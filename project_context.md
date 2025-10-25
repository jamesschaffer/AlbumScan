# PROJECT_CONTEXT.md
# AlbumScan - Music Album Discovery iOS App - Complete Development Guide

**Version:** 1.1 (Two-Tier API Architecture)
**Last Updated:** October 24, 2025  
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
7. [Two-Tier API Architecture](#two-tier-api-architecture)
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
- **Version:** 1.1 (Two-Tier API Refactor)
- **Purpose:** A music discovery companion that reveals the cultural significance and artistic merit of albums through photo identification
- **Target Audience:** Music collectors, vinyl enthusiasts, record store browsers who prioritize artistic value over financial value
- **Platform:** iOS (minimum iOS 16+)
- **Development Approach:** Native iOS using Swift/SwiftUI
- **MVP Scope:** Photo identification + cultural context only. NO Spotify playback integration in MVP.

---

## EXECUTIVE SUMMARY

This iOS application celebrates the joy of music discovery by helping collectors identify albums and understand their cultural significance, artistic merit, and historical impact. When digging through record store bins filled with hundreds of unfamiliar albums, collectors need a knowledgeable companion that can answer: "Is this musically important? Did this influence other artists? Is this album beloved by musicians and critics?"

**This app is deliberately NOT about pricing, pressing values, or financial collectibility.** Instead, this app focuses on the artistic and cultural dimensions of music discovery - helping users find albums that matter because of their sound, innovation, influence, and artistry.

**Key Innovation: Two-Tier API Strategy**
The app now uses a progressive two-tier approach that separates fast identification from deep analysis:
- **Phase 1 (2-4 seconds):** Quick album identification - fails fast if album can't be identified
- **Phase 2 (3-6 seconds):** Deep cultural analysis and review generation - only runs after successful identification

This architecture optimizes for speed, cost, and user experience. Users get immediate feedback on whether the scan worked, and only pay for expensive review generation when identification succeeds.

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
  - Photo is processed via two-tier API approach:
    - Phase 1: Identification (2-4 seconds)
    - Phase 2: Review generation (3-6 seconds, runs in background)
  - App displays album name and artist upon successful Phase 1 completion
  - If Phase 1 fails, displays "Couldn't find a match" message with "Try Again" button
  - Phase 2 runs in background while artwork loads
  - Works with various cover conditions (worn, angled, partially visible)
  - Stores only the album cover art, NOT the user's original photo

#### Sub-Feature 1A: High-Resolution Album Artwork Retrieval
- **Priority:** MUST-HAVE (Required for Feature 3 display)
- **Description:** After Claude API identifies an album (Phase 1), retrieve high-resolution album artwork from MusicBrainz + Cover Art Archive
- **Technical Approach:** Sequential API calls using artist + album metadata, runs in parallel with Phase 2
- **User Story:** "As a user, I want to see high-quality album artwork so that I can visually identify and appreciate the album"
- **Acceptance Criteria:**
  - After Phase 1 returns album identification, immediately initiate MusicBrainz artwork search (parallel with Phase 2)
  - Search MusicBrainz API using artist name and album title to find release MBID (MusicBrainz ID)
  - Use MBID to query Cover Art Archive API for album artwork
  - Retrieve highest quality artwork available (prefer "front" cover image)
  - If Cover Art Archive returns no results, fall back to placeholder: "Album art unavailable"
  - Cache retrieved artwork locally (both thumbnail for history and high-res for detail view)
  - Total artwork retrieval should complete within 2-3 seconds after album identification
  - Handle multiple release variants by selecting the first matching result (prefer original/main release)
  - Artwork URLs should be stored in Album entity for offline reference
  - If MusicBrainz search returns no matches, still display album details with placeholder artwork
  - Artwork retrieval failure should NEVER block album information display

### Feature 2: Cultural Context & Quality Assessment
- **Priority:** MUST-HAVE (Core differentiator)
- **Description:** AI-powered concise album review providing critical assessment, cultural significance, and buying recommendation - explicitly NOT financial value or pricing information
- **User Story:** "As a record store browser, I want a quick, honest assessment of why an album matters musically and whether I should buy it, so I can make informed decisions while flipping through bins"
- **Architecture:** Generated in Phase 2 (after successful identification), uses web search for current information
- **Acceptance Criteria:**
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
  - All content generated via Claude API Phase 2 using web search for research
  - Shows cached content if album has been scanned before (avoids redundant API calls)
  - If Phase 2 fails, displays "Review temporarily unavailable" with retry option

### Feature 3: Album Information Display
- **Priority:** MUST-HAVE
- **Description:** Detailed view showing comprehensive album metadata in a specific visual hierarchy
- **User Story:** "As a music enthusiast, I want to see complete album information so that I can learn about the album before listening"
- **Acceptance Criteria:**
  - Content displays in the following order:
    1. Album artwork (high resolution) - sourced from Cover Art Archive via MusicBrainz
    2. Artist name and album title
    3. Recommendation badge (ESSENTIAL/RECOMMENDED/SKIP/AVOID with emoji)
    4. Cultural context summary (from Feature 2, Phase 2)
    5. Bullet points (3-5) with evidence
    6. Rating out of 10
    7. Key Tracks section - Lists most popular/significant tracks from the album
  - Also displays: Release year, genre(s), record label (from Phase 1)
  - Loads progressively:
    - Phase 1 data (artist, title, year, genre) appears first
    - Artwork loads in parallel with Phase 2
    - Review content appears when Phase 2 completes
  - Loads instantly from cache if previously scanned (offline access for historical albums)
  - Handles partial failures gracefully:
    - If artwork fails: Show placeholder, display all text
    - If Phase 2 fails: Show basic info + "Review temporarily unavailable" with retry button
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

### Flow 2: Primary Use Case - Album Scan & Musical Discovery (Two-Tier)
```
Launch App → Camera View (Screen 1) → Tap "SCAN" Button 
  → Screen 2: Identification Loading (Phase 1, 2-4 sec)
  → Screen 2B: Album Identified Transition (0.5 sec)
  → Screen 2C: Review Loading (Phase 2 + Artwork, 3-6 sec)
  → Album Details (Screen 3) 
  → Auto-saved to History 
  → Tap "X" → Camera View (Screen 1)
```

### Flow 3: Album Scan - Phase 1 Failure (Identification Failed)
```
Launch App → Camera View (Screen 1) → Tap "SCAN" Button 
  → Screen 2: Identification Loading (Phase 1)
  → Scan Error (Screen 5: "Couldn't find a match") 
  → Tap "TRY AGAIN" → Camera View (Screen 1)
```

### Flow 4: Album Scan - Phase 2 Failure (Review Generation Failed)
```
Launch App → Camera View (Screen 1) → Tap "SCAN" Button 
  → Screen 2: Identification Loading (Phase 1, succeeds)
  → Screen 2B: Album Identified Transition
  → Screen 2C: Review Loading (Phase 2 fails)
  → Album Details (Screen 3) with basic info + "Review temporarily unavailable"
  → User taps "Retry Review" → Re-runs Phase 2 only
  → Review appears on success
```

### Flow 5: Review Scan History
```
Launch App → Camera View (Screen 1) → Tap History Icon 
  → Scan History (Screen 4) 
  → Tap Album → Album Details (Screen 3) 
  → Tap "X" → Scan History (Screen 4)
```

### Flow 6: Scan from History View
```
Scan History (Screen 4) → Tap "SCAN" Button → Camera View (Screen 1) 
  → Tap "SCAN" Button → [Follow Flow 2]
```

### Flow 7: Delete Album from History
```
Scan History (Screen 4) → Swipe Left on Album → Tap Delete → Album Removed from List
```

### Flow 8: Re-scan Existing Album (Duplicate Allowed)
```
Camera View (Screen 1) → Tap "SCAN" Button → [Follow Flow 2]
```
**Note:** All scans are saved to history, including duplicates. Users manage duplicates by swiping to delete.

### Flow 9: Camera Permission Denied
```
Launch App (First Time) → Welcome Screen → Camera Permission Request → User Denies 
  → Permission Error Screen → "Open Settings" Button → iOS Settings 
  → User Grants Permission → Return to App → Camera View (Screen 1)
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

### Screen 2: Identification Loading State (Phase 1)
- **Purpose:** Indicates album identification in progress
- **Key Elements:**
  - "ALBUM SCAN" header (top, white text)
  - Animated text with trailing ellipsis (...): "Flipping through every record bin in existence..."
  - Text animation: ellipsis cycles through 1, 2, 3 dots
  - Minimum display time: 1 second (even if API responds faster)
  - No cancel button
  - Black background, white text
- **Duration:** 2-4 seconds (target: 3 seconds average)
- **Navigation:** 
  - Success → Screen 2B (Album Identified Transition)
  - Failure → Scan Error (Screen 5)

### Screen 2B: Album Identified Transition (NEW)
- **Purpose:** Shows successful identification while initiating Phase 2 and artwork fetch
- **Key Elements:**
  - "ALBUM SCAN" header (top)
  - Album title and artist name (prominent, centered, white text)
  - Small loading indicator below album info
  - Text: "Loading details..."
  - Background: Black
- **Duration:** 0.5-1 second (brief confirmation before transitioning)
- **Behavior:** 
  - Triggers Phase 2 (review generation) immediately
  - Triggers artwork fetch (MusicBrainz + Cover Art Archive) in parallel
- **Navigation:** 
  - Automatically transitions to Screen 2C (Review Loading)

### Screen 2C: Review Loading State (Phase 2 + Artwork)
- **Purpose:** Shows album artwork while review generates in background
- **Key Elements:**
  - Album artwork displayed (high-res from Cover Art Archive, or placeholder if unavailable)
  - Artist name and album title visible at top
  - Loading indicator in review area (below artwork)
  - Animated text: "Writing a review that's somehow both pretentious and correct..."
  - Text animation: ellipsis cycles through 1, 2, 3 dots
  - Minimum display time: 1 second
  - Black background
- **Duration:** 3-6 seconds (while Phase 2 processes)
- **Navigation:** 
  - Success → Album Details (Screen 3) with full review
  - Phase 2 fails → Album Details (Screen 3) with "Review temporarily unavailable" message

### Screen 3: Album Details
- **Purpose:** Display album information and cultural context
- **Key Elements:**
  - High-res album artwork from Cover Art Archive (minimum 500x500px when available, scales up to full width of screen)
  - If artwork unavailable: Display centered placeholder with text "Album art unavailable" on neutral gray background
  - Artwork should fill width of screen with appropriate aspect ratio (typically square for albums)
  - Artist name and album title (prominent)
  - Recommendation badge with emoji (ESSENTIAL/RECOMMENDED/SKIP/AVOID)
  - Cultural context summary (2-3 sentences) - from Phase 2
  - Bullet points (3-5) with evidence - from Phase 2
  - Rating out of 10 - from Phase 2
  - Key Tracks section - from Phase 2
  - Release year, genre(s), record label - from Phase 1
  - "X" button (top right)
  - History icon (top right, next to X)
- **Partial Failure States:**
  - If artwork fails: Show placeholder, display all text content
  - If Phase 2 fails: Show artwork (if available) + basic metadata + "Review temporarily unavailable" message with "Retry Review" button
  - "Retry Review" button re-runs only Phase 2 (not Phase 1 or artwork fetch)
- **Navigation:** 
  - X button → Returns to previous screen (Camera View or Scan History)
  - History icon → Scan History (Screen 4)
  - "Retry Review" button (if Phase 2 failed) → Re-runs Phase 2, updates display on success

### Screen 4: Scan History
- **Purpose:** Chronological list of all scanned albums
- **Key Elements:**
  - Scrollable list (newest first)
  - Each entry: thumbnail, artist name, album title, scan date
  - Swipe-left-to-delete functionality
  - History icon (top right)
  - "SCAN" button (bottom)
  - Empty state: "Scan your first album to begin"
- **Navigation:** 
  - Tap album → Album Details (Screen 3)
  - SCAN button → Camera View (Screen 1)
  - History icon → Returns to Camera View (Screen 1)

### Screen 5: Scan Error (Phase 1 Failure)
- **Purpose:** Handle failed identification attempts
- **Key Elements:**
  - Error icon
  - Message: "Couldn't find a match"
  - Optional hint text: "Make sure the front of the album cover is clear and fills the frame"
  - "TRY AGAIN" button
- **Navigation:** 
  - TRY AGAIN → Camera View (Screen 1)

### Welcome Screen (First-time only)
- **Purpose:** App introduction and branding
- **Key Elements:**
  - App name/logo
  - Tagline: "Discover music that matters"
  - "Get Started" button
- **Navigation:** 
  - Get Started → Camera Permission Request → Camera View (Screen 1)

### Permission Error Screen (Edge case)
- **Purpose:** Handle camera permission denial
- **Key Elements:**
  - Error/warning icon
  - Message explaining camera access is required
  - "Open Settings" button (opens iOS Settings)
  - Brief explanation of why camera permission is needed
- **Navigation:** 
  - Open Settings → iOS Settings app
  - User returns after granting permission → Camera View (Screen 1)

---

## TWO-TIER API ARCHITECTURE

### Overview
AlbumScan uses a progressive two-tier API strategy that separates fast identification from deep analysis, optimizing for speed, cost, and user experience.

**Key Benefits:**
1. **Fail Fast:** Users know within 3 seconds if scan worked
2. **Lower Cost on Failures:** Failed IDs cost ~$0.03-0.05 instead of $0.20-0.30
3. **Progressive Disclosure:** Users see results incrementally (feels faster)
4. **Better Error Handling:** Can show partial results if review fails
5. **Optimization Opportunities:** Can cache Phase 1 results separately
6. **Future-Proof:** Could add alternative review sources without re-identifying

---

### Phase 1: Fast Identification (2-4 seconds)

**Purpose:** Quickly identify the album with minimal processing

**API Call Details:**
- **Endpoint:** Anthropic Claude API (Vision + Text)
- **Model:** Claude Sonnet 4.5
- **Input:** Album cover photo (JPEG, 1024x1024, 1-2MB)
- **Prompt:** See `phase1_album_identification_prompt.txt`
- **Key Characteristics:**
  - Minimal prompt focused purely on identification
  - NO web search enabled (speed critical)
  - NO cultural analysis
  - NO review generation
  - Binary outcome: success or error
- **Expected Response Time:** 2-4 seconds
- **Cost:** ~$0.03-0.05 per call
- **Max Tokens:** 300 (small response)

**Success Response JSON:**
```json
{
  "success": true,
  "artist_name": "Radiohead",
  "album_title": "OK Computer",
  "release_year": "1997",
  "genres": ["Alternative Rock", "Art Rock"],
  "record_label": "Parlophone"
}
```

**Error Response JSON:**
```json
{
  "success": false,
  "error_message": "Could not identify album cover"
}
```

**Phase 1 Error Scenarios (All return error):**
- Image is not an album cover (random object, person, etc.)
- Image is back cover of album
- Image is too blurry/out of focus to identify
- Image is too zoomed in (partial view) or too far out (detail too small)
- Multiple albums in frame (ambiguous)
- Bootleg/unofficial release with uncertain identity
- Claude has low confidence in identification

**On Success:**
- Display album title + artist immediately (Screen 2B)
- Trigger MusicBrainz artwork fetch (parallel with Phase 2)
- Trigger Phase 2 review generation
- Transition to Screen 2C

**On Failure:**
- Route to Scan Error (Screen 5)
- User taps "TRY AGAIN" → Camera View
- No Phase 2 call made (save cost)
- Total cost of failure: ~$0.03-0.05

---

### Phase 2: Deep Review Generation (3-6 seconds)

**Purpose:** Generate comprehensive cultural context and review using web research

**API Call Details:**
- **Endpoint:** Anthropic Claude API (Text only, no vision)
- **Model:** Claude Sonnet 4.5
- **Input:** Album metadata from Phase 1 (text string: "Artist: {artist}, Album: {album}, Year: {year}, Genre: {genres}, Label: {label}")
- **Prompt:** See `phase2_review_generation_prompt.txt`
- **Key Characteristics:**
  - Full review prompt with web search ENABLED
  - Research current album information
  - Generate ratings, recommendations, key tracks, bullets
  - No image input (uses metadata only)
- **Expected Response Time:** 3-6 seconds
- **Cost:** ~$0.15-0.25 per call
- **Max Tokens:** 1500 (larger response)

**Success Response JSON:**
```json
{
  "context_summary": "OK Computer is Radiohead's landmark 1997 album that captured millennial anxiety through experimental rock. It transformed alternative music by proving ambitious art-rock could achieve both critical and commercial success. The album's influence on indie and electronic music remains profound nearly three decades later.",
  "context_bullets": [
    "Acclaimed as one of the greatest albums ever made, with a 9.1 from Pitchfork and consistent top-10 rankings in all-time lists.",
    "Hit #1 in the UK and went triple-platinum in the US, proving experimental rock could be commercially viable.",
    "Pioneered the use of electronic textures in rock, directly influencing bands like Muse, Coldplay, and The National.",
    "Features iconic tracks 'Paranoid Android,' 'Karma Police,' and 'No Surprises' that remain alternative radio staples.",
    "Won the 1998 Grammy for Best Alternative Music Album and was added to the Library of Congress's National Recording Registry in 2015."
  ],
  "rating": 9.5,
  "recommendation": "ESSENTIAL",
  "key_tracks": ["Paranoid Android", "Karma Police", "No Surprises", "Exit Music (For a Film)", "Let Down"]
}
```

**On Success:**
- Display full review in Album Details (Screen 3)
- Save complete album data to CoreData
- Cache review for future scans of same album

**On Failure:**
- Still display Album Details (Screen 3) with:
  - Album artwork (already fetched in parallel)
  - Basic metadata (from Phase 1)
  - Error message: "Review temporarily unavailable"
  - "Retry Review" button that re-triggers only Phase 2 (doesn't re-identify)
- User can retry Phase 2 without re-scanning or paying for Phase 1 again

---

### Parallel Process: Artwork Retrieval (1-3 seconds)

**Runs concurrently with Phase 2 review generation**

**Sequence:**
1. **MusicBrainz Search** (0.5-1 second)
   - Trigger immediately after Phase 1 success
   - Query using artist + album from Phase 1 metadata
   - Retrieve MBID (MusicBrainz ID)
   - Endpoint: `https://musicbrainz.org/ws/2/release`
   - Query: `artist:{artist_name} AND release:{album_title}`
   
2. **Cover Art Archive** (0.5-1 second)
   - Query using MBID from MusicBrainz
   - Download 500px image (large size)
   - Endpoint: `https://coverartarchive.org/release/{mbid}`
   
3. **Cache & Display** (0.5-1 second)
   - Generate 200px thumbnail for history
   - Cache both sizes locally (CoreData)
   - Display in Screen 2C and Screen 3

**Total artwork time:** 1-3 seconds (completes before or during Phase 2)

**Artwork Failure Handling:**
- MusicBrainz returns no results → Use placeholder
- Cover Art Archive returns 404 → Use placeholder
- Network timeout → Use placeholder
- All artwork failures are non-blocking (album info still displays)

---

### Complete User Flow Timeline

```
User taps SCAN
↓
[0-4s] Phase 1: Identification
Screen 2: "Flipping through every record bin in existence..."
↓
SUCCESS → Phase 1 complete
↓
[0.5s] Screen 2B: "OK Computer by Radiohead" (brief confirmation)
↓
[PARALLEL EXECUTION BEGINS]
├─ [1-3s] MusicBrainz → Cover Art Archive → Display artwork
└─ [3-6s] Phase 2: Review generation
↓
Screen 2C: Shows artwork + "Writing a review that's somehow both pretentious and correct..."
↓
[BOTH COMPLETE]
↓
Screen 3: Full Album Details (artwork + review)
```

**Total Time:** 5-10 seconds from scan to complete display
**Perceived Time:** ~3 seconds to know if scan worked + background loading

**Cost Breakdown:**
- Phase 1 (ID): ~$0.03-0.05
- Phase 2 (Review): ~$0.15-0.25
- **Total per successful scan:** ~$0.18-0.30
- **Cost per failed scan:** ~$0.03-0.05 (Phase 1 only)

**Cost Comparison to Single-Tier:**
- Old approach: $0.20-0.30 per scan (success or failure)
- New approach: $0.03-0.05 for failures, $0.18-0.30 for successes
- **Savings:** 80-85% cost reduction on failed scans

---

### State Management Requirements

**SwiftUI State Enum:**
```swift
enum ScanState {
    case idle                    // Camera view, ready to scan
    case identifying             // Phase 1 in progress
    case identified              // Phase 1 success, brief transition
    case loadingReview           // Phase 2 + artwork in progress
    case complete                // Both phases done
    case identificationFailed    // Phase 1 failed
    case reviewFailed            // Phase 1 worked, Phase 2 failed
}
```

**Album Data Structure:**
```swift
struct AlbumScanData {
    // Phase 1 data (identification)
    var artistName: String?
    var albumTitle: String?
    var releaseYear: String?
    var genres: [String]?
    var recordLabel: String?
    var phase1Completed: Bool = false
    
    // Artwork data (parallel with Phase 2)
    var albumArtwork: UIImage?
    var artworkLoaded: Bool = false
    var musicbrainzID: String?
    
    // Phase 2 data (review)
    var contextSummary: String?
    var contextBullets: [String]?
    var rating: Double?
    var recommendation: String?
    var keyTracks: [String]?
    var phase2Completed: Bool = false
    
    // Error tracking
    var phase1Error: String?
    var phase2Error: String?
}
```

---

### Error Handling in Two-Tier System

**Scenario 1: Phase 1 Fails (Identification)**
- User Experience: Screen 5 (Scan Error) - "Couldn't find a match"
- User Action: Tap "TRY AGAIN" → Camera View
- Cost Impact: ~$0.03-0.05 (no Phase 2 call)
- System Behavior: Phase 2 never triggered

**Scenario 2: Phase 1 Succeeds, Artwork Fails**
- User Experience: Album Details with placeholder artwork
- Review displays normally
- All text data visible
- Non-blocking error
- Cost Impact: Full cost (~$0.18-0.30)

**Scenario 3: Phase 1 Succeeds, Phase 2 Fails**
- User Experience: Album Details with:
  - Real artwork (if available, otherwise placeholder)
  - Basic metadata (artist, title, year, genre, label)
  - Error in review area: "Review temporarily unavailable"
  - "Retry Review" button (only re-runs Phase 2)
- Cost Impact: Phase 1 cost (~$0.03-0.05) initially, Phase 2 cost (~$0.15-0.25) on retry
- System Behavior: Partial success is better than total failure

**Scenario 4: Both Artwork and Phase 2 Fail**
- User Experience: Album Details with:
  - Placeholder artwork
  - Basic metadata (from Phase 1)
  - "Review temporarily unavailable"
  - "Retry Review" button
- Still Useful: User knows what album it is
- Cost Impact: Phase 1 cost only (~$0.03-0.05)

**Scenario 5: Network Failure Mid-Process**
- If Phase 1 in progress: Show error, retry from beginning
- If Phase 2 in progress: Show partial results with retry option
- If artwork in progress: Show placeholder, continue with review

---

### Caching Strategy for Two-Tier System

**Phase 1 Cache (Identification):**
- **Decision:** Do NOT cache Phase 1 results by image
- **Reasoning:** 
  - Image hashing is expensive
  - Phase 1 is fast (2-4s) and cheap ($0.03-0.05)
  - User rarely scans exact same photo twice
  - Not worth the complexity

**Phase 2 Cache (Review):**
- **Cache Key:** `"{artist_name}_{album_title}".lowercased().replacingOccurrences(of: " ", with: "_")`
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
- **Async/Await:** Modern Swift concurrency for two-tier API calls and parallel execution
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
  
  // Phase 1 Data (Identification)
  artistName: String
  albumTitle: String
  releaseYear: String?
  genres: [String]  // Array stored as JSON or comma-separated
  recordLabel: String?
  phase1Completed: Bool  // Track if Phase 1 succeeded
  
  // Artwork Data (Parallel with Phase 2)
  musicbrainzID: String?  // MBID for future reference
  albumArtURL: String?  // Cover Art Archive URL (large/500px)
  albumArtThumbnailData: Data?  // Cached 200x200 JPEG for history
  albumArtHighResData: Data?  // Cached 500px JPEG for detail view
  albumArtRetrievalFailed: Bool  // Track if artwork lookup failed
  artworkLoaded: Bool  // Track if artwork fetch completed
  
  // Phase 2 Data (Review)
  contextSummary: String?  // 2-3 sentence opening
  contextBulletPoints: [String]  // 3-5 bullets, stored as JSON or comma-separated
  rating: Double?  // 0-10
  recommendation: String?  // ESSENTIAL/RECOMMENDED/SKIP/AVOID
  keyTracks: [String]  // Stored as JSON or comma-separated
  phase2Completed: Bool  // Track if Phase 2 succeeded
  phase2Failed: Bool  // Track if Phase 2 needs retry
  phase2LastAttempt: Date?  // When we last tried Phase 2 (for retry logic)
  
  // Metadata
  scannedDate: Date  // When user first scanned this
  lastViewedDate: Date?  // Last time user opened this album in history
  
  // Raw API Responses (Optional, for debugging)
  rawPhase1Response: String?
  rawPhase2Response: String?
}
```

### Storage Strategy

**Auto-save Policy:**
- Phase 1 success: Immediately save to CoreData with basic metadata
- Artwork fetch: Update existing record with artwork data
- Phase 2 success: Update existing record with review data
- This allows partial saves (can show basic info even if Phase 2 fails)

**Duplicates:**
- Duplicates ARE allowed - every scan creates new entry
- Same album scanned multiple times = multiple CoreData entries
- Users manage duplicates manually via swipe-to-delete in history

**Caching:**
- Review content cached indefinitely (reviews don't change)
- Before Phase 2 call, check CoreData for existing album with matching artist + title
- If exists: Skip Phase 2 API call, use cached review
- If not exists: Make Phase 2 API call, cache result

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
- Phase 1 with real Claude API (using test images)
- Phase 2 with real Claude API (using test metadata)
- MusicBrainz search → Parse MBID
- Cover Art Archive query → Download image
- Full two-tier flow with real APIs

**Parallel Execution Tests:**
- Artwork and Phase 2 run in parallel
- Both complete, display together
- Artwork fails, Phase 2 succeeds
- Artwork succeeds, Phase 2 fails
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
- Users should see album info + artwork within 5-10 seconds total
- Phase 1: 2-4 seconds
- Artwork + Phase 2 (parallel): 3-6 seconds
- Total: 5-10 seconds

**Parallel Execution:**
- Artwork retrieval runs concurrently with Phase 2 review generation
- Both processes start immediately after Phase 1 success
- Whichever finishes first displays immediately
- Screen 2C shows artwork while review generates

**Non-Blocking:**
- Never block album information display waiting for artwork
- If artwork fails, show placeholder immediately
- If Phase 2 fails, show artwork + basic metadata immediately

**Aggressive Timeout:**
- 5 seconds max for entire artwork retrieval process
- MusicBrainz: 5 seconds
- Cover Art Archive: 5 seconds (query + download)
- After timeout, use placeholder and continue

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
- Phase 2 reviews cached indefinitely (reviews don't change)
- Before Phase 2 call, check CoreData for existing album
- If review exists: Skip Phase 2 API call, use cached review
- If not: Make Phase 2 API call, cache result in CoreData

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
- Phase 1: `phase1_album_identification_prompt.txt`
- Phase 2: `phase2_review_generation_prompt.txt`

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
- Single "TRY AGAIN" action for all Phase 1 errors (keep it simple)
- "Retry Review" button for Phase 2 errors (only retries review, not identification)

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

**Document Version:** 1.1 (Two-Tier API Architecture)
**Last Updated:** October 24, 2025  
**Status:** Ready for two-tier refactoring  
**Next Steps:** Implement two-tier API architecture in Swift/SwiftUI