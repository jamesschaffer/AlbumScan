# Gemini API Analysis for AlbumScan

**Date:** December 7, 2025
**Purpose:** Evaluate Google Gemini API as an alternative to OpenAI for AlbumScan's two-tier identification and review generation system.

---

## Executive Summary

**Yes, Gemini can do everything you're currently doing with OpenAI, and at a significantly lower cost.** The analysis below provides detailed evidence for both capability parity and cost savings.

---

## 1. Capability Analysis

### Can Gemini Analyze Album Cover Images? ✅ YES

Based on official documentation from [Google AI for Developers](https://ai.google.dev/gemini-api/docs/vision):

| Requirement | Gemini Capability | Evidence |
|-------------|-------------------|----------|
| **Vision/Image Analysis** | ✅ Native multimodal | All Gemini models are "built to be multimodal from the ground up" |
| **Text Extraction (OCR)** | ✅ Full support | "Text recognition from handwriting" and printed text supported |
| **Object Recognition** | ✅ 10,000+ categories | "Identifies and locates objects within images with pixel-level accuracy" |
| **Visual Q&A** | ✅ Full support | "Ask specific questions about image content and receive detailed, contextually appropriate responses" |
| **JSON Response Format** | ✅ Supported | `response_mime_type="application/json"` enforces structured output |
| **Base64 Image Input** | ✅ Supported | Same method you use with OpenAI |
| **Image Token Counting** | ✅ Predictable | 258 tokens for ≤384px images; 768x768 tiles at 258 tokens each |

**Your ID Call 1 prompt** (`single_prompt_identification.txt`) requires:
- Reading text from album covers → ✅ Gemini OCR
- Describing visual elements (colors, artwork style) → ✅ Gemini visual understanding
- Recognizing iconic album covers from internal knowledge → ✅ Gemini's training includes music/culture
- Returning structured JSON → ✅ Native JSON mode support

### Can Gemini Write Album Reviews? ✅ YES

Gemini models are general-purpose LLMs with equivalent text generation capabilities to GPT-4o. Your review prompts (`album_review.txt` and `album_review_ultra.txt`) require:

| Requirement | Gemini Capability |
|-------------|-------------------|
| Cultural analysis | ✅ Training includes music history, reviews |
| Structured JSON output | ✅ Native JSON response format |
| Ratings and recommendations | ✅ Standard LLM capability |
| Source citations (Ultra) | ✅ Grounding with Google Search |

### Search Grounding Comparison

| Feature | OpenAI (gpt-4o-search-preview) | Gemini (Grounding with Google Search) |
|---------|-------------------------------|---------------------------------------|
| **Search Capability** | Automatic with model | Tool-based, model decides when to search |
| **Search Sources** | Web search | Google Search index |
| **Citation Format** | Inline with response | `groundingMetadata` with URIs and titles |
| **Control** | Model decides | Model decides (can be prompted) |
| **Billing Model** | Per-token + search overhead | Per-prompt (legacy) or per-query (Gemini 3) |

---

## 2. Cost Analysis

### Current OpenAI Costs (Your Implementation)

Based on your code in `OpenAIAPIService.swift` and `functions/src/index.ts`:

| Call Type | Model | Input Cost | Output Cost | Search Cost | Typical Total |
|-----------|-------|------------|-------------|-------------|---------------|
| **ID Call 1** | gpt-4o | $2.50/1M | $10.00/1M | N/A | ~$0.01/call |
| **ID Call 2** | gpt-4o-search-preview | $2.50/1M | $10.00/1M | ~$0.03/search | ~$0.03-0.04/call |
| **Review (Free)** | gpt-4o | $2.50/1M | $10.00/1M | N/A | ~$0.05-0.10/call |
| **Review (Ultra)** | gpt-4o-search-preview | $2.50/1M | $10.00/1M | ~$0.03/search | ~$0.08-0.13/call |

**Your documented cost**: ~$0.10/day for 100 scans with caching

### Gemini Pricing Options

Based on [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing):

#### Option A: Gemini 2.0 Flash (Best Value)

| Call Type | Model | Input Cost | Output Cost | Search Cost | Typical Total |
|-----------|-------|------------|-------------|-------------|---------------|
| **ID Call 1** | gemini-2.0-flash | $0.10/1M | $0.40/1M | N/A | ~$0.0003/call |
| **ID Call 2** | gemini-2.0-flash + Search | $0.10/1M | $0.40/1M | $0.035/prompt* | ~$0.035/call |
| **Review (Free)** | gemini-2.0-flash | $0.10/1M | $0.40/1M | N/A | ~$0.0005/call |
| **Review (Ultra)** | gemini-2.0-flash + Search | $0.10/1M | $0.40/1M | $0.035/prompt* | ~$0.036/call |

*Search pricing: $35/1,000 grounded prompts after free tier (1,500/day free for 2.5 Flash)

#### Option B: Gemini 2.5 Flash (Better Quality)

| Call Type | Model | Input Cost | Output Cost | Search Cost | Typical Total |
|-----------|-------|------------|-------------|-------------|---------------|
| **ID Call 1** | gemini-2.5-flash | $0.30/1M | $2.50/1M | N/A | ~$0.001/call |
| **ID Call 2** | gemini-2.5-flash + Search | $0.30/1M | $2.50/1M | $0.035/prompt* | ~$0.036/call |
| **Review (Free)** | gemini-2.5-flash | $0.30/1M | $2.50/1M | N/A | ~$0.002/call |
| **Review (Ultra)** | gemini-2.5-flash + Search | $0.30/1M | $2.50/1M | $0.035/prompt* | ~$0.037/call |

*1,500 free grounded prompts/day included

#### Option C: Gemini 2.5 Pro (Premium Quality)

| Call Type | Model | Input Cost | Output Cost | Search Cost | Typical Total |
|-----------|-------|------------|-------------|-------------|---------------|
| **ID Call 1** | gemini-2.5-pro | $1.25/1M | $10.00/1M | N/A | ~$0.008/call |
| **ID Call 2** | gemini-2.5-pro + Search | $1.25/1M | $10.00/1M | $0.035/prompt | ~$0.043/call |
| **Review (Free)** | gemini-2.5-pro | $1.25/1M | $10.00/1M | N/A | ~$0.008/call |
| **Review (Ultra)** | gemini-2.5-pro + Search | $1.25/1M | $10.00/1M | $0.035/prompt | ~$0.043/call |

---

## 3. Direct Cost Comparison (100 Scans/Day)

### Assumptions:
- 80% of scans succeed on ID Call 1 (no search needed)
- 20% of scans need ID Call 2 (with search)
- 30% cache miss rate on reviews (70% cached)
- 10% of users have Ultra tier with search-enabled reviews

| Provider/Model | ID Call 1 (100) | ID Call 2 (20) | Reviews (30) | Ultra Reviews (3) | **Daily Total** |
|----------------|-----------------|----------------|--------------|-------------------|-----------------|
| **OpenAI gpt-4o** | $1.00 | $0.70 | $2.40 | $0.36 | **$4.46** |
| **Gemini 2.0 Flash** | $0.03 | $0.70* | $0.015 | $0.108 | **$0.85** |
| **Gemini 2.5 Flash** | $0.10 | $0.72* | $0.06 | $0.111 | **$0.99** |
| **Gemini 2.5 Pro** | $0.80 | $0.86 | $0.24 | $0.129 | **$2.03** |

*Includes $0.035/grounded prompt for search calls

### Your Current Optimized Cost: ~$0.10/day
This is achieved through aggressive caching (70-80% hit rate). With Gemini, you could achieve:

| Scenario | OpenAI (Current) | Gemini 2.0 Flash | Gemini 2.5 Flash | Savings |
|----------|------------------|------------------|------------------|---------|
| **With Caching** | $0.10/day | $0.02/day | $0.03/day | **70-80%** |
| **Without Caching** | $4.46/day | $0.85/day | $0.99/day | **78-81%** |

---

## 4. Key Pricing Differences: Search Capability

### OpenAI Approach
- `gpt-4o-search-preview` is a **separate model** with built-in search
- Search happens automatically based on model judgment
- Pricing includes token costs + opaque search overhead (~$0.03-0.035/call extra)

### Gemini Approach
- Search is a **tool** (`google_search`) added to any model
- Model decides when to execute searches
- **Transparent per-query billing** coming with Gemini 3:
  - $14/1,000 search queries (vs. $35/1,000 prompts currently)
  - Multiple searches per prompt = multiple charges
  - More control, potentially lower cost for targeted use

### Free Tier Advantage (Gemini)
Gemini offers **1,500 free grounded prompts per day** for 2.5 Flash. This covers:
- All your ID Call 2 searches (20/day in example)
- All your Ultra reviews with search (3/day in example)
- **Net search cost: $0** until you exceed 1,500/day

---

## 5. Recommendation

### For AlbumScan, I recommend: **Gemini 2.5 Flash**

| Factor | Rationale |
|--------|-----------|
| **Cost** | 70-80% cheaper than OpenAI |
| **Vision Quality** | Comparable to GPT-4o for OCR and image understanding |
| **Search** | 1,500 free grounded prompts/day (covers your needs) |
| **JSON Support** | Native structured output mode |
| **Free Tier** | Generous for development and testing |
| **Context Window** | 1M tokens (vs. 128K for GPT-4o) |

### Migration Considerations

1. **API Format**: Different from OpenAI - requires new service implementation
2. **Response Parsing**: Grounding metadata format differs from OpenAI citations
3. **Firebase Integration**: Google Cloud Functions work natively with Gemini/Vertex AI
4. **Testing**: Your prompts should work with minimal modification

---

## 6. Implementation Notes

### Gemini API Request Structure (Vision)

```javascript
// Example: ID Call 1 equivalent with Gemini
const response = await model.generateContent({
  contents: [{
    parts: [
      { text: identificationPrompt },
      { inlineData: { mimeType: "image/jpeg", data: base64Image } }
    ]
  }],
  generationConfig: {
    responseMimeType: "application/json"
  }
});
```

### Gemini API with Search Grounding

```javascript
// Example: ID Call 2 / Ultra Review with search
const response = await model.generateContent({
  contents: [{ parts: [{ text: prompt }] }],
  tools: [{ googleSearch: {} }],  // Enable search grounding
  generationConfig: {
    responseMimeType: "application/json"
  }
});

// Response includes groundingMetadata with citations
const metadata = response.candidates[0].groundingMetadata;
// metadata.webSearchQueries - queries executed
// metadata.groundingChunks - source URIs and titles
```

### Token Consumption for Images

| Image Size | Gemini Tokens | OpenAI Tokens (est.) |
|------------|---------------|----------------------|
| ≤384px | 258 tokens | ~85 tokens (low detail) |
| 768x768 | 258 tokens/tile | ~170 tokens (high detail) |
| 1024x1024 | ~516 tokens (2 tiles) | ~765 tokens |

---

## 7. Risk Assessment

| Risk | Mitigation |
|------|------------|
| **Quality difference** | Test with 50+ album covers before migration |
| **API changes** | Gemini 3 pricing changes Jan 2026; monitor announcements |
| **Response format** | May need prompt adjustments for consistent JSON |
| **Search accuracy** | Google Search may return different results than OpenAI's search |

---

## Sources

- [Gemini Developer API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini Image Understanding](https://ai.google.dev/gemini-api/docs/vision)
- [Grounding with Google Search](https://ai.google.dev/gemini-api/docs/google-search)
- [OpenAI GPT-4o Pricing Guide](https://blog.laozhang.ai/ai/openai-gpt-4o-api-pricing-guide/)
- [LLM API Pricing Comparison 2025](https://intuitionlabs.ai/articles/llm-api-pricing-comparison-2025)
- [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- [Vertex AI Pricing](https://cloud.google.com/vertex-ai/generative-ai/pricing)

---

**Last Updated:** December 7, 2025
