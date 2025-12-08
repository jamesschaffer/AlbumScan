/**
 * Gemini Response Helper Utilities
 *
 * Extracted helper functions for JSON transformation and response processing.
 * These are used by Gemini Cloud Functions and are testable in isolation.
 */

// Types for grounding metadata
export interface GroundingChunk {
  web?: { uri?: string; title?: string };
}

export interface ReviewResponse {
  context_summary: string;
  context_bullets: string[];
  rating: number;
  recommendation: string;
  key_tracks: string[];
  [key: string]: unknown; // Allow additional fields
}

/**
 * Strips markdown code fences from Gemini responses.
 * Gemini often wraps JSON in ```json ... ``` blocks.
 *
 * @param text - Raw response text from Gemini
 * @returns Cleaned text without markdown fences
 */
export function stripMarkdownFences(text: string): string {
  let cleanedText = text.trim();

  if (cleanedText.startsWith("```json")) {
    cleanedText = cleanedText.replace(/^```json\s*/, "").replace(/```\s*$/, "").trim();
  } else if (cleanedText.startsWith("```")) {
    cleanedText = cleanedText.replace(/^```\s*/, "").replace(/```\s*$/, "").trim();
  }

  return cleanedText;
}

/**
 * Validates and normalizes JSON response.
 * Parses, validates structure, and re-serializes for consistent output.
 *
 * @param text - JSON string to validate
 * @returns Normalized JSON string
 * @throws Error if JSON is invalid
 */
export function validateAndNormalizeJson(text: string): string {
  const parsed = JSON.parse(text);
  return JSON.stringify(parsed);
}

/**
 * Validates that a review response has all required fields.
 *
 * @param parsed - Parsed review object
 * @returns true if valid
 * @throws Error if missing required fields
 */
export function validateReviewFields(parsed: unknown): parsed is ReviewResponse {
  const obj = parsed as Record<string, unknown>;

  if (
    !obj.context_summary ||
    !obj.context_bullets ||
    obj.rating === undefined ||
    !obj.recommendation ||
    !obj.key_tracks
  ) {
    throw new Error("Missing required fields in review response");
  }

  if (!Array.isArray(obj.context_bullets)) {
    throw new Error("context_bullets must be an array");
  }

  if (!Array.isArray(obj.key_tracks)) {
    throw new Error("key_tracks must be an array");
  }

  if (typeof obj.rating !== "number") {
    throw new Error("rating must be a number");
  }

  return true;
}

/**
 * Extracts unique sources from Gemini grounding chunks.
 * Deduplicates by title and limits to maxSources.
 *
 * @param groundingChunks - Array of grounding chunks from Gemini
 * @param maxSources - Maximum number of sources to return (default: 6)
 * @returns Array of unique grounding chunks with web data
 */
export function extractUniqueSources(
  groundingChunks: GroundingChunk[],
  maxSources: number = 6
): GroundingChunk[] {
  const seenTitles = new Set<string>();

  return groundingChunks
    .filter((chunk) => {
      if (!chunk.web?.uri || !chunk.web?.title) return false;
      if (seenTitles.has(chunk.web.title)) return false;
      seenTitles.add(chunk.web.title);
      return true;
    })
    .slice(0, maxSources);
}

/**
 * Injects source citations into review bullet points.
 * Appends markdown links to bullet points based on grounding sources.
 *
 * @param bullets - Array of bullet point strings
 * @param sources - Array of unique grounding chunks
 * @returns New array of bullets with citations appended
 */
export function injectCitationsIntoBullets(
  bullets: string[],
  sources: GroundingChunk[]
): string[] {
  if (sources.length === 0) {
    return [...bullets];
  }

  return bullets.map((bullet, index) => {
    if (index < sources.length) {
      const source = sources[index];
      const title = source.web?.title || "source";
      const url = source.web?.uri || "";
      return `${bullet} ([${title}](${url}))`;
    }
    return bullet;
  });
}

/**
 * Extracts text content from Gemini response structure.
 * Handles both direct .text accessor and candidates array structure.
 *
 * @param response - Gemini API response object
 * @returns Extracted text content
 */
export function extractTextFromGeminiResponse(response: unknown): string {
  const responseAny = response as Record<string, unknown>;

  // Try direct text accessor first
  if (typeof responseAny.text === "string") {
    return responseAny.text;
  }

  // Fall back to candidates structure
  const candidates = responseAny.candidates as Array<{
    content?: { parts?: Array<{ text?: string }> };
  }>;

  // For multi-part responses (search grounding), concatenate all text parts
  if (candidates?.[0]?.content?.parts) {
    const parts = candidates[0].content.parts;
    return parts
      .filter((part) => typeof part.text === "string")
      .map((part) => part.text)
      .join("");
  }

  return "";
}

/**
 * Transforms a Gemini response into OpenAI-compatible format.
 * Used to maintain iOS client compatibility.
 *
 * @param content - Processed content string
 * @returns OpenAI-compatible response structure
 */
export function toOpenAIFormat(content: string): {
  choices: Array<{
    index: number;
    message: { role: string; content: string };
    finish_reason: string;
  }>;
} {
  return {
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content,
        },
        finish_reason: "stop",
      },
    ],
  };
}
