/**
 * Unit Tests for Gemini Helper Utilities
 *
 * Tests JSON transformation, response parsing, and citation injection logic.
 */

import {
  stripMarkdownFences,
  validateAndNormalizeJson,
  validateReviewFields,
  extractUniqueSources,
  injectCitationsIntoBullets,
  extractTextFromGeminiResponse,
  toOpenAIFormat,
  GroundingChunk,
} from "../utils/gemini-helpers";

describe("stripMarkdownFences", () => {
  it("should remove ```json prefix and ``` suffix", () => {
    const input = "```json\n{\"key\": \"value\"}\n```";
    const expected = "{\"key\": \"value\"}";
    expect(stripMarkdownFences(input)).toBe(expected);
  });

  it("should remove plain ``` fences without json label", () => {
    const input = "```\n{\"key\": \"value\"}\n```";
    const expected = "{\"key\": \"value\"}";
    expect(stripMarkdownFences(input)).toBe(expected);
  });

  it("should handle text without markdown fences", () => {
    const input = "{\"key\": \"value\"}";
    expect(stripMarkdownFences(input)).toBe(input);
  });

  it("should trim whitespace", () => {
    const input = "  \n```json\n{\"key\": \"value\"}\n```\n  ";
    const expected = "{\"key\": \"value\"}";
    expect(stripMarkdownFences(input)).toBe(expected);
  });

  it("should handle empty string", () => {
    expect(stripMarkdownFences("")).toBe("");
  });

  it("should handle JSON with nested objects", () => {
    const input = "```json\n{\"outer\": {\"inner\": \"value\"}}\n```";
    const expected = "{\"outer\": {\"inner\": \"value\"}}";
    expect(stripMarkdownFences(input)).toBe(expected);
  });

  it("should handle multiline JSON", () => {
    const input = `\`\`\`json
{
  "key1": "value1",
  "key2": "value2"
}
\`\`\``;
    const result = stripMarkdownFences(input);
    expect(result).toContain("\"key1\"");
    expect(result).toContain("\"key2\"");
    expect(result).not.toContain("```");
  });
});

describe("validateAndNormalizeJson", () => {
  it("should parse and re-serialize valid JSON", () => {
    const input = "{\"key\": \"value\"}";
    const result = validateAndNormalizeJson(input);
    expect(JSON.parse(result)).toEqual({ key: "value" });
  });

  it("should normalize whitespace in JSON", () => {
    const input = "{\n  \"key\":   \"value\"\n}";
    const result = validateAndNormalizeJson(input);
    expect(result).toBe("{\"key\":\"value\"}");
  });

  it("should throw on invalid JSON", () => {
    const input = "{\"key\": value}"; // Missing quotes around value
    expect(() => validateAndNormalizeJson(input)).toThrow();
  });

  it("should throw on empty string", () => {
    expect(() => validateAndNormalizeJson("")).toThrow();
  });

  it("should handle arrays", () => {
    const input = "[\"a\", \"b\", \"c\"]";
    const result = validateAndNormalizeJson(input);
    expect(JSON.parse(result)).toEqual(["a", "b", "c"]);
  });

  it("should handle nested structures", () => {
    const input = "{\"arr\": [1, 2], \"obj\": {\"nested\": true}}";
    const result = validateAndNormalizeJson(input);
    expect(JSON.parse(result)).toEqual({
      arr: [1, 2],
      obj: { nested: true },
    });
  });
});

describe("validateReviewFields", () => {
  const validReview = {
    context_summary: "Great album",
    context_bullets: ["Point 1", "Point 2"],
    rating: 8.5,
    recommendation: "Must listen",
    key_tracks: ["Track 1", "Track 2"],
  };

  it("should return true for valid review", () => {
    expect(validateReviewFields(validReview)).toBe(true);
  });

  it("should throw when context_summary is missing", () => {
    const invalid = { ...validReview, context_summary: undefined };
    expect(() => validateReviewFields(invalid)).toThrow("Missing required fields");
  });

  it("should throw when context_bullets is missing", () => {
    const invalid = { ...validReview, context_bullets: undefined };
    expect(() => validateReviewFields(invalid)).toThrow("Missing required fields");
  });

  it("should throw when rating is missing", () => {
    const invalid = { ...validReview, rating: undefined };
    expect(() => validateReviewFields(invalid)).toThrow("Missing required fields");
  });

  it("should throw when recommendation is missing", () => {
    const invalid = { ...validReview, recommendation: undefined };
    expect(() => validateReviewFields(invalid)).toThrow("Missing required fields");
  });

  it("should throw when key_tracks is missing", () => {
    const invalid = { ...validReview, key_tracks: undefined };
    expect(() => validateReviewFields(invalid)).toThrow("Missing required fields");
  });

  it("should throw when context_bullets is not an array", () => {
    const invalid = { ...validReview, context_bullets: "not an array" };
    expect(() => validateReviewFields(invalid)).toThrow("context_bullets must be an array");
  });

  it("should throw when key_tracks is not an array", () => {
    const invalid = { ...validReview, key_tracks: "not an array" };
    expect(() => validateReviewFields(invalid)).toThrow("key_tracks must be an array");
  });

  it("should throw when rating is not a number", () => {
    const invalid = { ...validReview, rating: "8.5" };
    expect(() => validateReviewFields(invalid)).toThrow("rating must be a number");
  });

  it("should allow rating of 0", () => {
    const zeroRating = { ...validReview, rating: 0 };
    expect(validateReviewFields(zeroRating)).toBe(true);
  });

  it("should allow additional fields", () => {
    const withExtra = { ...validReview, extra_field: "allowed" };
    expect(validateReviewFields(withExtra)).toBe(true);
  });
});

describe("extractUniqueSources", () => {
  const createChunk = (title: string, uri: string): GroundingChunk => ({
    web: { title, uri },
  });

  it("should extract sources with web data", () => {
    const chunks = [
      createChunk("Source 1", "https://example.com/1"),
      createChunk("Source 2", "https://example.com/2"),
    ];
    const result = extractUniqueSources(chunks);
    expect(result).toHaveLength(2);
  });

  it("should deduplicate by title", () => {
    const chunks = [
      createChunk("Same Title", "https://example.com/1"),
      createChunk("Same Title", "https://example.com/2"),
      createChunk("Different", "https://example.com/3"),
    ];
    const result = extractUniqueSources(chunks);
    expect(result).toHaveLength(2);
    expect(result[0].web?.title).toBe("Same Title");
    expect(result[1].web?.title).toBe("Different");
  });

  it("should limit to maxSources (default 6)", () => {
    const chunks = Array.from({ length: 10 }, (_, i) =>
      createChunk(`Source ${i}`, `https://example.com/${i}`)
    );
    const result = extractUniqueSources(chunks);
    expect(result).toHaveLength(6);
  });

  it("should respect custom maxSources", () => {
    const chunks = Array.from({ length: 10 }, (_, i) =>
      createChunk(`Source ${i}`, `https://example.com/${i}`)
    );
    const result = extractUniqueSources(chunks, 3);
    expect(result).toHaveLength(3);
  });

  it("should filter out chunks without uri", () => {
    const chunks: GroundingChunk[] = [
      { web: { title: "No URI" } },
      createChunk("Has URI", "https://example.com"),
    ];
    const result = extractUniqueSources(chunks);
    expect(result).toHaveLength(1);
    expect(result[0].web?.title).toBe("Has URI");
  });

  it("should filter out chunks without title", () => {
    const chunks: GroundingChunk[] = [
      { web: { uri: "https://example.com" } },
      createChunk("Has Title", "https://example.com/2"),
    ];
    const result = extractUniqueSources(chunks);
    expect(result).toHaveLength(1);
    expect(result[0].web?.title).toBe("Has Title");
  });

  it("should handle empty array", () => {
    expect(extractUniqueSources([])).toEqual([]);
  });

  it("should handle chunks without web property", () => {
    const chunks: GroundingChunk[] = [
      {},
      createChunk("Valid", "https://example.com"),
    ];
    const result = extractUniqueSources(chunks);
    expect(result).toHaveLength(1);
  });
});

describe("injectCitationsIntoBullets", () => {
  const createSource = (title: string, uri: string): GroundingChunk => ({
    web: { title, uri },
  });

  it("should append citations to bullets", () => {
    const bullets = ["Point 1", "Point 2"];
    const sources = [
      createSource("Source A", "https://a.com"),
      createSource("Source B", "https://b.com"),
    ];
    const result = injectCitationsIntoBullets(bullets, sources);

    expect(result[0]).toBe("Point 1 ([Source A](https://a.com))");
    expect(result[1]).toBe("Point 2 ([Source B](https://b.com))");
  });

  it("should not modify bullets beyond available sources", () => {
    const bullets = ["Point 1", "Point 2", "Point 3"];
    const sources = [createSource("Source A", "https://a.com")];
    const result = injectCitationsIntoBullets(bullets, sources);

    expect(result[0]).toBe("Point 1 ([Source A](https://a.com))");
    expect(result[1]).toBe("Point 2");
    expect(result[2]).toBe("Point 3");
  });

  it("should return copy of bullets when no sources", () => {
    const bullets = ["Point 1", "Point 2"];
    const result = injectCitationsIntoBullets(bullets, []);

    expect(result).toEqual(bullets);
    expect(result).not.toBe(bullets); // Should be a new array
  });

  it("should handle empty bullets array", () => {
    const sources = [createSource("Source A", "https://a.com")];
    const result = injectCitationsIntoBullets([], sources);
    expect(result).toEqual([]);
  });

  it("should handle missing web properties gracefully", () => {
    const bullets = ["Point 1"];
    const sources: GroundingChunk[] = [{ web: {} }];
    const result = injectCitationsIntoBullets(bullets, sources);

    expect(result[0]).toBe("Point 1 ([source]())");
  });
});

describe("extractTextFromGeminiResponse", () => {
  it("should extract from direct text property", () => {
    const response = { text: "Direct text" };
    expect(extractTextFromGeminiResponse(response)).toBe("Direct text");
  });

  it("should extract from candidates structure", () => {
    const response = {
      candidates: [
        {
          content: {
            parts: [{ text: "Candidate text" }],
          },
        },
      ],
    };
    expect(extractTextFromGeminiResponse(response)).toBe("Candidate text");
  });

  it("should concatenate multiple text parts", () => {
    const response = {
      candidates: [
        {
          content: {
            parts: [{ text: "Part 1" }, { text: " Part 2" }],
          },
        },
      ],
    };
    expect(extractTextFromGeminiResponse(response)).toBe("Part 1 Part 2");
  });

  it("should prefer direct text over candidates", () => {
    const response = {
      text: "Direct",
      candidates: [
        {
          content: {
            parts: [{ text: "Candidate" }],
          },
        },
      ],
    };
    expect(extractTextFromGeminiResponse(response)).toBe("Direct");
  });

  it("should return empty string for missing data", () => {
    expect(extractTextFromGeminiResponse({})).toBe("");
    expect(extractTextFromGeminiResponse({ candidates: [] })).toBe("");
    expect(extractTextFromGeminiResponse({ candidates: [{}] })).toBe("");
  });

  it("should filter non-text parts in multi-part response", () => {
    const response = {
      candidates: [
        {
          content: {
            parts: [
              { text: "Text part" },
              { data: "binary data" }, // Not a text part
              { text: " more text" },
            ],
          },
        },
      ],
    };
    expect(extractTextFromGeminiResponse(response)).toBe("Text part more text");
  });
});

describe("toOpenAIFormat", () => {
  it("should create OpenAI-compatible structure", () => {
    const result = toOpenAIFormat("Test content");

    expect(result).toEqual({
      choices: [
        {
          index: 0,
          message: {
            role: "assistant",
            content: "Test content",
          },
          finish_reason: "stop",
        },
      ],
    });
  });

  it("should handle empty content", () => {
    const result = toOpenAIFormat("");
    expect(result.choices[0].message.content).toBe("");
  });

  it("should handle JSON string content", () => {
    const jsonContent = "{\"key\": \"value\"}";
    const result = toOpenAIFormat(jsonContent);
    expect(result.choices[0].message.content).toBe(jsonContent);
  });

  it("should handle content with special characters", () => {
    const content = "Content with \"quotes\" and\nnewlines";
    const result = toOpenAIFormat(content);
    expect(result.choices[0].message.content).toBe(content);
  });
});

describe("Integration: Full transformation pipeline", () => {
  it("should process a complete Gemini review response", () => {
    // Simulate raw Gemini response
    const rawResponse = `\`\`\`json
{
  "context_summary": "A landmark album that defined a generation",
  "context_bullets": [
    "Revolutionary production techniques",
    "Genre-defying sound"
  ],
  "rating": 9.5,
  "recommendation": "Essential listening",
  "key_tracks": ["Track 1", "Track 2"]
}
\`\`\``;

    const groundingChunks: GroundingChunk[] = [
      { web: { title: "Pitchfork", uri: "https://pitchfork.com/review" } },
      { web: { title: "Rolling Stone", uri: "https://rollingstone.com/review" } },
    ];

    // Step 1: Strip markdown
    const stripped = stripMarkdownFences(rawResponse);
    expect(stripped).not.toContain("```");

    // Step 2: Validate and normalize JSON
    const normalized = validateAndNormalizeJson(stripped);
    const parsed = JSON.parse(normalized);

    // Step 3: Validate review fields
    expect(validateReviewFields(parsed)).toBe(true);

    // Step 4: Extract unique sources
    const sources = extractUniqueSources(groundingChunks);
    expect(sources).toHaveLength(2);

    // Step 5: Inject citations
    const bulletsWithCitations = injectCitationsIntoBullets(
      parsed.context_bullets,
      sources
    );
    expect(bulletsWithCitations[0]).toContain("[Pitchfork]");
    expect(bulletsWithCitations[1]).toContain("[Rolling Stone]");

    // Step 6: Update parsed object and convert to OpenAI format
    parsed.context_bullets = bulletsWithCitations;
    const finalJson = JSON.stringify(parsed);
    const openAIFormat = toOpenAIFormat(finalJson);

    // Verify final structure
    expect(openAIFormat.choices).toHaveLength(1);
    expect(openAIFormat.choices[0].message.role).toBe("assistant");
    expect(openAIFormat.choices[0].finish_reason).toBe("stop");

    // Verify content is valid JSON with citations
    const finalContent = JSON.parse(openAIFormat.choices[0].message.content);
    expect(finalContent.context_bullets[0]).toContain("Pitchfork");
  });
});
