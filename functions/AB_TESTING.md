# A/B Testing: OpenAI vs Gemini

This document outlines the metrics to monitor when comparing OpenAI and Gemini providers.

## Test Configuration

- **OpenAI Functions:** `identifyAlbum`, `searchFinalizeAlbum`, `generateReview`
- **Gemini Functions:** `identifyAlbumGemini`, `searchFinalizeAlbumGemini`, `generateReviewGemini`
- **Toggle Location:** iOS Debug builds only (`#if DEBUG` in CameraView.swift)
- **Default Provider:** OpenAI (production)

## Metrics to Monitor

### 1. Accuracy Metrics

| Metric | How to Measure | Target |
|--------|----------------|--------|
| Album Identification Rate | % of scans that return valid album data | > 90% |
| Correct Artist/Album Match | Manual verification of sample scans | > 95% |
| Review Quality | User satisfaction / content relevance | Subjective |

### 2. Performance Metrics

Monitor via Firebase Console > Functions > Logs:

| Metric | Log Pattern | Target |
|--------|-------------|--------|
| Latency (ID Call 1) | `[identifyAlbum*] Processing request` to response | < 5s |
| Latency (ID Call 2) | `[searchFinalizeAlbum*] Processing request` to response | < 8s |
| Latency (Review) | `[generateReview*] Processing request` to response | < 10s |
| Error Rate | `Error:` in function logs | < 2% |

### 3. Cost Metrics

Monitor via Google Cloud Console:

| Provider | Pricing Model | Monitoring Location |
|----------|---------------|---------------------|
| OpenAI | Per-token (input + output) | OpenAI Usage Dashboard |
| Gemini | Per-token (varies by model) | Google Cloud Billing |

**Token Usage Logs:**
- OpenAI: `Tokens used: X (prompt: Y, completion: Z)`
- Gemini: Response length logged in chars

### 4. Reliability Metrics

| Metric | What to Watch |
|--------|---------------|
| JSON Parse Failures | `JSON validation failed` in logs |
| MAX_TOKENS Truncation | `finish: MAX_TOKENS` or `finishReason: MAX_TOKENS` |
| Rate Limit Hits | `resource-exhausted` errors |
| Grounding Success | `Grounding sources: N` (should be > 0 for Ultra) |

## Firebase Console Queries

### View Gemini-specific logs:
```
resource.type="cloud_function"
resource.labels.function_name=~".*Gemini.*"
```

### View errors only:
```
resource.type="cloud_function"
severity>=ERROR
```

### Compare latencies:
```
resource.type="cloud_function"
"Processing request"
```

## Test Procedure

1. Enable Debug toggle on test device
2. Perform 10+ scans with each provider
3. Record:
   - Success/failure for each scan
   - Subjective quality of reviews (1-5)
   - Note any obvious errors (wrong album, truncated content)
4. Check Firebase logs for errors and latencies
5. Compare costs after test period

## Decision Criteria

Consider switching to Gemini as default if:
- [ ] Accuracy >= OpenAI
- [ ] Latency within 20% of OpenAI
- [ ] Cost < OpenAI (or within 10% with better quality)
- [ ] Error rate < 2%
- [ ] Grounding/citations working correctly for Ultra tier
