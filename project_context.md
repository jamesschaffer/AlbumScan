# PROJECT_CONTEXT.md
# AlbumScan - Music Album Discovery iOS App - Complete Development Guide

**Version:** 1.2 (Four-Phase API Architecture)
**Last Updated:** October 25, 2025  
**Platform:** iOS (Minimum iOS 16+)  
**Development Stack:** Swift + SwiftUI  

---

## TABLE OF CONTENTS
1. [Project Overview](#project-overview)
2. [Executive Summary](#executive-summary)
3. [User Personas](#user-personas)
4. [Core Features](#core-features)
5. [User Flows](#user-flows)
6. [Screen Architecture](#screen-architecture)
7. [Four-Phase API Architecture](#four-phase-api-architecture)
8. [Technical Stack](#technical-stack)
9. [API Integration Details](#api-integration-details)
10. [Data Model](#data-model)
11. [Camera Implementation](#camera-implementation)
12. [UI/UX Requirements](#uiux-requirements)
13. [Error Handling](#error-handling)
14. [Testing Strategy](#testing-strategy)

---

## PROJECT OVERVIEW

- **App Name:** AlbumScan
- **Version:** 1.2 (Four-Phase API Architecture)
- **Purpose:** A music discovery companion that reveals the cultural significance and artistic merit of albums through photo identification
- **Target Audience:** Music collectors, vinyl enthusiasts, record store browsers who prioritize artistic value over financial value
- **Platform:** iOS (minimum iOS 16+)
- **Development Approach:** Native iOS using Swift/SwiftUI
- **MVP Scope:** Photo identification + cultural context only. NO Spotify playback integration in MVP.

---

## EXECUTIVE SUMMARY

This iOS application celebrates the joy of music discovery by helping collectors identify albums and understand their cultural significance, artistic merit, and historical impact. When digging through record store bins filled with hundreds of unfamiliar albums, collectors need a knowledgeable companion that can answer: "Is this musically important? Did this influence other artists? Is this album beloved by musicians and critics?"

**This app is deliberately NOT about pricing, pressing values, or financial collectibility.** Instead, this app focuses on the artistic and cultural dimensions of music discovery - helping users find albums that matter because of their sound, innovation, influence, and artistry.

**Key Innovation: Four-Phase API Strategy**
The app uses a sequential four-phase approach that optimizes for accuracy, speed, and cost:
- **Phase 1A (1-2 seconds):** Vision extraction - Extract visible text and describe cover artwork
- **Phase 1B (1-2 seconds):** Web search mapping - Identify album using extracted data + web search
- **Phase 2 (2-3 seconds):** Artwork retrieval - Fetch high-resolution album art from MusicBrainz
- **Phase 3 (3-5 seconds):** Review generation - Generate cultural analysis and buying recommendation

This architecture ensures accurate album identification (Phases 1A/1B handle edge cases like acronyms and minimal text), confirms the match with users (2-second preview), then generates expensive review content only after successful identification.

The app uses AI-powered album identification (Claude API) to provide instant context about why an album matters musically. It's like having a passionate music historian in your pocket who can instantly tell you "this is the album that invented shoegaze" or "this obscure funk record was sampled by dozens of hip-hop producers."

---

## USER PERSONAS

### Primary Persona: "Record Store Browser Sarah"
- **Demographics:** 28 years old, urban professional, moderate vinyl collector
- **Goals/Needs:** 
  - Discover musically significant albums while digging through bins
  - Learn about albums that influenced her favorite contemporary artists
  - Find hidden gems and culturally important records she's never heard of
  - Understand why certain albums are considered classics or important
  - Remember discoveries so she can listen to them later (on her own via Spotify/Apple Music/etc.)
- **Pain Points:** 
  - Surrounded by thousands of albums but doesn't know their musical significance
  - Doesn't want to just buy "valuable" records - wants artistically meaningful ones
  - Can't tell which obscure album might be an influential masterpiece
  - Frustrated by price-focused collecting culture - she cares about the music
  - Forgets album names by the time she gets home to look them up
- **Technical Proficiency:** High - comfortable with modern apps and streaming services
- **Collection Philosophy:** "I collect albums that move me or taught me something about music, not albums that are worth money"

### Secondary Persona: "Vinyl Enthusiast Mike"
- **Demographics:** 45 years old, seasoned music lover with 500+ records
- **Goals/Needs:**
  - Discover the musical stories behind unfamiliar albums
  - Understand an album's place in music history and its influence
  - Learn about artists he's never encountered before
  - Find connections between albums (samples, influences, collaborations)
  - Share musical knowledge and discoveries with fellow enthusiasts
- **Pain Points:**
  - Tired of apps that only tell him what an album is "worth"
  - Wants to know WHY an album matters, not what it sells for
  - Difficult to quickly assess musical significance of unknown albums
  - Estate sales and thrift stores full of albums with no context about their artistry
  - Time-consuming to research every interesting album cover he sees
- **Technical Proficiency:** Moderate - uses smartphone regularly but not highly technical
- **Collection Philosophy:** "I dig for music that expanded boundaries or captured a moment in time, not for investment pieces"

---

## CORE FEATURES

### Feature 1: Camera-Based Album Identification
- **Priority:** MUST-HAVE (Core feature)
- **Description:** Users can take a photo of any album cover, and the app will identify it using AI vision
- **User Story:** "As a record store browser, I want to take a photo of an album cover so that I can instantly know what album it is and who the artist is"
- **Acceptance Criteria:**
  - Camera View shows live camera feed immediately upon load (optimized for speed)
  - User taps "SCAN" button to capture photo (no review/retake - immediate send)
  - Photo is processed via four-phase API approach:
    - Phase 1A: Vision extraction (1-2 seconds)
    - Phase 1B: Web search mapping (1-2 seconds)
    - Phase 2: Artwork retrieval (2-3 seconds)
    - Phase 3: Review generation (3-5 seconds)
  - App displays album name, artist, and artwork after Phase 2 completion (2-second confirmation screen)
  - If Phases 1A/1B/2 fail, displays "Couldn't find a match" message with "Try Again" button
  - Phase 3 runs after 2-second confirmation screen
  - If Phase 3 fails, shows album details with "Review temporarily unavailable" + retry button
  - Works with various cover conditions (worn, angled, partially visible, minimal text, acronyms)
  - Stores only the album cover art from MusicBrainz, NOT the user's original photo

#### Sub-Feature 1A: High-Resolution Album Artwork Retrieval
- **Priority:** MUST-HAVE (Required for Feature 3 display)
- **Description:** After Phase 1B identifies album metadata, retrieve high-resolution album artwork from MusicBrainz + Cover Art Archive (Phase 2)
- **Technical Approach:** Sequential API calls using artist + album metadata from Phase 1B
- **User Story:** "As a user, I want to see high-quality album artwork so that I can visually identify and appreciate the album"
- **Acceptance Criteria:**
  - After Phase 1B returns album identification, immediately initiate MusicBrainz artwork search (Phase 2)
  - Search MusicBrainz API using artist name and album title to find release MBID (MusicBrainz ID)
  - Use MBID to query Cover Art Archive API for album artwork
  - Retrieve highest quality artwork available (prefer "front" cover image)
  - If Cover Art Archive returns no results, fall back to placeholder: "Album art unavailable"
  - Cache retrieved artwork locally (both thumbnail for history and high-res for detail view)
  - Total artwork retrieval should complete within 2-3 seconds
  - Handle multiple release variants by selecting the first matching result (prefer original/main release)
  - Artwork URLs should be stored in Album entity for offline reference
  - If MusicBrainz search returns no matches, still display album details with placeholder artwork
  - Artwork retrieval failure should NEVER block album information display

### Feature 2: Cultural Context & Quality Assessment
- **Priority:** MUST-HAVE (Core differentiator)
- **Description:** AI-powered concise album review providing critical assessment, cultural significance, and buying recommendation - explicitly NOT financial value or pricing information
- **User Story:** "As a record store browser, I want a quick, honest assessment of why an album matters musically and whether I should buy it, so I can make informed decisions while flipping through bins"
- **Architecture:** Generated in Phase 3 (after successful identification and artwork retrieval), uses web search for current information
- **Input:** Receives clean metadata from Phase 1B (artist name, album title, release year, genres, record label)
- **Acceptance Criteria:**
  - Phase 3 prompt receives ONLY metadata (no album identification task)
  - Displays 2-3 sentence opening summary capturing the album's core essence and importance
  - Provides 3-5 bullet points (formatted as actual bullets •) with specific evidence:
    - Critical reception (scores from Pitchfork, Rolling Stone, Metacritic when available)
    - Concrete impact examples (chart performance, sales figures, awards)
    - Specific standout tracks and sonic qualities
    - Genre innovation or influence on other artists
    - Reputation evolution (initially panned vs. later acclaimed, etc.)
  - Includes rating out of 10 (Claude's assessment based on analysis)
  - Provides clear buying recommendation using one of four emoji-badged categories:
    - **ESSENTIAL** 💎 - Must own for any serious music collection
    - **RECOMMENDED** 👍 - Buy if you're a fan of [specific artist/genre/era]
    - **SKIP** 😐 - Not worth your time or money
    - **AVOID** 💩 - Actively bad; belongs in the trash
  - Uses honest, direct language - calls out mediocre or bad albums explicitly
  - Focuses on what actually matters about the album (no filler or generic praise)
  - Evaluates albums purely on musical merit - artist's personal controversies or social issues may be mentioned for context but do NOT devalue their musical contributions or impact
  - Explicitly avoids any language about "investment," "value," "rare," "pressing details," or "collectibility"
  - NEVER mentions price, monetary value, or market considerations
  - All content generated via Claude API Phase 3 using web search for research
  - Shows cached content if album has been scanned before (avoids redundant API calls)
  - If Phase 3 fails, displays album details with "Review temporarily unavailable" + retry button (retry only calls Phase 3, not full scan)

### Feature 3: Album Information Display
- **Priority:** MUST-HAVE
- **Description:** Detailed view showing comprehensive album metadata in a specific visual hierarchy
- **User Story:** "As a music enthusiast, I want to see complete album information so that I can learn about the album before listening"
- **Acceptance Criteria:**
  - Content displays in the following order:
    1. Album artwork (high resolution) - sourced from Cover Art Archive via MusicBrainz (Phase 2)
    2. Artist name and album title (from Phase 1B)
    3. Recommendation badge (ESSENTIAL/RECOMMENDED/SKIP/AVOID with emoji) (from Phase 3)
    4. Cultural context summary (from Feature 2, Phase 3)
    5. Bullet points (3-5) with evidence (from Phase 3)
    6. Rating out of 10 (from Phase 3)
    7. Key Tracks section - Lists most popular/significant tracks from the album (from Phase 3)
  - Also displays: Release year, genre(s), record label (from Phase 1B)
  - Loads instantly from cache if previously scanned (offline access for historical albums)
  - NO pricing information, pressing details, or market value anywhere
  - Loads progressively:
    - Phase 1B data (artist, title, year, genre, label) appears in Loading Screen 2
    - Phase 2 artwork loads in Loading Screen 2
    - Phase 3 review content appears in Album Details Screen
  - Loads instantly from cache if previously scanned (offline access for historical albums)
  - Handles partial failures gracefully:
    - If Phase 2 (artwork) fails: Show placeholder, display all text
    - If Phase 3 fails: Show basic info + "Review temporarily unavailable" with retry button
  - NO pricing information, pressing details, or market value anywhere

### Feature 4: Scan History
- **Priority:** MUST-HAVE (Makes the app useful beyond single-use)
- **Description:** Simple chronological list of all scanned albums (newest first)
- **User Story:** "As a user, I want to review albums I've scanned so that I can remember what I found interesting"
- **Acceptance Criteria:**
  - Chronologically ordered list (newest first)
  - Shows album cover thumbnail, title, and artist for each entry
  - Every scan is automatically saved to history (including duplicate scans of same album)
  - Users manage their list by swiping to delete unwanted entries
  - Tapping item reopens full album information display (Feature 3)
  - Persists locally on device with unlimited storage (no cap on saved albums)
  - Simple delete option (swipe-to-delete)
  - No search/filter functionality in MVP (scroll only)
  - History icon (clock symbol) is hidden on Camera View until user scans their first album
  - If API is unavailable, displays retry button for failed loads

---

## USER FLOWS

### Flow 1: First-Time User Onboarding
```
Launch App (First Time) → Welcome Screen → Camera Permission Request → Camera View (Screen 1)
```

### Flow 2: Primary Use Case - Album Scan & Musical Discovery (Four-Phase)
```
Launch App → Camera View 
  → Tap "SCAN" Button 
  → Loading Screen 1: "Flipping through every record bin in existence..." 
     (Runs Phase 1A: Vision Extraction + Phase 1B: Web Search Mapping + Phase 2: Artwork Retrieval, ~4-6 sec)
  → Loading Screen 2: Shows album artwork + "We found {Album Title} by {Artist Name}" 
     (2-second confirmation hold)
  → Loading Screen 3: "Writing a review that's somehow both pretentious and correct..." 
     (Runs Phase 3: Review Generation, ~3-5 sec)
  → Album Details Screen (Full review display) 
  → Auto-saved to History 
  → Tap "X" → Camera View
```

### Flow 3: Album Scan - Phase 1A/1B/2 Failure (Identification Failed)
```
Launch App → Camera View 
  → Tap "SCAN" Button 
  → Loading Screen 1: "Flipping through every record bin in existence..." 
     (Phase 1A/1B/2 fail)
  → Scan Error Screen: "Couldn't find a match" 
  → Tap "TRY AGAIN" → Camera View
```

### Flow 4: Album Scan - Phase 3 Failure (Review Generation Failed)
```
Launch App → Camera View 
  → Tap "SCAN" Button 
  → Loading Screen 1: "Flipping through every record bin in existence..." 
     (Phase 1A/1B/2 succeed)
  → Loading Screen 2: Shows album artwork + "We found {Album Title} by {Artist Name}" 
     (2-second confirmation)
  → Loading Screen 3: "Writing a review that's somehow both pretentious and correct..." 
     (Phase 3 fails)
  → Album Details Screen with basic info + artwork + "Review temporarily unavailable"
  → User taps "Retry Review" → Re-runs Phase 3 only
  → Review appears on success
```

### Flow 5: Review Scan History
```
Launch App → Camera View → Tap History Icon 
  → Scan History Screen 
  → Tap Album → Album Details Screen 
  → Tap "X" → Scan History Screen
```

### Flow 6: Scan from History View
```
Scan History Screen → Tap "SCAN" Button → Camera View 
  → Tap "SCAN" Button → [Follow Flow 2]
```

### Flow 7: Delete Album from History
```
Scan History Screen → Swipe Left on Album → Tap Delete → Album Removed from List
```

### Flow 8: Re-scan Existing Album (Duplicate Allowed)
```
Camera View → Tap "SCAN" Button → [Follow Flow 2]
```
**Note:** All scans are saved to history, including duplicates. Users manage duplicates by swiping to delete.

### Flow 9: Camera Permission Denied
```
Launch App (First Time) → Welcome Screen → Camera Permission Request → User Denies 
  → Permission Error Screen → "Open Settings" Button → iOS Settings 
  → User Grants Permission → Return to App → Camera View
```

---

## SCREEN ARCHITECTURE

### Screen 1: Camera View (Default Home Screen)
- **Purpose:** Live camera feed for scanning album covers
- **Key Elements:**
  - Full-screen live camera feed
  - Square framing guide overlay (to center album covers)
    - The area outside the guide overlay should be black with 80% opacity
    - This square should be as large as possible with ~20px margin on the left and right of the screen
    - This square should be positioned perfectly center measured from the top and bottom of the iPhone
  - When the picture is taken, crop everything that is outside the guide so other records in the background are not included
  - Set the camera lens to the 1x default zoom
  - Large "SCAN" button at bottom
  - History icon (clock symbol) - only visible after first successful scan
- **Navigation:** 
  - App launches directly to this screen (after first-time onboarding)
  - History icon → Scan History (Screen 4)
  - SCAN button → Screen 2 (Identification Loading)

### Loading Screen 1: Combined Identification + Artwork Retrieval
- **Purpose:** Indicates album identification and artwork retrieval in progress
- **Phases Running:** Phase 1A (Vision Extraction) + Phase 1B (Web Search Mapping) + Phase 2 (Artwork Retrieval)
- **Key Elements:**
  - "ALBUM SCAN" header (top, white text)
  - Animated text with trailing ellipsis (...): "Flipping through every record bin in existence..."
  - Text animation: ellipsis cycles through 1, 2, 3 dots
  - Minimum display time: 1 second (even if all phases complete faster)
  - No cancel button
  - Black background, white text
- **Duration:** ~4-6 seconds total (Phase 1A: 1-2s, Phase 1B: 1-2s, Phase 2: 2-3s)
- **Navigation:** 
  - Success (all three phases complete) → Loading Screen 2 (Album Identified Confirmation)
  - Failure (any phase fails) → Scan Error Screen

### Loading Screen 2: Album Identified Confirmation
- **Purpose:** Shows user the album we matched with 2-second confirmation hold
- **Phases Complete:** Phase 1A, 1B, 2 (identification + artwork retrieval complete)
- **Key Elements:**
  - Album artwork (high-resolution from Cover Art Archive, or placeholder if unavailable)
  - Text: "We found {Album Title} by {Artist Name}"
  - Clean, centered layout
  - No loading animation (static screen)
  - Black background
- **Duration:** Exactly 2 seconds (fixed hold time)
- **Purpose:** Allows user to visually confirm correct album match before review loads
- **Navigation:** 
  - After 2 seconds → Automatically transitions to Loading Screen 3 (Review Generation)

### Loading Screen 3: Review Generation
- **Purpose:** Indicates review generation in progress after user has confirmed album match
- **Phase Running:** Phase 3 (Review Generation)
- **Key Elements:**
  - Animated text with trailing ellipsis (...): "Writing a review that's somehow both pretentious and correct..."
  - Text animation: ellipsis cycles through 1, 2, 3 dots
  - Minimum display time: 1 second (even if Phase 3 completes faster)
  - Black background, white text
- **Duration:** ~3-5 seconds (while Phase 3 review generation processes)
- **Navigation:** 
  - Success → Album Details Screen (full review display)
  - Failure → Album Details Screen with "Review temporarily unavailable" + retry button

### Album Details Screen
- **Purpose:** Display album information and cultural context
- **Key Elements:**
  - High-res album artwork from Cover Art Archive (minimum 500x500px when available, scales up to full width of screen)
  - If artwork unavailable: Display centered placeholder with text "Album art unavailable" on neutral gray background
  - Artwork should fill width of screen with appropriate aspect ratio (typically square for albums)
  - Artist name and album title (prominent) - from Phase 1B
  - Recommendation badge with emoji (ESSENTIAL/RECOMMENDED/SKIP/AVOID) - from Phase 3
  - Cultural context summary (2-3 sentences) - from Phase 3
  - Bullet points (3-5) with evidence - from Phase 3
  - Rating out of 10 - from Phase 3
  - Key Tracks section - from Phase 3
  - Release year, genre(s), record label - from Phase 1B
  - "X" button (top right)
  - History icon (top right, next to X)
- **Partial Failure States:**
  - If artwork fails (Phase 2): Show placeholder, display all text content from Phase 1B and Phase 3
  - If Phase 3 fails: Show artwork (from Phase 2) + basic metadata (from Phase 1B) + "Review temporarily unavailable" message with "Retry Review" button
  - "Retry Review" button re-runs only Phase 3 (not Phase 1A/1B or Phase 2)
- **Navigation:** 
  - X button → Returns to previous screen (Camera View or Scan History)
  - History icon → Scan History Screen
  - "Retry Review" button (if Phase 3 failed) → Re-runs Phase 3, updates display on success

### Scan History Screen
- **Purpose:** Chronological list of all scanned albums
- **Key Elements:**
  - Scrollable list (newest first)
  - Each entry: thumbnail, artist name, album title, scan date
  - Swipe-left-to-delete functionality
  - History icon (top right)
  - "SCAN" button (bottom)
  - Empty state: "Scan your first album to begin"
- **Navigation:** 
  - Tap album → Album Details Screen
  - SCAN button → Camera View
  - History icon → Returns to Camera View

### Scan Error Screen
- **Purpose:** Handle failed identification or artwork retrieval attempts (Phase 1A/1B/2 failures)
- **Key Elements:**
  - Error icon
  - Message: "Couldn't find a match"
  - Optional hint text: "Make sure the front of the album cover is clear and fills the frame"
  - "TRY AGAIN" button
- **Navigation:** 
  - TRY AGAIN → Camera View

### Welcome Screen (First-time only)
- **Purpose:** App introduction and branding
- **Key Elements:**
  - App name/logo
  - Tagline: "Discover music that matters"
  - "Get Started" button
- **Navigation:** 
  - Get Started → Camera Permission Request → Camera View

### Permission Error Screen (Edge case)
- **Purpose:** Handle camera permission denial
- **Key Elements:**
  - Error/warning icon
  - Message explaining camera access is required
  - "Open Settings" button (opens iOS Settings)
  - Brief explanation of why camera permission is needed
- **Navigation:** 
  - Open Settings → iOS Settings app
  - User returns after granting permission → Camera View

---

## FOUR-PHASE API ARCHITECTURE

### Overview
AlbumScan uses a sequential four-phase API strategy that optimizes for identification accuracy, speed, cost, and user experience.

**Key Benefits:**
1. **Accurate Identification:** Separate vision extraction from web search mapping handles edge cases (acronyms, minimal text, visual-only covers)
2. **Fail Fast:** Users know within 6 seconds if scan worked (Phases 1A/1B/2)
3. **Lower Cost on Failures:** Failed IDs cost ~$0.04-0.05 instead of $0.20-0.30
4. **User Confirmation:** 2-second hold shows matched album before expensive review generation
5. **Progressive Disclosure:** Users see results incrementally (feels faster)
6. **Better Error Handling:** Can show partial results if review fails
7. **Optimization Opportunities:** Can cache each phase independently
8. **Future-Proof:** Could add alternative review sources without re-identifying

---

### Phase 1A: Vision Extraction (1-2 seconds)

**Purpose:** Extract observable text and visual information from album cover (NO identification)

**API Call Details:**
- **Endpoint:** Anthropic Claude API (Vision)
- **Model:** Claude Sonnet 4.5
- **Input:** Album cover photo (JPEG, 1024x1024, 1-2MB)
- **Prompt:** See `phase1a_vision_extraction.txt`
- **Key Characteristics:**
  - Extract text exactly as it appears (including acronyms, band names, labels)
  - Describe visual elements (colors, imagery, artistic style)
  - NO interpretation or identification
  - NO web search (pure vision extraction)
  - Small, focused response
- **Expected Response Time:** 1-2 seconds
- **Cost:** ~$0.03 per call
- **Max Tokens:** 200 (small response)

**Response JSON:**
```json
{
  "extractedText": "TVOTR, Seeds",
  "albumDescription": "Bold red background with white geometric typography. Minimalist design with seed pod imagery in corners. Modern sans-serif font."
}
```

**On Success:**
- Pass extracted data to Phase 1B immediately
- No user-facing state change (Loading Screen 1 continues)

**On Failure:**
- Route to Scan Error Screen
- User taps "TRY AGAIN" → Camera View
- Total cost of failure: ~$0.03

---

### Phase 1B: Web Search Mapping (1-2 seconds)

**Purpose:** Use extracted text + visual description to identify album via web search

**API Call Details:**
- **Endpoint:** Anthropic Claude API (Text only, no vision)
- **Model:** Claude Sonnet 4.5
- **Input:** JSON from Phase 1A (extractedText + albumDescription)
- **Prompt:** See `phase1b_web_search_mapping.txt`
- **Key Characteristics:**
  - Web search ENABLED (critical for disambiguation)
  - Resolve acronyms to full names (TVOTR → TV on the Radio)
  - Match visual descriptions to known album artwork
  - Return clean, structured metadata
  - Binary outcome: success or error
- **Expected Response Time:** 1-2 seconds
- **Cost:** ~$0.01-0.02 per call (text + web search)
- **Max Tokens:** 300 (small response)

**Success Response JSON:**
```json
{
  "success": true,
  "artistName": "TV on the Radio",
  "albumTitle": "Seeds",
  "releaseYear": "2014",
  "genres": ["Indie Rock", "Art Rock"],
  "recordLabel": "Harvest Records"
}
```

**Error Response JSON:**
```json
{
  "success": false,
  "reason": "Could not find album matching the provided metadata"
}
```

**Phase 1B Error Scenarios:**
- Web search finds no matching albums
- Multiple ambiguous matches with no clear winner
- Extracted text too minimal or unclear to search effectively
- Claude has low confidence in match after web search

**On Success:**
- Pass clean metadata to Phase 2 (artwork retrieval)
- Loading Screen 1 continues (user sees no transition yet)

**On Failure:**
- Route to Scan Error Screen
- Total cost of Phase 1A + 1B failure: ~$0.04-0.05
- User taps "TRY AGAIN" → Camera View (restarts from Phase 1A)

---

### Phase 2: Album Artwork Retrieval (2-3 seconds)

**Purpose:** Fetch high-resolution album artwork using clean metadata from Phase 1B

**Sequence:**
1. **MusicBrainz Search** (0.5-1 second)
   - Trigger immediately after Phase 1B success
   - Query using artist + album from Phase 1B metadata
   - Retrieve MBID (MusicBrainz ID)
   - Endpoint: `https://musicbrainz.org/ws/2/release`
   - Query: `artist:{artistName} AND release:{albumTitle}`
   - User-Agent header REQUIRED: `AlbumScan/1.0 (james@jamesschaffer.com)`
   
2. **Cover Art Archive** (0.5-1 second)
   - Query using MBID from MusicBrainz
   - Download 500px image (large size)
   - Endpoint: `https://coverartarchive.org/release/{mbid}`
   
3. **Cache & Display** (0.5-1 second)
   - Generate 200px thumbnail for history
   - Cache both sizes locally (CoreData)
   - Display in Loading Screen 2 and Album Details Screen

**Total artwork retrieval time:** 2-3 seconds

**Cost:** $0 (free APIs)

**Artwork Failure Handling:**
- MusicBrainz returns no results → Use placeholder, continue to Loading Screen 2
- Cover Art Archive returns 404 → Use placeholder, continue to Loading Screen 2
- Network timeout → Use placeholder, continue to Loading Screen 2
- All artwork failures are non-blocking (album info still displays)

**On Success:**
- Transition to Loading Screen 2 (2-second confirmation hold)
- Display artwork + "We found {Album Title} by {Artist Name}"
- After 2 seconds → Transition to Loading Screen 3 (Phase 3 begins)

**On Failure:**
- Still transition to Loading Screen 2 with placeholder artwork
- Continue normal flow (Phase 3 runs after 2-second hold)

---

### Phase 3: Album Review Generation (3-5 seconds)

**Purpose:** Generate comprehensive cultural context and review using web research

**API Call Details:**
- **Endpoint:** Anthropic Claude API (Text only, no vision)
- **Model:** Claude Sonnet 4.5
- **Input:** Clean metadata from Phase 1B (text string: "Artist: {artistName}, Album: {albumTitle}, Year: {releaseYear}, Genre: {genres}, Label: {recordLabel}")
- **Prompt:** See `phase3_review_generation.txt`
- **Key Characteristics:**
  - Full review prompt with web search ENABLED
  - Research current album information (critical reception, chart performance, influence)
  - Generate ratings, recommendations, key tracks, bullets
  - NO image input (uses metadata only)
  - NO identification task (already complete)
- **Expected Response Time:** 3-5 seconds
- **Cost:** ~$0.05-0.10 per call
- **Max Tokens:** 1500 (larger response)

**Success Response JSON:**
```json
{
  "contextSummary": "OK Computer is Radiohead's landmark 1997 album that captured millennial anxiety through experimental rock. It transformed alternative music by proving ambitious art-rock could achieve both critical and commercial success. The album's influence on indie and electronic music remains profound nearly three decades later.",
  "contextBullets": [
    "Acclaimed as one of the greatest albums ever made, with a 9.1 from Pitchfork and consistent top-10 rankings in all-time lists.",
    "Hit #1 in the UK and went triple-platinum in the US, proving experimental rock could be commercially viable.",
    "Pioneered the use of electronic textures in rock, directly influencing bands like Muse, Coldplay, and The National.",
    "Features iconic tracks 'Paranoid Android,' 'Karma Police,' and 'No Surprises' that remain alternative radio staples.",
    "Won the 1998 Grammy for Best Alternative Music Album and was added to the Library of Congress's National Recording Registry in 2015."
  ],
  "rating": 9.5,
  "recommendation": "ESSENTIAL",
  "keyTracks": ["Paranoid Android", "Karma Police", "No Surprises", "Exit Music (For a Film)", "Let Down"]
}
```

**On Success:**
- Display full review in Album Details Screen
- Save complete album data to CoreData (metadata from Phase 1B + artwork from Phase 2 + review from Phase 3)
- Cache review for future scans of same album

**On Failure:**
- Still display Album Details Screen with:
  - Album artwork (already fetched in Phase 2)
  - Basic metadata (from Phase 1B: artist, album, year, genres, label)
  - Error message: "Review temporarily unavailable"
  - "Retry Review" button that re-triggers only Phase 3
- User can retry Phase 3 without re-scanning or paying for Phase 1A/1B/2 again

---

### Complete User Flow Timeline

```
User taps SCAN
↓
Loading Screen 1: "Flipping through every record bin in existence..."
[1-2s] Phase 1A: Vision Extraction (extract text + describe visuals)
[1-2s] Phase 1B: Web Search Mapping (identify album via web search)
[2-3s] Phase 2: Artwork Retrieval (MusicBrainz → Cover Art Archive)
↓
SUCCESS → All three phases complete (4-6 seconds total)
↓
Loading Screen 2: Shows artwork + "We found {Album Title} by {Artist Name}"
[2s] User confirmation hold (static, no loading)
↓
Loading Screen 3: "Writing a review that's somehow both pretentious and correct..."
[3-5s] Phase 3: Review Generation (web search + cultural analysis)
↓
Album Details Screen: Full review display
↓
Auto-saved to History
```

---

### State Management Requirements

**SwiftUI State Enum:**
```swift
enum ScanState {
    case idle                          // Camera view, ready to scan
    case phase1AInProgress             // Vision extraction running
    case phase1BInProgress             // Web search mapping running
    case phase2InProgress              // Artwork retrieval running
    case identificationComplete        // Phases 1A/1B/2 complete, showing Loading Screen 2 (2-sec hold)
    case phase3InProgress              // Review generation running
    case complete                      // All phases done, showing Album Details
    case identificationFailed          // Phase 1A/1B/2 failed
    case reviewFailed                  // Phases 1A/1B/2 worked, Phase 3 failed
}
```

**Album Data Structure:**
```swift
struct AlbumScanData {
    // Phase 1A data (vision extraction)
    var extractedText: String?
    var albumDescription: String?
    var phase1ACompleted: Bool = false
    
    // Phase 1B data (identification metadata)
    var artistName: String?
    var albumTitle: String?
    var releaseYear: String?
    var genres: [String]?
    var recordLabel: String?
    var phase1BCompleted: Bool = false
    
    // Phase 2 data (artwork)
    var albumArtwork: UIImage?
    var artworkLoaded: Bool = false
    var musicbrainzID: String?
    var phase2Completed: Bool = false
    
    // Phase 3 data (review)
    var contextSummary: String?
    var contextBullets: [String]?
    var rating: Double?
    var recommendation: String?
    var keyTracks: [String]?
    var phase3Completed: Bool = false
    
    // Error tracking
    var phase1Error: String?
    var phase2Error: String?
}
```

---

### Error Handling in Four-Phase System

**Scenario 1: Phase 1A/1B/2 Fails (Identification or Artwork)**
- User Experience: Scan Error Screen - "Couldn't find a match"
- User Action: Tap "TRY AGAIN" → Camera View
- Cost Impact: ~$0.04-0.05 (no Phase 3 call)
- System Behavior: Phase 3 never triggered

**Scenario 2: Phase 1A/1B/2 Succeeds, Phase 3 Fails**
- User Experience: Album Details Screen with:
  - Album artwork (from Phase 2, or placeholder if Phase 2 failed)
  - Basic metadata (artist, title, year, genre, label from Phase 1B)
  - Error in review area: "Review temporarily unavailable"
  - "Retry Review" button (only re-runs Phase 3)
- Cost Impact: Phase 1A/1B (~$0.04-0.05) initially, Phase 3 cost (~$0.05-0.10) on retry
- System Behavior: Partial success is better than total failure

**Scenario 3: Phase 2 Artwork Fails, Everything Else Succeeds**
- User Experience: Album Details Screen with:
  - Placeholder artwork
  - Full review from Phase 3
  - All metadata visible
- Non-blocking error: Review displays normally
- Cost Impact: Full cost (~$0.09-0.15)

**Scenario 4: Network Failure Mid-Process**
- If Phase 1A/1B/2 in progress: Show error, retry from beginning (Scan Error Screen)
- If Phase 3 in progress: Show partial results (artwork + metadata) with "Retry Review" button
- Network recovery: User can retry without re-scanning

---

### Caching Strategy for Four-Phase System

**Phase 1A/1B Cache (Identification):**
- **Decision:** Do NOT cache Phase 1A/1B results by image
- **Reasoning:** 
  - Image hashing is expensive
  - Phase 1A/1B is fast (2-4s total) and cheap ($0.04-0.05)
  - User rarely scans exact same photo twice
  - Not worth the complexity

**Phase 3 Cache (Review):**
- **Cache Key:** `"{artistName}_{albumTitle}".lowercased().replacingOccurrences(of: " ", with: "_")`
- **Cache Location:** CoreData (part of Album entity)
- **Cache Duration:** Never expires (reviews don't change)
- **Cache Check:** Before Phase 2 API call:
  - Query CoreData for existing album with matching artist + title
  - If exists → Skip Phase 2 API call, display cached review immediately
  - If not exists → Make Phase 2 API call, cache result in CoreData
- **Cache Savings:** Huge cost reduction for duplicate album scans

**Artwork Cache:**
- **Cache Key:** MBID (MusicBrainz ID) or `"{artist}_{album}"` fallback
- **Cache Location:** CoreData as Data blobs (both 500px and 200px versions)
- **Cache Duration:** Never expires (artwork doesn't change)
- **Cache Check:** Before MusicBrainz call:
  - If album exists in CoreData with artwork → Use cached artwork, skip API calls
  - If not exists → Fetch from MusicBrainz + Cover Art Archive, cache in CoreData

**Memory Cache (NSCache):**
- Hold 20-30 most recently viewed artworks in memory
- Speeds up history scrolling
- Auto-clears on memory pressure

---

### API Implementation Notes

**Phase 1 API Call (Swift):**
```swift
let phase1Response = await claudeAPI.identifyAlbum(
    image: capturedPhoto,
    prompt: phase1IdentificationPrompt,
    enableWebSearch: false,  // CRITICAL: disable for speed
    maxTokens: 300,
    temperature: 0.0  // Deterministic for identification
)
```

**Phase 2 API Call (Swift):**
```swift
// Check cache first
if let cachedAlbum = await coreDataManager.fetchAlbum(
    artist: artistName, 
    title: albumTitle
) {
    // Use cached review, skip API call
    return cachedAlbum
}

// No cache, make API call
let phase2Response = await claudeAPI.generateReview(
    metadata: "Artist: \(artist), Album: \(album), Year: \(year), Genre: \(genres.joined(separator: ", ")), Label: \(label)",
    prompt: phase2ReviewPrompt,
    enableWebSearch: true,  // Enable research
    maxTokens: 1500,
    temperature: 0.3  // Slightly creative for review
)
```

**Parallel Execution Pattern:**
```swift
async let artworkTask = fetchArtwork(artist: artistName, album: albumTitle)
async let reviewTask = generateReview(artist: artistName, album: albumTitle)

let (artwork, review) = await (artworkTask, reviewTask)
```

---

## TECHNICAL STACK

### Platform & Language
- **Platform:** iOS (native)
- **Minimum iOS Version:** iOS 16.0+
- **Target Devices:** iPhone only (MVP)
- **Development Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **IDE:** Xcode 15+
- **Version Control:** Git (GitHub recommended)

### Why SwiftUI?
- Declarative syntax ideal for rapid iteration
- Better for learning iOS development in 2025
- Cleaner code for hobby project
- Future-proof as Apple's recommended approach
- Easier to prototype UI changes quickly

### Networking & Image Handling
- **HTTP Client:** URLSession (native iOS)
- **Image Caching:** 
  - NSCache for in-memory caching (20-30 recent images)
  - CoreData for persistent disk cache (unlimited, never expires)
- **Image Loading:** SwiftUI AsyncImage with custom caching layer
- **Async/Await:** Modern Swift concurrency for sequential four-phase API calls
- **Image Formats:** JPEG (primary), PNG (fallback)

### Data Persistence
- **Framework:** CoreData
- **Storage:** Local device only (no cloud sync in MVP)
- **Entities:** Album (see Data Model section)

---

## API INTEGRATION DETAILS

### Anthropic Claude API

**General Information:**
- **Documentation:** https://docs.anthropic.com/
- **Model:** Claude Sonnet 4.5 (`claude-sonnet-4-5-20250929`)
- **Authentication:** API key (store in Xcode build configuration, never hardcode)
- **Rate Limits:** Monitor usage, implement retry logic with exponential backoff
- **Error Handling:** Timeout after 10 seconds, retry once on transient failures

**Phase 1: Album Identification**
- **Capabilities:** Vision API (image analysis) + Text generation
- **Input:** JPEG image (1024x1024, 1-2MB)
- **Prompt File:** `phase1_album_identification_prompt.txt`
- **Web Search:** Disabled (speed critical)
- **Max Tokens:** 300
- **Temperature:** 0.0 (deterministic)
- **Expected Response Time:** 2-4 seconds
- **Cost:** ~$0.03-0.05 per call

**Phase 2: Review Generation**
- **Capabilities:** Text generation + Web search (enabled)
- **Input:** Text metadata string from Phase 1
- **Prompt File:** `phase2_review_generation_prompt.txt`
- **Web Search:** Enabled (research current information)
- **Max Tokens:** 1500
- **Temperature:** 0.3 (slightly creative for reviews)
- **Expected Response Time:** 3-6 seconds
- **Cost:** ~$0.15-0.25 per call

---

### MusicBrainz API

**General Information:**
- **Purpose:** Search for album releases and retrieve MusicBrainz IDs (MBIDs)
- **Documentation:** https://musicbrainz.org/doc/MusicBrainz_API
- **Endpoint:** `https://musicbrainz.org/ws/2/release`
- **Authentication:** None required (open API)
- **Rate Limiting:** 1 request per second (implement delay if needed)
- **User-Agent Required:** Must include custom User-Agent header
  - Format: `AlbumScan/1.0 (james@jamesschaffer.com)`
  - Requests without User-Agent may be blocked

**Query Parameters:**
- `query`: Lucene-style search query combining artist and album
- `fmt`: Response format (use `json`)
- `limit`: Number of results (use `5` to handle multiple variants)

**Search Strategy:**
- Primary search: `artist:{artist_name} AND release:{album_title}`
- If no results: Try fuzzy search with `artist:{artist_name} release:{album_title}~`
- Select first result with matching artist name (case-insensitive)

**Response Contains:**
- Release MBID (primary goal)
- Release title
- Artist credit
- Date
- Country

**Caching:** Cache MBIDs with album metadata in CoreData to avoid repeat searches

**Example Request:**
```
GET https://musicbrainz.org/ws/2/release?query=artist:Radiohead%20AND%20release:OK%20Computer&fmt=json&limit=5
User-Agent: AlbumScan/1.0 (james@jamesschaffer.com)
```

**Expected Response Time:** 0.5-1 second

---

### Cover Art Archive API

**General Information:**
- **Purpose:** Retrieve high-resolution album artwork using MusicBrainz release ID
- **Documentation:** https://coverartarchive.org/
- **Endpoint:** `https://coverartarchive.org/release/{mbid}`
- **Authentication:** None required (open API)
- **Rate Limiting:** No strict limits, but respect reasonable use

**Image Selection Priority:**
1. `front` image (primary album cover)
2. First available image if no front designation
3. Prefer larger images (check `thumbnails` object for sizes)

**Response Structure:**
- Array of images with URLs, types, and thumbnail variants
- Each image has:
  - `types`: ["Front", "Back", etc.]
  - `front`: boolean
  - `image`: Full resolution URL
  - `thumbnails`: Object with `small` (250px) and `large` (500px) URLs

**Image Sizes Available:**
- `small`: 250px
- `large`: 500px  
- `original`: Full resolution (often 1000-1500px)

**Download Strategy:** 
- Download `large` (500px) for detail view
- Generate thumbnail (200x200) from large image for history list
- Store both in CoreData as Data blobs

**404 Handling:** 
- Common for obscure releases
- Gracefully fall back to placeholder: "Album art unavailable"
- Non-blocking error (album info still displays)

**Example Request:**
```
GET https://coverartarchive.org/release/67a63246-0de4-4cd8-8ce2-35f0e17f652b
```

**Example Response Structure:**
```json
{
  "images": [
    {
      "types": ["Front"],
      "front": true,
      "image": "https://coverartarchive.org/release/.../front.jpg",
      "thumbnails": {
        "small": "https://...-250.jpg",
        "large": "https://...-500.jpg"
      }
    }
  ]
}
```

**Expected Response Time:** 0.5-1 second (query) + 0.5-1 second (download)

---

### Recommendation Emojis (Hardcoded in App)

**Mapping (stored in Swift enum):**
- **ESSENTIAL:** 💎 (diamond)
- **RECOMMENDED:** 👍 (thumbs up)  
- **SKIP:** 😐 (face with diagonal mouth)
- **AVOID:** 💩 (poop emoji)

---

## DATA MODEL

### CoreData Schema

#### Album Entity

```swift
Album {
  // Primary Key
  id: UUID (primary key)
  
  // Phase 1A Data (Vision Extraction) - Not stored, only used for Phase 1B
  // extractedText and albumDescription are temporary, not persisted
  
  // Phase 1B Data (Identification Metadata)
  artistName: String
  albumTitle: String
  releaseYear: String?
  genres: [String]  // Array stored as JSON or comma-separated
  recordLabel: String?
  phase1BCompleted: Bool  // Track if identification succeeded
  
  // Phase 2 Data (Artwork)
  musicbrainzID: String?  // MBID for future reference
  albumArtURL: String?  // Cover Art Archive URL (large/500px)
  albumArtThumbnailData: Data?  // Cached 200x200 JPEG for history
  albumArtHighResData: Data?  // Cached 500px JPEG for detail view
  albumArtRetrievalFailed: Bool  // Track if artwork lookup failed
  phase2Completed: Bool  // Track if artwork fetch completed
  
  // Phase 3 Data (Review)
  contextSummary: String?  // 2-3 sentence opening
  contextBulletPoints: [String]  // 3-5 bullets, stored as JSON or comma-separated
  rating: Double?  // 0-10
  recommendation: String?  // ESSENTIAL/RECOMMENDED/SKIP/AVOID
  keyTracks: [String]  // Stored as JSON or comma-separated
  phase3Completed: Bool  // Track if Phase 3 succeeded
  phase3Failed: Bool  // Track if Phase 3 needs retry
  phase3LastAttempt: Date?  // When we last tried Phase 3 (for retry logic)
  
  // Metadata
  scannedDate: Date  // When user first scanned this
  lastViewedDate: Date?  // Last time user opened this album in history
  
  // Raw API Responses (Optional, for debugging)
  rawPhase1AResponse: String?  // Vision extraction JSON
  rawPhase1BResponse: String?  // Identification JSON
  rawPhase3Response: String?  // Review JSON
}
```

### Storage Strategy

**Auto-save Policy:**
- Phase 1B success: Immediately save to CoreData with basic metadata (artist, album, year, genres, label)
- Phase 2 (artwork fetch): Update existing record with artwork data
- Phase 3 success: Update existing record with review data
- This allows partial saves (can show basic info even if Phase 3 fails)

**Duplicates:**
- Duplicates ARE allowed - every scan creates new entry
- Same album scanned multiple times = multiple CoreData entries
- Users manage duplicates manually via swipe-to-delete in history

**Caching:**
- Review content cached indefinitely (reviews don't change)
- Before Phase 3 call, check CoreData for existing album with matching artist + title
- If exists: Skip Phase 3 API call, use cached review, show Album Details immediately after Loading Screen 2
- If not exists: Make Phase 3 API call, cache result

**Offline Access:**
- All scanned albums viewable without internet
- Artwork stored as Data blobs (both thumbnail and high-res)
- All text content stored locally

**Storage Limits:**
- No app-enforced limit on number of albums
- iPhone storage is the only constraint
- Typical album: ~500KB (artwork) + ~5KB (text) = ~505KB
- 1000 albums ≈ 500MB

---

## CAMERA IMPLEMENTATION

### AVFoundation Framework

**Camera Access:**
- **Framework:** AVCaptureSession for live camera feed
- **Permissions:** Request camera access on first launch (standard iOS flow)
- **Permission Denial:** Show Permission Error Screen with "Open Settings" button

**Camera Settings:**
- **Live Feed:** Camera activates immediately when Screen 1 loads (optimize for speed)
- **Orientation:** Locked to portrait mode only (no landscape support in MVP)
- **Lens:** 1x default zoom (no digital zoom or wide-angle)
- **Performance:** Prioritize speed over quality (minimize processing delays)

**Photo Capture:**
- **Trigger:** SCAN button tap (direct capture, no review/retake in MVP)
- **Format:** JPEG
- **Resolution:** 1024x1024 (square, optimized for album covers and API)
- **Compression:** 1-2MB file size (balance between upload speed and detail)
- **Quality Setting:** Balanced (fast upload, sufficient detail for identification)

**Square Framing Guide:**
- **Overlay:** Square guide centered on screen
- **Outside Guide:** Black overlay with 80% opacity
- **Guide Size:** As large as possible with ~20px margin on left/right
- **Guide Position:** Perfectly centered vertically (measured from top and bottom)
- **Purpose:** Help users center album cover in frame

**Cropping:**
- **When:** After capture, before sending to API
- **What:** Crop to square guide area only
- **Why:** Remove background records/clutter, focus API on target album
- **Implementation:** Extract pixels within guide boundaries, discard rest

### Image Pipeline

```
User taps SCAN 
  → AVCaptureSession captures photo
  → Crop to square guide area (1024x1024)
  → Compress to JPEG (1-2MB)
  → Send to Claude API Phase 1
```

**No Photo Library Access:**
- Direct camera only (no picking from library in MVP)
- Simpler permissions and UX
- Optimized for in-store browsing use case

---

## UI/UX REQUIREMENTS

### Design System

**iOS Native Patterns:**
- Follow Apple Human Interface Guidelines
- Use native SwiftUI components where possible
- Standard iOS navigation patterns (X button, swipe gestures)

**SF Symbols:**
- Use Apple's icon library for all icons
- Clock icon for history
- X icon for close/dismiss
- Camera icon if needed

**Dark Mode:**
- Support system dark mode
- SwiftUI handles automatically with proper color definitions
- Test both light and dark modes
- Primary screens (loading, camera) use black background

**Dynamic Type:**
- Support accessibility text sizing
- Text scales with system settings
- Ensure readability at all sizes

**Haptic Feedback:**
- Subtle haptics on button taps (SCAN, TRY AGAIN, etc.)
- Haptic on successful scan (light impact)
- Haptic on error (notification feedback)

### Performance Targets

**App Launch:**
- < 2 seconds from icon tap to Camera View ready
- Camera feed activates immediately (no black screen)

**Phase 1 Response:**
- 2-4 seconds target
- Display results within 5 seconds max (including network)

**Phase 2 Response:**
- 3-6 seconds target
- Display review within 8 seconds of Phase 1 completion

**Screen Transitions:**
- 60fps smooth animations
- No janky transitions between screens
- Loading states feel responsive

**History Scrolling:**
- Smooth scrolling even with 100+ albums
- Use thumbnail images (200x200) for performance
- Lazy loading for large lists

**Offline Access:**
- History loads instantly from CoreData cache
- No loading spinner for cached albums

### Accessibility

**VoiceOver:**
- All interactive elements properly labeled
- Descriptive labels for images
- Logical navigation order

**Dynamic Type:**
- Text scales with system settings (see above)
- Minimum 17pt body text
- Test at largest accessibility sizes

**Color Contrast:**
- Sufficient contrast ratios (WCAG AA minimum)
- White text on black background (primary screens)
- Test in both light and dark modes

**Tap Targets:**
- Minimum 44x44pt for all interactive elements
- Large SCAN button (easy to tap while holding phone)
- Generous spacing between tappable elements

---

## ERROR HANDLING

### Critical Error Scenarios

**1. No Internet Connection**
- **Detection:** Before Phase 1 API call if possible
- **User Experience:** Alert: "No internet connection. Please check your connection and try again."
- **Action:** "OK" button dismisses alert, returns to Camera View
- **Phase 1 Behavior:** Don't attempt API call if no connection
- **Phase 2 Behavior:** If Phase 1 succeeded offline (cached), allow Phase 2 to fail gracefully

**2. Phase 1 API Failure (Identification)**
- **Causes:**
  - Network timeout (10 seconds)
  - Invalid response from Claude API
  - Rate limit hit
  - Server error (5xx)
  - Album genuinely not identifiable
- **User Experience:** Screen 5 (Scan Error)
- **Message:** "Couldn't find a match"
- **Hint Text:** "Make sure the front of the album cover is clear and fills the frame"
- **Action:** "TRY AGAIN" button → Camera View
- **Cost:** ~$0.03-0.05 (no Phase 2 call)

**3. Phase 2 API Failure (Review Generation)**
- **Causes:**
  - Network timeout
  - Invalid response
  - Web search failures
  - Server error
- **User Experience:** Album Details (Screen 3) with:
  - Real artwork (if available)
  - Basic metadata from Phase 1
  - Error message: "Review temporarily unavailable"
  - "Retry Review" button
- **Action:** "Retry Review" → Re-runs only Phase 2 (not Phase 1 or artwork)
- **Behavior:** Partial success - user still knows what album it is

**4. Camera Issues**
- **Permission Denied:**
  - Show Permission Error Screen
  - "Open Settings" button → iOS Settings app
  - User grants permission → Return to app → Camera View
- **Hardware Failure:**
  - Alert: "Camera unavailable. Please restart the app."
  - "OK" button dismisses alert
  - Graceful degradation (don't crash)
- **Poor Lighting:**
  - No client-side detection (let Claude handle in Phase 1)
  - May affect identification quality (acceptable for MVP)
  - User will retry naturally if scan fails

**5. Storage Issues**
- **Disk Full:**
  - CoreData save fails → Alert: "Unable to save album. Storage may be full."
  - Graceful handling (scan still completes, just not saved)
  - Unlikely with album metadata (small data size)
- **CoreData Failure:**
  - Alert: "An error occurred. Please try again."
  - Offer retry button
  - Log error for debugging

**6. Album Not Identified (Phase 1 Returns Error)**
- **User Experience:** Screen 5 (Scan Error) - "Couldn't find a match"
- **Action:** "TRY AGAIN" button → Camera View
- **Common Causes:**
  - Not an album cover (random object)
  - Back cover of album
  - Too blurry/partial/far away
  - Multiple albums in frame
  - Bootleg/unofficial release

**7. Album Artwork Retrieval Failures**
- **MusicBrainz Search Returns No Results:**
  - Use placeholder: "Album art unavailable"
  - Continue displaying album details
  - Non-blocking error
- **Cover Art Archive Returns 404:**
  - Use placeholder (common for obscure releases)
  - Continue displaying album details
- **Network Timeout During Artwork Download:**
  - Use placeholder after 5 second timeout
  - Don't block Phase 2 review display
- **Image Download Fails or Corrupted:**
  - Use placeholder
  - Continue displaying album details
- **Important:** All artwork failures are non-blocking - album information always displays

### Networking

**Framework:** URLSession (native iOS)

**Timeout Settings:**
- Phase 1 (Claude): 10 seconds
- Phase 2 (Claude): 15 seconds (allows for web search)
- MusicBrainz: 5 seconds
- Cover Art Archive: 5 seconds (query) + 5 seconds (download) = 10 seconds total

**Retry Logic:**
- **Phase 1:** Single auto-retry on transient failures (network glitch), then show error
- **Phase 2:** User-initiated retry via "Retry Review" button (no auto-retry)
- **Artwork:** Single auto-retry, then use placeholder
- **Exponential Backoff:** For rate limit errors (unlikely with Claude)

**HTTPS Only:**
- All API calls over secure connection (HTTPS)
- No insecure HTTP requests

**Error Response Handling:**
- Parse JSON errors from Claude API
- Handle 4xx (client errors) vs 5xx (server errors) differently
- Log errors for debugging (but don't expose to user)

---

## TESTING STRATEGY

### Unit Tests

**CoreData Operations:**
- Save album to CoreData (Phase 1 data only)
- Update album with Phase 2 data
- Update album with artwork data
- Fetch album by artist + title (cache check)
- Delete album from history
- Query all albums (sorted by date)

**API Response Parsing:**
- Parse Phase 1 success JSON
- Parse Phase 1 error JSON
- Parse Phase 2 success JSON
- Handle malformed JSON gracefully
- Parse MusicBrainz response
- Parse Cover Art Archive response

**Data Model Validation:**
- Album entity saves correctly
- Arrays (genres, bullets, tracks) serialize/deserialize
- Data blobs (artwork) save and load correctly
- Date fields save correctly

**Caching Logic:**
- Check cache before Phase 2 call
- Cache review after Phase 2 success
- Cache artwork after download
- Cache lookup by artist + title

---

### Integration Tests

**Complete Flow Tests:**
- Camera capture → Phase 1 → Phase 2 → Save to CoreData
- Camera capture → Phase 1 success → Phase 2 fail → Partial save
- Camera capture → Phase 1 fail → Error screen
- Phase 1 → Artwork fetch (parallel) → Phase 2 → Display
- Retry Review button → Phase 2 only (no re-identification)

**Navigation Flow Tests:**
- Camera View → History → Album Details → Back to History
- Camera View → Scan → Album Details → X → Camera View
- Album Details → Retry Review → Updated review display

**Error Handling Path Tests:**
- No internet → Error message → Retry
- Phase 1 timeout → Error screen
- Phase 2 timeout → Partial display with retry
- Artwork 404 → Placeholder display
- Permission denied → Settings screen

**API Integration Tests:**
- Phase 1A with real Claude API (using test images)
- Phase 1B with real Claude API (using Phase 1A output)
- Phase 2 with real MusicBrainz + Cover Art Archive (using Phase 1B metadata)
- Phase 3 with real Claude API (using Phase 1B metadata)
- MusicBrainz search → Parse MBID
- Cover Art Archive query → Download image
- Full four-phase sequential flow with real APIs

**Sequential Execution Tests:**
- Phase 1A → 1B → 2 complete sequentially during Loading Screen 1
- Loading Screen 2 displays for exactly 2 seconds
- Phase 3 runs during Loading Screen 3
- Phase 1A/1B/2 fails → Scan Error Screen
- Phase 3 fails → Album Details with retry
- Both fail, show partial results

---

### Manual Testing

**Critical Real-World Testing:**
- **Test at actual record stores** with real albums (most important)
- Test various lighting conditions (bright, dim, overhead lights)
- Test obscure vs popular albums
- Test worn/damaged covers
- Test angled shots (not perfectly straight)
- Test partially visible covers

**Device Testing:**
- Test on multiple iPhone models if possible (different screen sizes)
- Test on oldest supported iOS version (iOS 16.0)
- Test on latest iOS version
- Test both light and dark modes

**Edge Case Testing:**
- Back cover of album (should error)
- Multiple albums in frame (should error)
- Non-album objects (should error)
- Bootleg/unofficial releases (may error)
- Albums with multiple releases (should pick one)

**Artwork Testing:**
- Popular albums (high success rate)
- Obscure albums (expect some failures)
- Non-English titles and artist names
- Albums known to be missing from Cover Art Archive
- Artwork quality on various iPhone screen sizes
- Artwork loading on slow network

**Error Scenario Testing:**
- Airplane mode (no internet)
- Permission denied (camera access)
- Timeout scenarios (slow network)
- Server errors (mock 5xx responses)
- Rate limiting (unlikely but test if possible)

**Performance Testing:**
- Scroll history with 100+ albums (smooth?)
- App launch time (< 2 seconds?)
- Phase 1 response time (< 4 seconds average?)
- Phase 2 response time (< 6 seconds average?)
- Memory usage (no leaks?)

---

### Test Data

**Known Albums for Testing (Diverse Set):**

**Acclaimed Albums (Should rate high):**
- Radiohead - OK Computer (1997)
- Kanye West - My Beautiful Dark Twisted Fantasy (2010)
- The Beatles - Abbey Road (1969)

**Mixed/Controversial Albums:**
- Kanye West - Yeezus (2013) - Divisive reception
- The Beatles - Let It Be (1970) - Mixed critical consensus

**Poorly Received Albums (Should rate low):**
- Madonna - MDNA (2012)
- Earth Wind & Fire - Electric Universe (1983)

**Obscure Albums:**
- Test with local/regional releases
- Test with non-US releases
- Test with albums missing from Cover Art Archive

**Edge Cases:**
- Bootleg releases
- Picture discs
- Colored vinyl (different artwork variants)
- Reissues with different artwork
- Box sets
- Singles vs albums

---

## SECURITY & PRIVACY

### API Key Management

**NEVER hardcode API keys in source code.**

**Storage Options:**
- **Xcode Build Configuration:** Store in xcconfig file (add to .gitignore)
- **Environment Variables:** Use Xcode build settings
- **Keychain:** For production apps (overkill for MVP)

**Git:**
- Add API keys to .gitignore
- Add xcconfig files to .gitignore
- Never commit sensitive credentials

**Best Practice:**
```swift
// Read from build configuration
let apiKey = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String
```

### Data Privacy

**No Analytics:**
- No tracking or analytics in MVP
- No user behavior logging
- No telemetry

**No External Data Sharing:**
- Album scan data stays on device
- No cloud sync (CoreData local only)
- No third-party SDKs

**Camera Access:**
- Only used when explicitly triggered by user (SCAN button)
- Not running in background
- Not accessing photo library

**API Data Transmission:**
- Album cover photo sent to Anthropic Claude API (Phase 1)
- Album metadata sent to Anthropic Claude API (Phase 2)
- Album metadata sent to MusicBrainz (for artwork)
- No personal user data transmitted
- All API calls over HTTPS

**Privacy Policy (Required for App Store):**
Before App Store submission, create privacy policy explaining:
- Camera usage (to capture album covers)
- API data transmission (image sent to Anthropic for identification)
- Local storage only (no cloud sync)
- No data sharing with third parties
- No user tracking or analytics

---

## COST ESTIMATES

### Monthly Costs (Hobby Use)

**API Costs:**
- **Anthropic Claude API:**
  - Successful scans: ~$0.18-0.30 per scan
  - Failed scans: ~$0.03-0.05 per scan
  - Estimated usage: 50-100 scans/month
  - Estimated cost: $10-30/month (depending on success rate)
  
**Infrastructure:**
- **Apple Developer Program:** $99/year (~$8/month)
- **MusicBrainz:** Free (open API)
- **Cover Art Archive:** Free (open API)

**Total Monthly Cost:** ~$18-38/month

### Cost Mitigation Strategies

**Caching:**
- Aggressive Phase 2 caching (never re-generate reviews for same album)
- Artwork caching (never re-fetch artwork for same album)
- Expected savings: 50-70% for users who scan duplicates

**Fail Fast:**
- Phase 1 costs 85% less than full review
- Failed scans only cost ~$0.03-0.05 instead of $0.20-0.30
- Expected savings: ~$5-10/month on failed scans

**Spending Alerts:**
- Set spending alerts with Anthropic ($50/month threshold)
- Monitor usage weekly via Anthropic dashboard
- Pause app if usage exceeds budget

**Future Optimizations:**
- Could add local ML model for pre-filtering obvious non-albums (Phase 0)
- Could cache Phase 1 results by image hash (expensive, low ROI)
- Could implement daily/weekly scan limits for personal use

---

## OUT OF SCOPE (MVP)

**Explicitly NOT in v1.1:**

❌ **Spotify playback integration** (deferred to v2.0)
❌ **Manual search functionality** (camera only)
❌ **Cloud sync / iCloud** (local storage only)
❌ **iPad support** (iPhone only)
❌ **Social sharing features** (no sharing, no social)
❌ **Export functionality** (no CSV, no backup)
❌ **Multiple language support** (English only)
❌ **Comprehensive crash reporting** (basic logging only)
❌ **User accounts / authentication** (no login)
❌ **Recommendation algorithm** (no "albums like this")
❌ **Genre filtering / search in history** (simple scroll only)
❌ **Album editing** (no manual corrections)
❌ **Batch scanning** (one album at a time)
❌ **AR features** (no augmented reality)
❌ **Barcode scanning** (album cover only)
❌ **Integration with other apps** (standalone app)

---

## IMPLEMENTATION NOTES

### Artwork Retrieval Priority

**Speed is Critical:**
- Users should see album confirmation within 4-6 seconds (Loading Screen 1)
- Phase 1A: 1-2 seconds (vision extraction)
- Phase 1B: 1-2 seconds (web search mapping)
- Phase 2: 2-3 seconds (artwork retrieval)
- Loading Screen 2: 2 seconds (confirmation hold)
- Phase 3: 3-5 seconds (review generation)
- Total: 9-13 seconds

**Sequential Execution:**
- Phase 1A → Phase 1B → Phase 2 run sequentially during Loading Screen 1
- After all three complete, transition to Loading Screen 2 (2-second hold)
- Phase 3 runs during Loading Screen 3 (after confirmation)
- User sees matched album + artwork before review generation begins

**Non-Blocking:**
- Never block album information display waiting for artwork
- If Phase 2 artwork fails, show placeholder in Loading Screen 2
- If Phase 3 fails, show Album Details with artwork + basic metadata immediately

**Aggressive Timeout:**
- 5 seconds max for Phase 2 artwork retrieval process
- MusicBrainz: 3 seconds
- Cover Art Archive: 3 seconds (query + download)
- After timeout, use placeholder and continue to Loading Screen 2

---

### Caching Strategy

**Memory Cache (NSCache):**
- Hold 20-30 most recently viewed artworks in memory
- Speeds up history scrolling
- Auto-clears on memory pressure
- No manual cache management needed

**Disk Cache (CoreData):**
- Store all downloaded artwork permanently as Data blobs
- Two versions per album:
  - High-res (500px) for detail view
  - Thumbnail (200x200) for history list
- Never expires (artwork doesn't change)

**Cache Key:**
- Prefer MBID (MusicBrainz ID) if available
- Fallback: `"{artist}_{album_title}".lowercased()` hash

**Cache Lookup:**
- Before MusicBrainz call, check CoreData for existing album
- If artwork exists: Use cached, skip all artwork API calls
- If not: Fetch from MusicBrainz + Cover Art Archive, cache in CoreData

**Review Cache:**
- Phase 3 reviews cached indefinitely (reviews don't change)
- Before Phase 3 call, check CoreData for existing album
- If review exists: Skip Phase 3 API call, use cached review, show Album Details immediately after Loading Screen 2
- If not: Make Phase 3 API call, cache result in CoreData

---

### User-Agent Header (REQUIRED for MusicBrainz)

MusicBrainz requires a proper User-Agent or requests may be blocked:

```
User-Agent: AlbumScan/1.0 (james@jamesschaffer.com)
```

Include this header in ALL MusicBrainz API requests.

---

### Rate Limiting Compliance

**MusicBrainz:**
- Maximum 1 request per second
- Implement 1-second delay between searches if needed (unlikely in single-user app)
- For multiple simultaneous scans: Queue requests with delay

**Cover Art Archive:**
- No strict limits
- Don't hammer the API (be respectful)
- Single-user app unlikely to hit limits

**Exponential Backoff for Retries:**
- First retry: Immediate
- Second retry: 2 seconds delay
- Third retry: 4 seconds delay
- Give up after 3 retries

---

### Placeholder Artwork Design

**Visual Specifications:**
- **Background Color:**
  - Light mode: #E5E5E5 (neutral gray)
  - Dark mode: #2C2C2C (dark gray)
- **Text:** "Album art unavailable" (centered)
- **Font:** System font, 17pt, medium weight
- **Aspect Ratio:** 1:1 square (matches album covers)
- **Optional Icon:** Music note or vinyl record symbol (subtle, 40pt)

**Implementation:**
- Create placeholder image programmatically (SwiftUI)
- Reuse same placeholder for all failures (don't generate per album)
- Ensure accessibility (VoiceOver describes as "Album art unavailable")

---

### Prompt Management

**Prompt Files:**
- Phase 1A: `phase1a_vision_extraction.txt`
- Phase 1B: `phase1b_web_search_mapping.txt`
- Phase 3: `phase3_review_generation.txt`

**Note:** No Phase 2 prompt file (Phase 2 is MusicBrainz + Cover Art Archive API calls only)

**Prompt Loading:**
- Store prompts in app bundle (as text files)
- Load at app launch and cache in memory
- Allows prompt updates without code changes

**Version Control:**
- Store prompts in Git repository
- Track changes to prompts separately from code
- Easy to test prompt variations

**Benefits:**
- Independent iteration on prompt quality
- No need to recompile app to test new prompts
- Clear separation of concerns (product vs engineering)
- Each phase's prompt can be optimized independently

---

### Key Navigation Rules

**History Icon Visibility:**
- Hidden on Camera View until first successful scan
- After first scan: Always visible on Camera View, Album Details, History

**Auto-save Behavior:**
- All successful scans (Phase 1 complete) automatically save to history
- Duplicates allowed - every scan creates new entry
- Users manage duplicates manually via swipe-to-delete

**Back Navigation:**
- Single "X" button returns to previous screen
- From Album Details: Returns to Camera View OR History (depending on where user came from)
- From History: Returns to Camera View via History icon

**Error Navigation:**
- Single "TRY AGAIN" action for all Phase 1A/1B/2 errors (returns to Camera View)
- "Retry Review" button for Phase 3 errors (only retries Phase 3, not identification or artwork)

**Default Home Screen:**
- Camera View is the default home screen (not History)
- App launches directly to Camera View (after first-time onboarding)

---

### Design Philosophy

**Speed over Perfection:**
- Get users scanning quickly
- Optimize for fast feedback (Phase 1 in 2-4 seconds)
- Progressive disclosure (show results as they load)

**Simple over Complex:**
- MVP is intentionally minimal
- Two-tier API adds complexity for good reason (speed, cost)
- But UI remains simple (no complex state machines exposed to user)

**Offline-First:**
- History works without internet
- Cached albums load instantly
- Graceful degradation when offline

**Music-Focused:**
- NEVER mention prices or collectibility
- Focus on artistic merit and cultural significance
- Honest reviews (call out bad albums)
- Evidence-based analysis (not just opinions)

---

**Document Version:** 1.2 (Four-Phase API Architecture)
**Last Updated:** October 25, 2025  
**Status:** Ready for four-phase refactoring  
**Next Steps:** Implement four-phase API architecture in Swift/SwiftUI
