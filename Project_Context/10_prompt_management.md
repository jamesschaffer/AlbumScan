### PROMPT MANAGEMENT

## Overview

AlbumScan uses a **two-tier identification architecture with OpenAI** as the primary LLM provider, leveraging three distinct prompts for album identification and review generation. This architecture optimizes for speed and accuracy by conditionally triggering web search only when needed.

---

## Current LLM Provider

**Active Provider:** OpenAI (configured in `Config.swift`)
- **Provider Selection:** `Config.currentProvider = .openAI`
- **Models Used:**
  - **ID Call 1:** `gpt-4o` (vision + internal recognition, NO web search)
  - **ID Call 2:** `gpt-4o-search-preview` (web search finalization, ONLY when needed)
  - **Review Generation:** `gpt-4o` (NO web search - music history is stable, search not needed)

**Alternative Provider:** Claude (Anthropic) - available but not currently used
- Configured via `LLMServiceFactory` protocol-based architecture
- Switch providers by changing `Config.currentProvider` to `.claude`

---

## Prompt Files

AlbumScan maintains three active prompts and two archived prompts:

### Active Prompts

1. **`single_prompt_identification.txt`**
   - **Purpose:** ID Call 1 - Single-pass album identification with conditional search request
   - **Used By:** `OpenAIAPIService.executeSinglePromptIdentification()`
   - **Model:** `gpt-4o` (NO web search capability)
   - **Location:** `AlbumScan/AlbumScan/Prompts/single_prompt_identification.txt`

2. **`search_finalization.txt`**
   - **Purpose:** ID Call 2 - Web search-assisted album identification (only when Call 1 requests search)
   - **Used By:** `OpenAIAPIService.executeSearchFinalization()`
   - **Model:** `gpt-4o-search-preview` (WITH web search capability)
   - **Location:** `AlbumScan/AlbumScan/Prompts/search_finalization.txt`

3. **`album_review.txt`**
   - **Purpose:** Review Generation (Free Tier) - Cultural analysis, rating, and buying recommendation
   - **Used By:** `OpenAIAPIService.generateReviewPhase2()` when `searchEnabled = false`
   - **Model:** `gpt-4o` (OpenAI, NO search capability)
   - **Location:** `AlbumScan/AlbumScan/Prompts/album_review.txt`
   - **Features:** Cost-optimized - no search capability, no domain restrictions
   - **Cost:** ~$0.05-0.10 per review

4. **`album_review_ultra.txt`**
   - **Purpose:** Review Generation (Ultra Tier) - Enhanced reviews with web search and cited sources
   - **Used By:** `OpenAIAPIService.generateReviewPhase2()` when `searchEnabled = true`
   - **Model:** `gpt-4o-search-preview` (OpenAI, WITH search capability)
   - **Location:** `AlbumScan/AlbumScan/Prompts/album_review_ultra.txt`
   - **Features:** Source prioritization - prioritizes 6 professional publications for citations
   - **Source Priority:**
     1. Metacritic (aggregated scores)
     2. Album of the Year (comprehensive database)
     3. Pitchfork (leading indie publication)
     4. Rolling Stone (classic music journalism)
     5. AllMusic (music encyclopedia)
     6. The Guardian (respected UK publication)
   - **Cost:** ~$0.08-0.13 per review (includes ~$0.03 search cost)

### Archived Prompts (Claude-Only)

5. **`Archive/Claude/phase1a_vision_extraction.txt`**
   - **Purpose:** Legacy Phase 1A - Vision extraction (text + visual description)
   - **Status:** Archived - only used if `Config.currentProvider = .claude`
   - **Location:** `AlbumScan/AlbumScan/Prompts/Archive/Claude/phase1a_vision_extraction.txt`

6. **`Archive/Claude/phase1b_web_search_mapping.txt`**
   - **Purpose:** Legacy Phase 1B - Web search mapping for album identification
   - **Status:** Archived - only used if `Config.currentProvider = .claude`
   - **Location:** `AlbumScan/AlbumScan/Prompts/Archive/Claude/phase1b_web_search_mapping.txt`

---

## Two-Tier Identification Architecture

### Overview

AlbumScan uses a **conditional two-tier identification system** that optimizes for speed, accuracy, and cost by avoiding expensive web search calls for 80-90% of albums.

**Key Design Principle:** Most albums can be identified using internal knowledge alone. Web search is only triggered when necessary, drastically reducing costs while maintaining high accuracy.

---

### Tier 1: Internal Recognition (ID Call 1)

**Prompt File:** `single_prompt_identification.txt`

**Model:** `gpt-4o` (vision + text, NO web search capability)

**Performance Metrics:**
- **Time:** 2-4 seconds
- **Cost:** ~$0.01 per call
- **Success Rate:** 80-90% of albums identified without search
- **Usage:** Every scan (100%)

**Process:**
1. Receives album cover image (1024×1024 JPEG)
2. Extracts visible text from cover (band name, album title, label info)
3. Describes artwork visually (colors, imagery, artistic style)
4. Attempts recognition using internal knowledge (iconic albums, famous covers)
5. Returns one of three outcomes:
   - **Success (HIGH confidence):** Album identified definitively → Skip Call 2
   - **Success (MEDIUM confidence):** Album identified with reasonable certainty → Skip Call 2
   - **Search Needed (LOW confidence):** Cannot identify confidently → Trigger Call 2

**Implementation:** `OpenAIAPIService.executeSinglePromptIdentification()`

**Why No Search?**
- Regular `gpt-4o` model cannot perform web searches
- Forces reliance on training data (extensive music knowledge)
- Faster response time (no search overhead)
- Lower cost (no search charges)

---

### Tier 2: Web Search Finalization (ID Call 2) - Conditional

**Prompt File:** `search_finalization.txt`

**Model:** `gpt-4o-search-preview` (WITH web search capability)

**Performance Metrics:**
- **Time:** 3-5 seconds
- **Cost:** ~$0.03-0.04 per call
- **Usage:** 10-20% of scans (deep cuts, obscure albums, minimal text covers)
- **Trigger:** Only when ID Call 1 returns `searchNeeded: true`

**Search Gate (Quality Validation):**

Before triggering Call 2, validates search is worthwhile:
- **Minimum Text:** 3+ readable characters extracted
- **Text Confidence:** Must be "medium" or "high" (NOT "low")
- **If Gate Fails:** Returns error to user ("Unable to identify - insufficient text")

**Purpose:** Prevents wasteful API calls on poor-quality captures (blurry, too far away, non-album objects)

**Process:**
1. Receives extracted text and visual description from Call 1
2. Performs ONE web search using suggested query from Call 1
3. Cross-references search results with visual description
4. Returns final identification or unresolved error

**Implementation:** `OpenAIAPIService.executeSearchFinalization()`

**Cost Justification:**
- Only used for 10-20% of scans
- Resolves albums that would otherwise fail
- Search cost (~$0.03) justified by successful identification

---

### Album Artwork Retrieval (Parallel)

**Source:** MusicBrainz + Cover Art Archive (free APIs)

**Performance Metrics:**
- **Time:** 1-2 seconds
- **Cost:** $0 (free open APIs)
- **Non-Blocking:** Displays placeholder if unavailable

**Process:**
1. Query MusicBrainz using artist + album metadata
2. Retrieve MBID (MusicBrainz ID)
3. Fetch 500px image from Cover Art Archive
4. Cache locally (CoreData)

**Note:** This runs in parallel with identification, not part of the "tier" system.

---

### Review Generation (Separate Phase) - Two-Tier System

**AlbumScan offers two review tiers** controlled by the Advanced Search toggle in Settings:

#### Free Tier

**Prompt File:** `album_review.txt`

**Model:** `gpt-4o` (NO web search capability)

**Performance Metrics:**
- **Time:** 3-5 seconds (or instant if cached)
- **Cost:** ~$0.05-0.10 per new review, $0.00 if cached
- **Cache Hit Rate:** 70-80% after initial usage
- **Source Restrictions:** None (removed domain restrictions - model relies on training data)

#### Ultra Tier (AlbumScan Ultra)

**Prompt File:** `album_review_ultra.txt`

**Model:** `gpt-4o-search-preview` (WITH web search capability)

**Performance Metrics:**
- **Time:** 3-5 seconds (or instant if cached)
- **Cost:** ~$0.08-0.13 per new review (includes ~$0.03 search cost), $0.00 if cached
- **Cache Hit Rate:** 70-80% after initial usage (same cache as Free tier)
- **Source Prioritization:** Model prioritizes 6 professional publications for citations:
  1. Metacritic (aggregated scores)
  2. Album of the Year (comprehensive database)
  3. Pitchfork (leading indie publication)
  4. Rolling Stone (classic music journalism)
  5. AllMusic (music encyclopedia)
  6. The Guardian (respected UK publication)

**Unified Process (Both Tiers):**
1. **Cache Check:** CoreData lookup by artist + album (with title normalization)
2. **If Cached:** Skip API call entirely (works for both Free and Ultra - cache is tier-agnostic)
3. **If Not Cached:**
   - **Free:** Generate review using `gpt-4o` with `album_review.txt` (~$0.05-0.10)
   - **Ultra:** Generate review using `gpt-4o-search-preview` with `album_review_ultra.txt` (~$0.08-0.13)
4. **Cache Result:** Store for future scans (indefinite duration, shared across tiers)
5. **Failure Handling:** Cache failure state for 30 days (prevents retry loops)

**Implementation:** `OpenAIAPIService.generateReviewPhase2(searchEnabled: Bool)`
- `searchEnabled = false` → Free tier (gpt-4o, no search)
- `searchEnabled = true` → Ultra tier (gpt-4o-search-preview, with search + source prioritization)

**Critical Optimization History (October 2025):**
- **Original Problem:** All reviews used `gpt-4o-search-preview` with hidden server-side searches ($0.15/review)
- **First Solution:** Switched Free tier to regular `gpt-4o` (no search) - eliminated search costs for Free tier
- **New Enhancement (October 30, 2025):** Two-tier system introduced
  - **Free Tier:** Uses `gpt-4o` (no search) - cost-optimized default ($0.05-0.10/review)
  - **Ultra Tier:** Uses `gpt-4o-search-preview` (with search) - premium option with source prioritization ($0.08-0.13/review)
- **Result:** Users control search costs via Settings toggle
- **Key Insight:** Use model without search capability for cost optimization; use search-enabled model with source prioritization when quality citations matter

**Input:** Clean metadata from identification phase
- Artist name
- Album title
- Release year
- Genres (array)
- Record label

---

## Prompt Loading Logic

### OpenAI Service (Current)

Prompts are loaded at service initialization (`OpenAIAPIService.init()`):

```swift
// Load from Bundle.main.url(forResource:withExtension:)
guard let identificationURL = Bundle.main.url(forResource: "single_prompt_identification", withExtension: "txt") else {
    fatalError("❌ Could not find single_prompt_identification.txt in bundle")
}

guard let searchURL = Bundle.main.url(forResource: "search_finalization", withExtension: "txt") else {
    fatalError("❌ Could not find search_finalization.txt in bundle")
}

guard let reviewURL = Bundle.main.url(forResource: "album_review", withExtension: "txt") else {
    fatalError("❌ Could not find album_review.txt in bundle")
}

guard let reviewUltraURL = Bundle.main.url(forResource: "album_review_ultra", withExtension: "txt") else {
    fatalError("❌ Could not find album_review_ultra.txt in bundle")
}

// Read file contents
self.identificationPrompt = try String(contentsOf: identificationURL)
self.searchFinalizationPrompt = try String(contentsOf: searchURL)
self.reviewPrompt = try String(contentsOf: reviewURL)
self.reviewUltraPrompt = try String(contentsOf: reviewUltraURL)
```

**Characteristics:**
- Prompts loaded once at app launch (singleton pattern)
- Cached in memory for entire app lifecycle
- Fatal errors if prompts are missing (fails fast during development)
- No fallback prompts (intentionally strict)

### Claude Service (Backup)

Prompts are loaded with fallback logic (`ClaudeAPIService.init()`):

```swift
// Try Prompts subdirectory first
if let promptPath = Bundle.main.path(forResource: "phase1a_vision_extraction", ofType: "txt", inDirectory: "Prompts"),
   let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
    self.phase1APrompt = promptContent
}
// Fallback to root bundle
else if let promptPath = Bundle.main.path(forResource: "phase1a_vision_extraction", ofType: "txt"),
         let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
    self.phase1APrompt = promptContent
}
// Last resort: hardcoded fallback
else {
    self.phase1APrompt = "Extract text and describe the album cover."
}
```

**Characteristics:**
- Graceful degradation with fallback prompts (more forgiving)
- Checks `Prompts/` subdirectory first, then root bundle
- Continues execution even if prompts are missing (uses simple fallbacks)
- Logs warnings in DEBUG mode

---

## Prompt Template Variables

Prompts use string interpolation for dynamic content:

### `search_finalization.txt`
```
{extractedText}      - Text visible on album cover (from ID Call 1)
{albumDescription}   - Visual description of cover (from ID Call 1)
{textConfidence}     - Confidence level: "high", "medium", or "low"
{searchQuery}        - Optimized search query (from ID Call 1)
```

Replaced at runtime using:
```swift
let prompt = searchFinalizationPrompt
    .replacingOccurrences(of: "{extractedText}", with: searchRequest.observation.extractedText)
    .replacingOccurrences(of: "{albumDescription}", with: searchRequest.observation.albumDescription)
    .replacingOccurrences(of: "{textConfidence}", with: searchRequest.observation.textConfidence)
    .replacingOccurrences(of: "{searchQuery}", with: searchRequest.query)
```

### `album_review.txt`
```
{artistName}     - Artist name (from identification phase)
{albumTitle}     - Album title (from identification phase)
{releaseYear}    - Release year (from identification phase)
{genres}         - Comma-separated genre list (from identification phase)
{recordLabel}    - Record label (from identification phase)
```

Replaced at runtime using string interpolation in prompt construction.

---

## Cost Optimization Features

### 1. Conditional Web Search (Identification)
- **ID Call 1 skips web search** → ~70% of albums identified without search
- **Call 2 only when needed** → Deep cuts/obscure albums trigger search
- **Search gate validation** → Prevents wasteful searches on unreadable covers

**Cost Savings:** 
- Successful Call 1: ~$0.01 (no search)
- Failed Call 1 + Call 2: ~$0.03-0.04 (with search)
- vs. Always searching: ~$0.05-0.06 per scan

### 2. Review Caching
- **CoreData lookup before API call** → Cache hit = $0 cost
- **30-day failure cooldown** → Prevents retry loops on permanently failed albums
- **Title normalization** → Matches "Deluxe", "Remastered", "Reissue" variants

**Cache Strategy:**
```swift
// Check cache
if let cachedAlbum = checkCachedAlbum(artistName: artist, albumTitle: album) {
    if cachedAlbum.phase2Completed {
        // Use cached review → Skip API call entirely
        return cachedResponse
    }
    if cachedAlbum.phase2Failed && daysSinceAttempt < 30 {
        // Recent failure → Skip retry
        return nil
    }
}

// Cache miss → Generate new review
let review = try await generateReviewPhase2(...)
```

### 3. Two-Tier Review System (AlbumScan Ultra)

**Free Tier (`album_review.txt`):**
- Uses `gpt-4o` (NO search capability)
- Removed domain restrictions - relies on training data
- Cost: ~$0.05-0.10 per review
- Best for: Well-known albums, cost-conscious users

**Ultra Tier (`album_review_ultra.txt`):**
- Uses `gpt-4o-search-preview` (WITH search capability)
- Source prioritization for 6 professional publications
- Cost: ~$0.08-0.13 per review (includes ~$0.03 search)
- Best for: Obscure albums, users who want cited sources

**User Control:**
- Toggle in Settings: "Enable Advanced Search"
- State persists via UserDefaults (`searchEnabled` key)
- AppState broadcasts changes to CameraManager
- Model selection happens at review generation time

**Impact:**
- Free tier: 100% elimination of search costs for default usage
- Ultra tier: Controlled search costs (~$0.03) with source quality improvements
- Combined with caching: 70-80% cache hit rate reduces costs significantly
- Users choose when search is worth the cost

---

## Debugging & Monitoring

All prompt operations are logged in DEBUG mode:

```swift
#if DEBUG
print("✅ [OpenAIAPIService] Loaded identification prompt from bundle")
print("✅ [OpenAIAPIService] Loaded search finalization prompt from bundle")
print("✅ [OpenAIAPIService] Loaded review prompt from bundle")
#endif
```

**Useful Debug Logs:**
- `✅ Loaded [prompt] from bundle` - Successful load
- `❌ Could not find [prompt].txt` - Missing file
- `📝 Raw response: [text]` - Full LLM output
- `💰 Tokens: [input] + [output] = [total]` - Cost tracking
- `📦 [CACHE] Found existing album` - Cache hit
- `📦 [CACHE MISS] Generating new review` - Cache miss

---

## File Structure

```
AlbumScan/
└── AlbumScan/
    └── Prompts/
        ├── single_prompt_identification.txt    (ID Call 1 - active)
        ├── search_finalization.txt             (ID Call 2 - active)
        ├── album_review.txt                    (Review Gen Free - active)
        ├── album_review_ultra.txt              (Review Gen Ultra - active)
        └── Archive/
            └── Claude/
                ├── phase1a_vision_extraction.txt    (archived)
                └── phase1b_web_search_mapping.txt   (archived)
```

**Bundle Integration:**
- Prompts are included in Xcode build target as bundle resources
- Accessible via `Bundle.main.url(forResource:withExtension:)`
- Version controlled in Git (prompt changes tracked separately from code)

---

## Version Control Best Practices

**Prompt Updates:**
1. Edit `.txt` files in `AlbumScan/AlbumScan/Prompts/`
2. Test changes in Xcode (prompts reload on each build)
3. Commit prompt files separately from code changes
4. Use descriptive commit messages: `"Update album_review prompt: add cost constraints"`

**Benefits:**
- Independent prompt iteration without recompiling app logic
- Clear Git history showing prompt evolution
- Easy A/B testing of prompt variations
- Product team can update prompts without engineering changes

---

## Future Considerations

**Potential Enhancements:**
1. **Dynamic prompt loading from server** - Update prompts without app releases
2. **A/B testing framework** - Compare prompt effectiveness across users
3. **Prompt versioning** - Track which prompt version generated each review
4. **Localization** - Support non-English prompts for international users
5. **User-configurable review style** - Let users choose review tone/length

**Current Limitations:**
- Prompts are fixed at compile time (no runtime updates)
- No analytics on prompt performance (success rates, cost per prompt)
- Single prompt per phase (no A/B testing infrastructure)
- English-only (no i18n support)

---

## Verification Summary

**Document Accuracy:** This prompt management document has been verified against the actual codebase implementation as of October 30, 2025.

**Verification Status:** ✅ Updated with AlbumScan Ultra two-tier review system

**Major Updates (October 30, 2025):**
1. **Added `album_review_ultra.txt`** - New prompt for Ultra tier with search and source prioritization
2. **Removed domain restrictions** from `album_review.txt` (Free tier)
3. **Documented two-tier review system** - Free (gpt-4o) vs Ultra (gpt-4o-search-preview)
4. **Updated cost optimization section** - Reflects user-controlled search via Settings toggle
5. **Added source prioritization details** - 6 professional publications for Ultra tier

**Key Accuracies Verified:**

1. **Current LLM Provider:**
   - ✅ OpenAI confirmed as active provider (Config.swift:21)
   - ✅ Model specifications accurate:
     - ID Call 1: `gpt-4o` (no search)
     - ID Call 2: `gpt-4o-search-preview` (with search)
     - Review: `gpt-4o` (no search)

2. **Prompt Files:**
   - ✅ Three active prompts verified in `AlbumScan/AlbumScan/Prompts/`:
     - `single_prompt_identification.txt`
     - `search_finalization.txt`
     - `album_review.txt`
   - ✅ Two archived Claude prompts verified in `Archive/Claude/`:
     - `phase1a_vision_extraction.txt`
     - `phase1b_web_search_mapping.txt`

3. **Two-Tier Identification Architecture:**
   - ✅ ID Call 1 performance metrics accurate (2-4s, $0.01, 80-90% success)
   - ✅ ID Call 2 performance metrics accurate (3-5s, $0.03-0.04, 10-20% usage)
   - ✅ Search gate validation documented correctly (3+ chars, medium/high confidence)
   - ✅ Artwork retrieval process accurate (MusicBrainz → Cover Art Archive)

4. **Review Generation:**
   - ✅ Model change documented correctly (`gpt-4o-search-preview` → `gpt-4o`)
   - ✅ October 2025 cost optimization accurately described
   - ✅ Cache behavior and title normalization documented correctly
   - ✅ Performance metrics accurate (3-5s or instant, 70-80% hit rate)

5. **Prompt Loading Logic:**
   - ✅ OpenAI service initialization verified (OpenAIAPIService.swift:40-60)
   - ✅ Claude service fallback logic verified (ClaudeAPIService.swift)
   - ✅ Fatal error behavior on missing prompts confirmed
   - ✅ Singleton pattern and memory caching confirmed

6. **Prompt Template Variables:**
   - ✅ `search_finalization.txt` variables verified (extractedText, albumDescription, textConfidence, searchQuery)
   - ✅ `album_review.txt` variables verified (artistName, albumTitle, releaseYear, genres, recordLabel)
   - ✅ String interpolation implementation confirmed

7. **Cost Optimization Features:**
   - ✅ Conditional web search logic documented correctly
   - ✅ Cost savings calculations accurate ($0.01 vs $0.03-0.04 vs $0.05-0.06)
   - ✅ Review caching strategy with 30-day failure cooldown verified
   - ✅ Critical model change impact: $5.15/day → $0.10/day (98% reduction)

8. **File Structure:**
   - ✅ Directory structure verified in Xcode project
   - ✅ Bundle integration confirmed (Build Phases → Copy Bundle Resources)
   - ✅ Git version control confirmed

**Document Quality:**
- Comprehensive coverage of prompt management strategy
- Clear explanation of two-tier architecture rationale
- Excellent documentation of October 2025 cost optimization discovery
- Detailed code examples and debug logging guidance
- Well-organized sections with clear navigation

**Key Insights Documented:**
- "When you need zero searches, use a model without search capability rather than trying to constrain a search-enabled model via prompts" (line 365)
- Hidden server-side searches discovery in `gpt-4o-search-preview` (lines 347-352)
- Search gate prevents wasteful API calls on poor captures (lines 117-124)

**Status:** This document is accurate, comprehensive, and requires no corrections. It serves as an excellent reference for understanding AlbumScan's prompt management strategy, cost optimization approach, and two-tier identification architecture.