/**
 * AlbumScan Cloud Functions
 *
 * Secure API proxy for OpenAI services with:
 * - Server-side API key storage
 * - Firebase App Check device attestation
 * - Per-device rate limiting
 * - Usage monitoring
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

// Initialize Firebase Admin
admin.initializeApp();

// Define secrets (stored in Google Cloud Secret Manager)
const openAiKey = defineSecret("OPENAI_API_KEY");
const geminiKey = defineSecret("GEMINI_API_KEY");

// Rate limiting storage (in-memory for simplicity, use Firestore for production scale)
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();

// Constants
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 10; // 10 requests per minute per device
const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";

// OpenAI response types
interface OpenAIUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

interface OpenAIResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }>;
  usage?: OpenAIUsage;
}

/**
 * Check rate limit for a device
 */
function checkRateLimit(deviceId: string): boolean {
  const now = Date.now();
  const record = rateLimitMap.get(deviceId);

  if (!record || now > record.resetTime) {
    // New window
    rateLimitMap.set(deviceId, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW_MS,
    });
    return true;
  }

  if (record.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false;
  }

  record.count++;
  return true;
}

/**
 * Extract clean JSON from a response that may contain markdown code fences
 * Handles: ```json, ```, various whitespace patterns, and extracts JSON objects
 */
function extractCleanJson(text: string): string {
  if (!text || text.trim().length === 0) {
    throw new Error("Empty response received");
  }

  let cleaned = text.trim();

  // Remove markdown code fences (case insensitive, handles extra whitespace)
  // Matches: ```json, ```JSON, ``` json, ```javascript, etc.
  cleaned = cleaned.replace(/^```\s*\w*\s*\n?/i, "").replace(/\n?```\s*$/i, "").trim();

  // If still not starting with {, try to extract JSON object
  if (!cleaned.startsWith("{") && !cleaned.startsWith("[")) {
    const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      cleaned = jsonMatch[0];
    }
  }

  return cleaned;
}

/**
 * Validate album identification response has required fields
 */
function validateIdentificationResponse(parsed: Record<string, unknown>): void {
  const requiredFields = ["artistName", "albumTitle"];
  for (const field of requiredFields) {
    if (parsed[field] === undefined) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
}

/**
 * Get device identifier from App Check token or fallback
 */
function getDeviceId(request: CallableRequest): string {
  // Use App Check app ID if available
  if (request.app?.appId) {
    return request.app.appId;
  }
  // Fallback - should not happen with enforceAppCheck: true
  return "unknown-device";
}

// ============================================================================
// ID CALL 1: Single-Prompt Identification
// ============================================================================

interface IdentificationRequest {
  base64Image: string;
  prompt: string;
}

export const identifyAlbum = onCall(
  {
    secrets: [openAiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<IdentificationRequest>) => {
    const deviceId = getDeviceId(request);

    // Rate limit check
    if (!checkRateLimit(deviceId)) {
      console.warn(`Rate limit exceeded for device: ${deviceId}`);
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a moment and try again."
      );
    }

    const { base64Image, prompt } = request.data;

    // Validate input
    if (!base64Image || !prompt) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: base64Image and prompt"
      );
    }

    // Validate image size (prevent abuse with huge images)
    const imageSizeBytes = (base64Image.length * 3) / 4;
    const maxSizeMB = 5;
    if (imageSizeBytes > maxSizeMB * 1024 * 1024) {
      throw new HttpsError(
        "invalid-argument",
        `Image too large. Maximum size is ${maxSizeMB}MB.`
      );
    }

    try {
      const apiKey = openAiKey.value();

      console.log(`[identifyAlbum] Processing request from device: ${deviceId}`);

      const response = await fetch(OPENAI_API_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o",
          max_tokens: 1000,
          response_format: { type: "json_object" },
          messages: [
            {
              role: "user",
              content: [
                { type: "text", text: prompt },
                {
                  type: "image_url",
                  image_url: {
                    url: `data:image/jpeg;base64,${base64Image}`,
                  },
                },
              ],
            },
          ],
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[identifyAlbum] OpenAI API error: ${response.status} - ${errorText}`);
        throw new HttpsError(
          "internal",
          "Failed to process image. Please try again."
        );
      }

      const result = await response.json() as OpenAIResponse;

      // Log usage for monitoring
      if (result.usage) {
        console.log(
          `[identifyAlbum] Tokens used: ${result.usage.total_tokens} ` +
          `(prompt: ${result.usage.prompt_tokens}, completion: ${result.usage.completion_tokens})`
        );
      }

      return {
        success: true,
        data: result,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("[identifyAlbum] Unexpected error:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred. Please try again."
      );
    }
  }
);

// ============================================================================
// ID CALL 2: Search Finalization (with web search)
// ============================================================================

interface SearchFinalizationRequest {
  prompt: string;
}

export const searchFinalizeAlbum = onCall(
  {
    secrets: [openAiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<SearchFinalizationRequest>) => {
    const deviceId = getDeviceId(request);

    // Rate limit check
    if (!checkRateLimit(deviceId)) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a moment and try again."
      );
    }

    const { prompt } = request.data;

    if (!prompt) {
      throw new HttpsError("invalid-argument", "Missing required field: prompt");
    }

    try {
      const apiKey = openAiKey.value();

      console.log(`[searchFinalizeAlbum] Processing request from device: ${deviceId}`);

      const response = await fetch(OPENAI_API_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-search-preview",
          max_tokens: 1000,
          messages: [
            {
              role: "user",
              content: prompt,
            },
          ],
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[searchFinalizeAlbum] OpenAI API error: ${response.status} - ${errorText}`);
        throw new HttpsError(
          "internal",
          "Failed to search. Please try again."
        );
      }

      const result = await response.json() as OpenAIResponse;

      if (result.usage) {
        console.log(
          `[searchFinalizeAlbum] Tokens used: ${result.usage.total_tokens}`
        );
      }

      return {
        success: true,
        data: result,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("[searchFinalizeAlbum] Unexpected error:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred. Please try again."
      );
    }
  }
);

// ============================================================================
// Review Generation
// ============================================================================

interface ReviewRequest {
  artistName: string;
  albumTitle: string;
  releaseYear: string;
  genres: string;
  recordLabel: string;
}

// Albums released in or after this year use Google Search grounding
const SEARCH_CUTOFF_YEAR = 2024;

function shouldUseSearch(releaseYear: string): boolean {
  if (releaseYear === "Unknown") return true;
  const year = parseInt(releaseYear, 10);
  return isNaN(year) || year >= SEARCH_CUTOFF_YEAR;
}

function validateReviewRequest(data: ReviewRequest): void {
  const { artistName, albumTitle, releaseYear, genres, recordLabel } = data;

  if (!artistName || typeof artistName !== "string" ||
      !albumTitle || typeof albumTitle !== "string" ||
      !releaseYear || typeof releaseYear !== "string" ||
      !genres || typeof genres !== "string" ||
      !recordLabel || typeof recordLabel !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: artistName, albumTitle, releaseYear, genres, recordLabel"
    );
  }

  if (artistName.length > 200 || albumTitle.length > 200 || recordLabel.length > 200) {
    throw new HttpsError(
      "invalid-argument",
      "artistName, albumTitle, and recordLabel must be 200 characters or fewer"
    );
  }

  if (genres.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "genres must be 500 characters or fewer"
    );
  }

  if (releaseYear !== "Unknown" && !/^\d{4}$/.test(releaseYear)) {
    throw new HttpsError(
      "invalid-argument",
      "releaseYear must be a 4-digit year or \"Unknown\""
    );
  }
}

// System instruction: persona, source rules, output format, tier system
const REVIEW_SYSTEM_INSTRUCTION = `You are a music critic writing an honest, evidence-based album review for collectors who care about artistic merit, not financial value.

**Your Task:**
Generate a concise, honest assessment of this album's cultural significance and musical merit based on your knowledge of music history, critical reception, influence, and cultural impact.

**Source Prioritization:**
When searching for evidence and critical reception, prioritize these sources (in order):
- Metacritic
- Album of the Year
- Pitchfork
- Rolling Stone
- AllMusic
- The Guardian

**Source Diversity Rules:**
To ensure comprehensive and credible reviews, follow these citation rules:
- Use NO MORE than 2 URLs from any single domain (e.g., max 2 Wikipedia links)
- Aim to cite at least 3 different sources from the priority list
- Prefer Metacritic/Pitchfork for review scores and critical consensus
- Use Wikipedia for general context, background, and album basics
- Use music publications (Rolling Stone, AllMusic) for in-depth analysis and cultural impact
- Diversify your sources to provide multiple perspectives

**Required Output Structure:**

1. **context_summary** (2-3 sentences): Opening paragraph that captures the album's core essence and importance. Be specific about what makes it matter (or not).

2. **context_bullets** (3-5 bullet points): Concrete evidence supporting your assessment:
   - Critical reception (scores from Pitchfork, Rolling Stone, Metacritic when available)
   - Concrete impact examples (chart performance, sales figures, awards)
   - Specific standout tracks and sonic qualities
   - Genre innovation or influence on other artists
   - Reputation evolution (initially panned vs. later acclaimed, etc.)

3. **rating** (number 0-10): Your assessment based on the album's artistic merit and cultural significance.

4. **recommendation** (string): Choose ONE label that best captures this album's place in music:

   TIER 1 (Undeniable Greatness): Essential Classic | Genre Landmark | Cultural Monument
   TIER 2 (Critical Darlings): Indie Masterpiece | Cult Essential | Critics' Choice
   TIER 3 (Crowd Pleasers): Crowd Favorite | Radio Gold | Crossover Success
   TIER 4 (Hidden Gems): Deep Cut | Surprise Excellence | Scene Favorite
   TIER 5 (Historical Interest): Time Capsule | Influential Curio | Pioneering Effort
   TIER 6 (Solid Work): Reliable Listen | Fan Essential | Genre Staple
   TIER 7 (Problematic): Ambitious Failure | Divisive Work | Uneven Effort
   TIER 8 (Pass): Forgettable Entry | Career Low | Avoid Entirely

**Critical Requirements:**
- Use honest, direct language - call out mediocre or bad albums explicitly
- Focus on what actually matters about the album (no filler or generic praise)
- Evaluate albums purely on musical merit - artist's personal controversies or social issues may be mentioned for context but do NOT devalue their musical contributions or impact
- Provide specific evidence (scores, chart positions, awards, influence examples)
- Choose the recommendation carefully based on the album's actual place in music history, not just your personal opinion
- Reserve Tier 1 labels for genuinely canonical/influential albums only
- NEVER mention price, monetary value, market considerations, investment potential, pressing details, or collectibility
- Be the honest music historian, not the investment advisor

Return ONLY valid JSON in this exact format:
{
  "context_summary": "string",
  "context_bullets": ["string", "string", "string"],
  "rating": number,
  "recommendation": "string (exactly as written above)",
  "key_tracks": ["string", "string", "string"]
}`;

function buildUserMessage(req: ReviewRequest): string {
  return `**Album Metadata:**
Artist: ${req.artistName}
Album: ${req.albumTitle}
Year: ${req.releaseYear}
Genre: ${req.genres}
Label: ${req.recordLabel}

Generate a concise, honest assessment of this album's cultural significance and musical merit.`;
}

// ============================================================================
// Health Check (for monitoring)
// ============================================================================

export const healthCheck = onCall(
  {
    enforceAppCheck: false, // Allow unauthenticated health checks
    cors: true,
  },
  async () => {
    return {
      status: "healthy",
      timestamp: new Date().toISOString(),
      version: "1.0.0",
    };
  }
);

// ============================================================================
// GEMINI: ID CALL 1 - Single-Prompt Identification
// ============================================================================

export const identifyAlbumGemini = onCall(
  {
    secrets: [geminiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<IdentificationRequest>) => {
    const deviceId = getDeviceId(request);

    // Rate limit check
    if (!checkRateLimit(deviceId)) {
      console.warn(`Rate limit exceeded for device: ${deviceId}`);
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a moment and try again."
      );
    }

    const { base64Image, prompt } = request.data;

    // Validate input
    if (!base64Image || !prompt) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: base64Image and prompt"
      );
    }

    // Validate image size (prevent abuse with huge images)
    const imageSizeBytes = (base64Image.length * 3) / 4;
    const maxSizeMB = 5;
    if (imageSizeBytes > maxSizeMB * 1024 * 1024) {
      throw new HttpsError(
        "invalid-argument",
        `Image too large. Maximum size is ${maxSizeMB}MB.`
      );
    }

    try {
      console.log(`[identifyAlbumGemini] Processing request from device: ${deviceId}`);

      const ai = new GoogleGenAI({ apiKey: geminiKey.value() });

      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType: "image/jpeg",
                  data: base64Image,
                },
              },
            ],
          },
        ],
        config: {
          // Note: Cannot use responseMimeType with tools, so we parse JSON manually
          maxOutputTokens: 2000,
          tools: [{ googleSearch: {} }], // Enable search for visual recognition of text-sparse albums
        },
      });

      // Extract text from response - the SDK structure requires navigating candidates
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const responseAny = response as any;
      let text = "";

      // Try the .text accessor first (may throw on blocked content)
      try {
        if (typeof response.text === "string") {
          text = response.text;
        }
      } catch {
        // .text accessor threw, fall back to candidates
      }

      // Fall back to extracting from candidates structure
      if (!text && responseAny.candidates?.[0]?.content?.parts?.[0]?.text) {
        text = responseAny.candidates[0].content.parts[0].text;
      }

      const finishReason = responseAny.candidates?.[0]?.finishReason || "unknown";
      console.log(`[identifyAlbumGemini] Finish reason: ${finishReason}`);
      console.log(`[identifyAlbumGemini] Response received, length: ${text.length}`);

      // Check for empty response (safety filters, API issues)
      if (!text || text.trim().length === 0) {
        console.error(`[identifyAlbumGemini] Empty response. Finish reason: ${finishReason}`);
        throw new HttpsError(
          "internal",
          finishReason === "SAFETY"
            ? "Image could not be processed due to content restrictions."
            : "No response received. Please try again with a clearer image."
        );
      }

      // Clean up Gemini response and validate JSON
      let cleanedText: string;
      try {
        cleanedText = extractCleanJson(text);
        const parsed = JSON.parse(cleanedText);
        validateIdentificationResponse(parsed);
        // Re-serialize to ensure clean JSON
        cleanedText = JSON.stringify(parsed);
        console.log("[identifyAlbumGemini] JSON validated successfully");
      } catch (jsonError) {
        console.error(`[identifyAlbumGemini] JSON validation failed: ${jsonError}`);
        console.error(`[identifyAlbumGemini] Raw text (first 500 chars): ${text.substring(0, 500)}`);
        throw new HttpsError(
          "internal",
          "Failed to parse album identification. Please try again."
        );
      }

      // Return in same format as OpenAI for compatibility
      return {
        success: true,
        data: {
          choices: [{
            index: 0,
            message: {
              role: "assistant",
              content: cleanedText,
            },
            finish_reason: "stop",
          }],
        },
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("[identifyAlbumGemini] Unexpected error:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred. Please try again."
      );
    }
  }
);

// ============================================================================
// GEMINI: ID CALL 2 - Search Finalization (with Google Search grounding)
// ============================================================================

export const searchFinalizeAlbumGemini = onCall(
  {
    secrets: [geminiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<SearchFinalizationRequest>) => {
    const deviceId = getDeviceId(request);

    // Rate limit check
    if (!checkRateLimit(deviceId)) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a moment and try again."
      );
    }

    const { prompt } = request.data;

    if (!prompt) {
      throw new HttpsError("invalid-argument", "Missing required field: prompt");
    }

    try {
      console.log(`[searchFinalizeAlbumGemini] Processing request from device: ${deviceId}`);

      const ai = new GoogleGenAI({ apiKey: geminiKey.value() });

      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: prompt,
        config: {
          tools: [{ googleSearch: {} }], // Enable Google Search grounding
          maxOutputTokens: 2000,
        },
      });

      // Extract text from response
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const responseAny = response as any;
      let text = "";

      // Try the .text accessor first (may throw on blocked content)
      try {
        if (typeof response.text === "string") {
          text = response.text;
        }
      } catch {
        // .text accessor threw, fall back to candidates
      }

      // Fall back to extracting from candidates structure
      if (!text && responseAny.candidates?.[0]?.content?.parts?.[0]?.text) {
        text = responseAny.candidates[0].content.parts[0].text;
      }

      // Log grounding metadata if available
      const groundingMetadata = responseAny.candidates?.[0]?.groundingMetadata;
      if (groundingMetadata?.webSearchQueries) {
        console.log(
          `[searchFinalizeAlbumGemini] Search queries: ${JSON.stringify(groundingMetadata.webSearchQueries)}`
        );
      } else {
        console.warn("[searchFinalizeAlbumGemini] No grounding sources returned from Google Search");
      }

      const finishReason = responseAny.candidates?.[0]?.finishReason || "unknown";
      console.log(`[searchFinalizeAlbumGemini] Finish reason: ${finishReason}`);
      console.log(`[searchFinalizeAlbumGemini] Response received, length: ${text.length}`);

      // Check for empty response
      if (!text || text.trim().length === 0) {
        console.error(`[searchFinalizeAlbumGemini] Empty response. Finish reason: ${finishReason}`);
        throw new HttpsError(
          "internal",
          "Search returned no results. Please try again."
        );
      }

      // Clean up Gemini response and validate JSON
      let cleanedText: string;
      try {
        cleanedText = extractCleanJson(text);
        const parsed = JSON.parse(cleanedText);
        validateIdentificationResponse(parsed);
        // Re-serialize to ensure clean JSON
        cleanedText = JSON.stringify(parsed);
        console.log("[searchFinalizeAlbumGemini] JSON validated successfully");
      } catch (jsonError) {
        console.error(`[searchFinalizeAlbumGemini] JSON validation failed: ${jsonError}`);
        console.error(`[searchFinalizeAlbumGemini] Raw text (first 500 chars): ${text.substring(0, 500)}`);
        throw new HttpsError(
          "internal",
          "Failed to finalize album identification. Please try again."
        );
      }

      // Return in same format as OpenAI for compatibility
      return {
        success: true,
        data: {
          choices: [{
            index: 0,
            message: {
              role: "assistant",
              content: cleanedText,
            },
            finish_reason: "stop",
          }],
        },
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("[searchFinalizeAlbumGemini] Unexpected error:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred. Please try again."
      );
    }
  }
);

// ============================================================================
// GEMINI: Review Generation
// ============================================================================

export const generateReviewGemini = onCall(
  {
    secrets: [geminiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<ReviewRequest>) => {
    const deviceId = getDeviceId(request);

    // Rate limit check
    if (!checkRateLimit(deviceId)) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a moment and try again."
      );
    }

    validateReviewRequest(request.data);

    const useSearch = shouldUseSearch(request.data.releaseYear);
    const userMessage = buildUserMessage(request.data);

    try {
      console.log(
        `[generateReviewGemini] Processing request from device: ${deviceId}, ` +
        `album: "${request.data.albumTitle}" by ${request.data.artistName}, useSearch: ${useSearch}`
      );

      const ai = new GoogleGenAI({ apiKey: geminiKey.value() });

      // Helper to call Gemini with or without search grounding
      const callGemini = async (withSearch: boolean) => {
        return ai.models.generateContent({
          model: "gemini-3-flash-preview",
          contents: [{ role: "user", parts: [{ text: userMessage }] }],
          config: {
            systemInstruction: REVIEW_SYSTEM_INSTRUCTION,
            maxOutputTokens: 4000,
            ...(withSearch ? { tools: [{ googleSearch: {} }] } : {}),
          },
        });
      };

      let response;
      let actualSearch = useSearch;

      if (useSearch) {
        try {
          response = await callGemini(true);
        } catch (searchError) {
          console.warn(
            `[generateReviewGemini] Search attempt failed — retrying without search grounding. Error: ${searchError}`
          );
          response = await callGemini(false);
          actualSearch = false;
        }
      } else {
        response = await callGemini(false);
      }

      // Extract text from response
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const responseAny = response as any;
      const candidate = responseAny.candidates?.[0];
      let text = "";

      // Try the .text accessor first (may throw on blocked content)
      try {
        if (typeof response.text === "string") {
          text = response.text;
        }
      } catch {
        // .text accessor threw, fall back to candidates
      }

      // Fall back to extracting from candidates structure
      if (!text && candidate?.content?.parts) {
        // Concatenate all text parts (search grounding may return multiple parts)
        text = candidate.content.parts
          .filter((part: Record<string, unknown>) => typeof part.text === "string")
          .map((part: Record<string, unknown>) => part.text)
          .join("");
      }

      const finishReason = candidate?.finishReason || "unknown";
      console.log(
        `[generateReviewGemini] Response: ${text.length} chars, finish: ${finishReason}`
      );

      // Check for empty response
      if (!text || text.trim().length === 0) {
        console.error(`[generateReviewGemini] Empty response. Finish reason: ${finishReason}`);
        throw new HttpsError(
          "internal",
          finishReason === "SAFETY"
            ? "Review could not be generated due to content restrictions."
            : "Failed to generate review. Please try again."
        );
      }

      // Clean up Gemini response using robust extraction
      let cleanedText = extractCleanJson(text);

      // Extract grounding sources from metadata
      // Gemini 3 uses searchEntryPoint.renderedContent (HTML) instead of groundingChunks
      const groundingMetadata = candidate?.groundingMetadata || responseAny.groundingMetadata;

      interface ExtractedSource {
        title: string;
        url: string;
      }

      // Extract sources from the HTML renderedContent
      const extractedSources: ExtractedSource[] = [];
      if (groundingMetadata?.searchEntryPoint?.renderedContent) {
        const html = groundingMetadata.searchEntryPoint.renderedContent as string;
        // Extract links from HTML: <a href="url">title</a>
        const linkRegex = /<a[^>]+href="([^"]+)"[^>]*>([^<]+)<\/a>/gi;
        let match;
        const seenDomains = new Set<string>();
        while ((match = linkRegex.exec(html)) !== null && extractedSources.length < 6) {
          const url = match[1];
          if (url) {
            // Extract domain name as the outlet (e.g., "pitchfork.com" -> "Pitchfork")
            try {
              const domain = new URL(url).hostname.replace("www.", "");
              const outlet = domain.split(".")[0]; // Get first part before .com
              const outletName = outlet.charAt(0).toUpperCase() + outlet.slice(1); // Capitalize
              if (!seenDomains.has(domain)) {
                seenDomains.add(domain);
                extractedSources.push({ title: outletName, url });
              }
            } catch {
              // Skip invalid URLs
            }
          }
        }
      }

      if (actualSearch) {
        console.log(`[generateReviewGemini] Grounding sources extracted: ${extractedSources.length}`);
        if (extractedSources.length === 0) {
          console.warn("[generateReviewGemini] Search enabled but no grounding sources found in response");
        }
      }

      // Validate JSON and fix common Gemini issues
      try {
        const parsed = JSON.parse(cleanedText);

        // Validate required fields exist
        if (!parsed.context_summary || !parsed.context_bullets ||
            parsed.rating === undefined || !parsed.recommendation || !parsed.key_tracks) {
          console.error("[generateReviewGemini] Missing required fields in response");
          throw new Error("Missing required fields");
        }

        // Post-process: Add source citations to bullet points using extracted sources
        if (extractedSources.length > 0 && actualSearch && Array.isArray(parsed.context_bullets)) {
          const bulletsCount = parsed.context_bullets.length;
          for (let i = 0; i < bulletsCount && i < extractedSources.length; i++) {
            const source = extractedSources[i];
            // Append citation to bullet
            parsed.context_bullets[i] = `${parsed.context_bullets[i]} ([${source.title}](${source.url}))`;
          }
          console.log(`[generateReviewGemini] Added citations to ${Math.min(bulletsCount, extractedSources.length)} bullet points`);
        }

        // Re-serialize to ensure clean JSON
        cleanedText = JSON.stringify(parsed);
        console.log("[generateReviewGemini] JSON validated successfully");
      } catch (jsonError) {
        console.error(`[generateReviewGemini] JSON validation failed: ${jsonError}`);
        console.error(`[generateReviewGemini] Raw text (first 500 chars): ${cleanedText.substring(0, 500)}`);
        throw new HttpsError(
          "internal",
          "Failed to generate valid review. Please try again."
        );
      }

      // Return in same format as OpenAI for compatibility
      return {
        success: true,
        data: {
          choices: [{
            index: 0,
            message: {
              role: "assistant",
              content: cleanedText,
            },
            finish_reason: "stop",
          }],
        },
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("[generateReviewGemini] Unexpected error:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred. Please try again."
      );
    }
  }
);
