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
  prompt: string;
  useSearch: boolean; // true for Ultra subscribers
}

export const generateReview = onCall(
  {
    secrets: [openAiKey],
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

    const { prompt, useSearch = false } = request.data;

    if (!prompt) {
      throw new HttpsError("invalid-argument", "Missing required field: prompt");
    }

    try {
      const apiKey = openAiKey.value();

      // Use search-enabled model for Ultra subscribers
      const model = useSearch ? "gpt-4o-search-preview" : "gpt-4o";

      console.log(
        `[generateReview] Processing request from device: ${deviceId}, model: ${model}`
      );

      const response = await fetch(OPENAI_API_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          max_tokens: 1500,
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
        console.error(`[generateReview] OpenAI API error: ${response.status} - ${errorText}`);
        throw new HttpsError(
          "internal",
          "Failed to generate review. Please try again."
        );
      }

      const result = await response.json() as OpenAIResponse;

      if (result.usage) {
        console.log(
          `[generateReview] Tokens used: ${result.usage.total_tokens}`
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
      console.error("[generateReview] Unexpected error:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred. Please try again."
      );
    }
  }
);

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
        model: "gemini-2.5-flash",
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
          responseMimeType: "application/json",
          maxOutputTokens: 2000,
        },
      });

      // Extract text from response - the SDK structure requires navigating candidates
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const responseAny = response as any;
      let text = "";

      // Try the .text accessor first (may work in some SDK versions)
      if (typeof response.text === "string") {
        text = response.text;
      } else if (responseAny.candidates?.[0]?.content?.parts?.[0]?.text) {
        // Fall back to extracting from candidates structure
        text = responseAny.candidates[0].content.parts[0].text;
      }

      console.log(`[identifyAlbumGemini] Finish reason: ${responseAny.candidates?.[0]?.finishReason}`);
      console.log(`[identifyAlbumGemini] Response received, length: ${text.length}`);

      // Clean up Gemini response - strip markdown code fences
      let cleanedText = text.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.replace(/^```json\s*/, "").replace(/```\s*$/, "").trim();
      } else if (cleanedText.startsWith("```")) {
        cleanedText = cleanedText.replace(/^```\s*/, "").replace(/```\s*$/, "").trim();
      }

      // Validate JSON before returning
      try {
        const parsed = JSON.parse(cleanedText);
        // Re-serialize to ensure clean JSON
        cleanedText = JSON.stringify(parsed);
        console.log("[identifyAlbumGemini] JSON validated successfully");
      } catch (jsonError) {
        console.error(`[identifyAlbumGemini] JSON validation failed: ${jsonError}`);
        console.error(`[identifyAlbumGemini] Raw text (first 500 chars): ${cleanedText.substring(0, 500)}`);
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
        model: "gemini-2.5-flash",
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

      if (typeof response.text === "string") {
        text = response.text;
      } else if (responseAny.candidates?.[0]?.content?.parts?.[0]?.text) {
        text = responseAny.candidates[0].content.parts[0].text;
      }

      // Log grounding metadata if available
      const groundingMetadata = responseAny.candidates?.[0]?.groundingMetadata;
      if (groundingMetadata?.webSearchQueries) {
        console.log(
          `[searchFinalizeAlbumGemini] Search queries: ${JSON.stringify(groundingMetadata.webSearchQueries)}`
        );
      }

      console.log(`[searchFinalizeAlbumGemini] Finish reason: ${responseAny.candidates?.[0]?.finishReason}`);
      console.log(`[searchFinalizeAlbumGemini] Response received, length: ${text.length}`);

      // Clean up Gemini response - strip markdown code fences
      let cleanedText = text.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.replace(/^```json\s*/, "").replace(/```\s*$/, "").trim();
      } else if (cleanedText.startsWith("```")) {
        cleanedText = cleanedText.replace(/^```\s*/, "").replace(/```\s*$/, "").trim();
      }

      // Validate JSON before returning
      try {
        const parsed = JSON.parse(cleanedText);
        // Re-serialize to ensure clean JSON
        cleanedText = JSON.stringify(parsed);
        console.log("[searchFinalizeAlbumGemini] JSON validated successfully");
      } catch (jsonError) {
        console.error(`[searchFinalizeAlbumGemini] JSON validation failed: ${jsonError}`);
        console.error(`[searchFinalizeAlbumGemini] Raw text (first 500 chars): ${cleanedText.substring(0, 500)}`);
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

    const { prompt, useSearch = false } = request.data;

    if (!prompt) {
      throw new HttpsError("invalid-argument", "Missing required field: prompt");
    }

    try {
      console.log(
        `[generateReviewGemini] Processing request from device: ${deviceId}, useSearch: ${useSearch}`
      );

      const ai = new GoogleGenAI({ apiKey: geminiKey.value() });

      // Configure with or without search based on Ultra tier
      interface GenerateConfig {
        maxOutputTokens: number;
        tools?: Array<{ googleSearch: Record<string, never> }>;
      }

      const config: GenerateConfig = {
        maxOutputTokens: 4000, // Reviews need more tokens, especially with search
      };

      if (useSearch) {
        config.tools = [{ googleSearch: {} }];
      }

      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash",
        contents: prompt,
        config,
      });

      // Extract text from response
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const responseAny = response as any;
      let text = "";

      // Debug: log structure when we have issues
      const candidate = responseAny.candidates?.[0];
      console.log(`[generateReviewGemini] Candidate keys: ${candidate ? Object.keys(candidate) : "no candidate"}`);
      console.log(`[generateReviewGemini] Content keys: ${candidate?.content ? Object.keys(candidate.content) : "no content"}`);
      console.log(`[generateReviewGemini] Parts count: ${candidate?.content?.parts?.length || 0}`);

      // Log all parts to understand the structure
      if (candidate?.content?.parts) {
        candidate.content.parts.forEach((part: Record<string, unknown>, idx: number) => {
          console.log(`[generateReviewGemini] Part ${idx} keys: ${Object.keys(part)}`);
          if (part.text) {
            console.log(`[generateReviewGemini] Part ${idx} text length: ${(part.text as string).length}`);
            console.log(`[generateReviewGemini] Part ${idx} text preview: ${(part.text as string).substring(0, 200)}`);
          }
        });
      }

      if (typeof response.text === "string") {
        text = response.text;
      } else if (responseAny.candidates?.[0]?.content?.parts) {
        // Concatenate all text parts (search grounding may return multiple parts)
        const parts = responseAny.candidates[0].content.parts;
        text = parts
          .filter((part: Record<string, unknown>) => typeof part.text === "string")
          .map((part: Record<string, unknown>) => part.text)
          .join("");
      }

      console.log(`[generateReviewGemini] Finish reason: ${responseAny.candidates?.[0]?.finishReason}`);
      console.log(`[generateReviewGemini] Response received, length: ${text.length}`);

      // Clean up Gemini response - strip markdown code fences
      let cleanedText = text.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.replace(/^```json\s*/, "").replace(/```\s*$/, "").trim();
      } else if (cleanedText.startsWith("```")) {
        cleanedText = cleanedText.replace(/^```\s*/, "").replace(/```\s*$/, "").trim();
      }

      // Extract grounding sources from metadata
      const groundingMetadata = candidate?.groundingMetadata;
      interface GroundingChunk {
        web?: { uri?: string; title?: string };
      }
      const groundingChunks: GroundingChunk[] = groundingMetadata?.groundingChunks || [];

      console.log(`[generateReviewGemini] Grounding chunks count: ${groundingChunks.length}`);
      if (groundingChunks.length > 0) {
        console.log(`[generateReviewGemini] Grounding sources: ${JSON.stringify(groundingChunks.slice(0, 5))}`);
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

        // Post-process: Add source citations to bullet points using grounding metadata
        if (groundingChunks.length > 0 && useSearch && Array.isArray(parsed.context_bullets)) {
          // Get unique sources (dedupe by title)
          const seenTitles = new Set<string>();
          const uniqueSources = groundingChunks
            .filter((chunk: GroundingChunk) => {
              if (!chunk.web?.uri || !chunk.web?.title) return false;
              if (seenTitles.has(chunk.web.title)) return false;
              seenTitles.add(chunk.web.title);
              return true;
            })
            .slice(0, 6); // Limit to 6 unique sources

          // Distribute sources across bullet points
          if (uniqueSources.length > 0) {
            const bulletsCount = parsed.context_bullets.length;
            for (let i = 0; i < bulletsCount && i < uniqueSources.length; i++) {
              const source = uniqueSources[i];
              const domain = source.web?.title || "source";
              const url = source.web?.uri || "";
              // Append citation to bullet
              parsed.context_bullets[i] = `${parsed.context_bullets[i]} ([${domain}](${url}))`;
            }
            console.log(`[generateReviewGemini] Added citations to ${Math.min(bulletsCount, uniqueSources.length)} bullet points`);
          }
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
