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

// Initialize Firebase Admin
admin.initializeApp();

// Define secrets (stored in Google Cloud Secret Manager)
const openAiKey = defineSecret("OPENAI_API_KEY");

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
