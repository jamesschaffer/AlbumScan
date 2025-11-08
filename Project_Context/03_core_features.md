# CORE FEATURES

### Feature 1: Camera-Based Album Identification
- **Priority:** MUST-HAVE (Core feature)
- **Description:** Users can take a photo of any album cover, and the app identifies it using AI vision through a two-tier identification system
- **User Story:** "As a record store browser, I want to take a photo of an album cover so that I can instantly know what album it is and who the artist is"
- **Acceptance Criteria:**
  - Camera View shows live camera feed immediately upon load with square framing guide
  - User taps "SCAN" button to capture photo (no review/retake - immediate processing)
  - Photo is processed via two-tier identification system:
    - **ID Call 1:** Single-prompt identification (2-4 seconds, ~80-90% success rate)
    - **ID Call 2:** Search finalization with search gate (3-5 seconds, conditional - only 10-20% of scans)
    - **Artwork Retrieval:** MusicBrainz + Cover Art Archive (1-2 seconds, runs after identification)
    - **Review Generation:** Album review with caching (3-5 seconds or instant if cached)
  - App displays "We found [Album] by [Artist]" with artwork after identification completes (2 second confirmation screen)
  - If identification fails (either Call 1 unresolved or Call 2 fails search gate), displays error banner at top: "Unable to identify this cover art"
  - Error banner auto-dismisses after 3 seconds and returns to idle camera
  - Review generation runs after confirmation screen
  - If review generation fails, shows album details with "Review Temporarily Unavailable" message
  - Works with various cover conditions (worn, angled, partially visible, minimal text)
  - Stores MusicBrainz artwork, NOT user's original photo
  - Search gate blocks wasteful searches: requires 3+ readable characters AND medium/high text confidence

#### Sub-Feature 1A: High-Resolution Album Artwork Retrieval
- **Priority:** MUST-HAVE (Required for Feature 3 display)
- **Description:** After identification, retrieve high-resolution album artwork from MusicBrainz + Cover Art Archive
- **Technical Approach:** Sequential API calls using artist + album metadata from identification
- **User Story:** "As a user, I want to see high-quality album artwork so that I can visually identify and appreciate the album"
- **Acceptance Criteria:**
  - After identification returns album metadata, immediately initiate MusicBrainz artwork search
  - Search MusicBrainz API using artist name and album title to find release MBID (MusicBrainz ID)
  - Use MBID to query Cover Art Archive API for album artwork
  - Retrieve highest quality artwork available (prefer "front" cover image, typically 500px)
  - If Cover Art Archive returns no results, use gray placeholder with "Album art unavailable" text
  - Cache retrieved artwork locally (both 200px thumbnail for history and high-res for detail view)
  - Total artwork retrieval completes within 1-2 seconds
  - Handle multiple release variants by selecting the first matching result
  - Artwork URLs stored in Album entity (CoreData) for reference
  - If MusicBrainz search returns no matches, display album details with placeholder artwork
  - Artwork retrieval failure NEVER blocks album information display

##### Timing & Flow

**Current Implementation:**
- ID Call 1: 2-4 seconds (80-90% success, no search)
- ID Call 2: 3-5 seconds (10-20% of scans, conditional search)
- Artwork Retrieval: 1-2 seconds (runs after identification succeeds)
- Confirmation Screen: 2 seconds (shows "We found..." with artwork)
- Review Generation: 3-5 seconds or instant if cached
- **Total Time:** 8-13 seconds for new album with search, 5-7 seconds without search

**Sequential Execution:**
1. ID Call 1 executes (identifying state)
2. If searchNeeded: ID Call 2 executes with search gate validation
3. After identification succeeds: Artwork fetch begins
4. Transition to identified state (2-second confirmation with artwork)
5. Transition to loadingReview state
6. Review generation executes (with cache check first)
7. Save to CoreData and display full album details

**Non-Blocking Behavior:**
- If artwork retrieval fails: show placeholder, continue to confirmation screen
- If review generation fails: show album details with error message and rescan suggestion
- Partial success always better than total failure

**Loading States (from ScanState enum):**
- `.identifying` - "Flipping through every record bin in existence..."
- `.identified` - Shows artwork + "We found [Album] by [Artist]" (2 seconds)
- `.loadingReview` - Shows artwork + "Writing a review that's somehow both pretentious and correct..."
- `.complete` - Transitions to AlbumDetailsView
- `.identificationFailed` - Shows error banner "Unable to identify this cover art"


### Feature 2: Cultural Context & Quality Assessment
- **Priority:** MUST-HAVE (Core differentiator)
- **Description:** AI-powered concise album review providing critical assessment, cultural significance, and buying recommendation - explicitly NOT financial value or pricing information. Available in two tiers: Free (standard model) and Ultra (search-enabled model with prioritized sources)
- **User Story:** "As a record store browser, I want a quick, honest assessment of why an album matters musically and whether I should buy it, so I can make informed decisions while flipping through bins"
- **Architecture:** Generated after successful identification and artwork retrieval
  - **Free Tier:** Uses `gpt-4o` (NO web search capability, cost-optimized)
  - **Ultra Tier:** Uses `gpt-4o-search-preview` (WITH web search, prioritized professional sources)
- **Input:** Receives clean metadata from identification (artist name, album title, release year, genres, record label)
- **Acceptance Criteria:**
  - Review prompt receives ONLY metadata (no album identification task)
  - Displays 2-3 sentence opening summary capturing the album's core essence and importance
  - Provides 3-5 bullet points (formatted as actual bullets •) with specific evidence:
    - Critical reception (specific scores when confident, qualitative descriptions otherwise)
    - Concrete impact examples (chart performance, sales figures, awards when known)
    - Specific standout tracks and sonic qualities
    - Genre innovation or influence on other artists
    - Reputation evolution (initially panned vs. later acclaimed, etc.)
  - Includes rating out of 10 (assessment based on analysis)
  - Provides clear recommendation using tiered contextual labels (examples):
    - **TIER 1:** Essential Classic, Genre Landmark, Cultural Monument
    - **TIER 2:** Indie Masterpiece, Cult Essential, Critics' Choice
    - **TIER 3:** Crowd Favorite, Radio Gold, Crossover Success
    - **TIER 4:** Deep Cut, Surprise Excellence, Scene Favorite
    - **TIER 5:** Time Capsule, Influential Curio, Pioneering Effort
    - **TIER 6:** Reliable Listen, Fan Essential, Genre Staple
    - **TIER 7:** Ambitious Failure, Divisive Work, Uneven Effort
    - **TIER 8:** Forgettable Entry, Career Low, Avoid Entirely
  - Uses honest, direct language - calls out mediocre or bad albums explicitly
  - Focuses on what actually matters about the album (no filler or generic praise)
  - Evaluates albums purely on musical merit - artist's personal controversies or social issues may be mentioned for context but do NOT devalue their musical contributions or impact
  - Explicitly avoids any language about "investment," "value," "rare," "pressing details," or "collectibility"
  - NEVER mentions price, monetary value, or market considerations
  - **Model Selection:**
    - **Free:** `gpt-4o` (NO search capability - cost ~$0.05-0.10/review)
    - **Ultra:** `gpt-4o-search-preview` (WITH search - cost ~$0.08-0.13/review including ~$0.03 search)
  - **Ultra Source Prioritization:** When search is enabled, prioritizes professional publications in order:
    1. Metacritic (aggregated scores)
    2. Album of the Year (comprehensive database)
    3. Pitchfork (leading indie publication)
    4. Rolling Stone (classic music journalism)
    5. AllMusic (music encyclopedia)
    6. The Guardian (respected UK publication)
  - Shows cached content if album has been scanned before (avoids redundant API calls)
  - Cache check happens BEFORE API call (CoreData lookup with title normalization)
  - Title normalization strips variants: Deluxe, Remaster, Reissue, Edition, Anniversary
  - If review generation fails, displays album details with "Review Temporarily Unavailable" + suggestion to rescan

### Feature 3: Album Information Display
- **Priority:** MUST-HAVE
- **Description:** Detailed view showing comprehensive album metadata in a specific visual hierarchy
- **User Story:** "As a music enthusiast, I want to see complete album information so that I can learn about the album before listening"
- **Acceptance Criteria:**
  - Content displays in the following order:
    1. Album artwork (high resolution) - sourced from Cover Art Archive via MusicBrainz
    2. Recommendation badge overlay on artwork (label + rating)
       - Example: "ESSENTIAL CLASSIC" with rating "8.5"
       - Badge positioned at bottom of artwork, full width, black background
    3. Artist name and album title (from identification)
    4. Metadata row format:
       - **Released:** [year]
       - **Genre:** [genres comma-separated]
       - **Label:** [record label]
    5. Cultural context summary (2-3 sentences)
    6. Bullet points (3-5) with evidence
    7. Rating out of 10 (displayed separately in body text)
    8. Key Tracks section (3-7 tracks) with 🎵 emoji header
  - Loads instantly from cache if previously scanned (offline access for historical albums)
  - Handles partial failures gracefully:
    - If artwork retrieval failed: Show gray placeholder rectangle with "Album art unavailable" text
    - If review generation failed: Show artwork + basic metadata + error message
      - Error message: "Review Temporarily Unavailable" with explanation
      - Suggestion: "💡 Tip: Scan this album again to retry generating the review."
  - NO pricing information, pressing details, or market value anywhere
  - Typography: Helvetica Neue throughout with specific font sizes:
    - Artist name: 26pt bold
    - Album title: 22pt bold
    - Body text: 18pt
    - Metadata: 18pt (bold labels, light gray values)
  - Bullet points indented 8pt from left edge
  - Rating badge uses Bungee font for numbers (brand consistency)

### Feature 4: Scan History
- **Priority:** MUST-HAVE (Makes the app useful beyond single-use)
- **Description:** Simple chronological list of all scanned albums (newest first)
- **User Story:** "As a user, I want to review albums I've scanned so that I can remember what I found interesting"
- **Acceptance Criteria:**
  - Chronologically ordered list (newest first) via CoreData sort descriptor
  - Shows album cover thumbnail (200px cached version), title, and artist for each entry
  - Every scan is automatically saved to history (including duplicate scans of same album)
  - Users manage their list by swiping left to delete unwanted entries
  - Swipe-to-delete shows red trash icon, full swipe commits deletion immediately
  - Tapping item reopens full album information display (Feature 3)
  - Persists locally on device via CoreData (unlimited storage, no cap on saved albums)
  - No search/filter functionality (scroll only)
  - History button (hamburger icon - three horizontal lines) hidden on Camera View until user scans their first album
  - Visibility managed by AppState.hasScannedAlbums boolean
  - Empty state when no scans: Shows clock icon with "Scan your first album to begin" message
  - Camera button (bottom right) returns to scan view from history
  - List extends to bottom edge, scrolls behind floating camera button
  - Background: black (matches app branding)
  - Logo displayed at top of history view

---

## Additional Features (Implemented)

### Feature 5: Branded Launch Screen
- **Priority:** NICE-TO-HAVE (Polish)
- **Description:** Branded launch screen displays while app initializes
- **Implementation:**
  - Shows AlbumScan logo on black background
  - Displays for 1.5 seconds
  - Fades out with opacity animation (0.5 second transition)
  - Implemented in AlbumScanApp.swift using ZStack overlay
- **User Story:** "As a user, I want to see branded launch screen so I know the app is loading"

### Feature 6: Framing Guide
- **Priority:** MUST-HAVE (Usability)
- **Description:** Visual guide helps users properly frame album covers before scanning
- **Implementation:**
  - Square overlay with green border (brand color)
  - Black semi-transparent overlay (80% opacity) outside guide
  - Guide size: screen width minus 40px (20px margins on left/right)
  - Vertically centered with slight adjustment (1.5% downward)
  - Cutout uses .destinationOut blend mode for transparency
  - 4px green stroke (brand color) on guide border
- **User Story:** "As a user, I want visual guidance so I know how to properly frame the album cover"

### Feature 7: Error Banner (Top Slide-Down)
- **Priority:** MUST-HAVE (Error Handling)
- **Description:** Non-blocking error notification for identification failures
- **Implementation:**
  - Red banner slides down from top of screen
  - Text: "Unable to identify this cover art"
  - Auto-dismisses after 3 seconds
  - Spring animation (response: 0.4, dampingFraction: 0.8)
  - Triggered on .identificationFailed state
  - Resets to idle after dismiss (camera ready for next scan)
- **User Story:** "As a user, I want to know when identification fails so I can try again"

### Feature 8: Progress Indicators
- **Priority:** MUST-HAVE (User Feedback)
- **Description:** Loading states provide feedback during multi-second processing with progressive messaging
- **Implementation:**
  - Four distinct loading messages with strategic timing:
    1. Identifying (0-3.5s): "Extracting text and examining album art..."
    2. Identifying (3.5s+): "Flipping through every record bin in existence..."
    3. Identified (2s hold): "We found [Album] by [Artist]" (with artwork)
    4. Loading Review: "Writing a review that's somehow both pretentious and correct..."
  - Animated ellipsis (...) on states 1, 2, and 4 (cycles every 0.5 seconds)
  - Slide-in/slide-out transitions between states (0.3s exit, 0.4s entrance)
  - Album artwork (150px) fades in during identified state
  - Text positioned at 50% screen height consistently
  - Brand green color for dynamic text elements (ellipsis, album name, artist name)
  - Logo displayed at top of all loading screens
  - UX improvement: Breaking ID Call 1 into two messages reduces perceived wait time
- **User Story:** "As a user, I want to know what's happening during processing so I don't think the app is frozen"
- **Timing:** Total scan time 5-18 seconds broken into progressive stages to maintain engagement

### Feature 9: Two-Tier Subscription System
- **Priority:** MUST-HAVE (Monetization)
- **Description:** StoreKit 2 subscription system with two tiers (Base and Ultra) plus free trial
- **Implementation:**
  - **Free Tier:**
    - 5 free scans per user
    - Keychain + UserDefaults persistence (survives reinstall ~95%)
    - ScanLimitManager tracks usage
  - **Base Subscription ($4.99/year):**
    - 120 scans per month
    - ID Call 1 only (no web search capability)
    - StoreKit product: `albumscan_base_annual`
    - Best for: Casual users scanning well-known albums
  - **Ultra Subscription ($11.99/year):**
    - 120 scans per month
    - Full two-tier identification (ID Call 1 + ID Call 2 with search)
    - StoreKit product: `albumscan_ultra_annual`
    - Advanced search for obscure albums
    - Enhanced accuracy for modern releases (2020+)
    - Detailed reviews with cited sources (when "Enable Advanced Search" toggle is ON)
    - Best for: Serious collectors scanning deep cuts
  - **SubscriptionManager Service:**
    - Handles purchase, restore, verification via StoreKit 2
    - Transaction listener for renewals and updates
    - Keychain persistence for subscription tier
    - Subscription status broadcast to AppState
  - **WelcomePurchaseSheet:**
    - Onboarding screen showing subscription options
    - SubscriptionCardView component for purchase UI
    - Displays when user exhausts free scans or on first launch
  - **Settings Screen:**
    - Gear icon, bottom-left of camera controls (64x64, green border, black bg)
    - Sheet presentation with Ultra benefits card
    - "Enable Advanced Search" toggle (Ultra subscribers only)
    - Toggle controls review model: Free (`gpt-4o`) vs Ultra (`gpt-4o-search-preview`)
  - **Search Gate Behavior:**
    - Base subscribers: Search gate enforced (ID Call 2 blocked)
    - Ultra subscribers: Search gate bypassed when "Enable Advanced Search" is ON
- **User Story:** "As a user, I want flexible subscription options that match my usage level and feature needs"
- **Acceptance Criteria:**
  - Free tier allows 5 scans before requiring subscription
  - Base tier provides affordable access ($4.99/year) with basic identification
  - Ultra tier provides advanced features ($11.99/year) including search capability
  - Monthly limits (120 scans) prevent abuse
  - Purchase and restore work correctly via StoreKit 2
  - Subscription tier persists across app restarts (Keychain)
  - Scan count persists across app reinstalls (Keychain)

---

## Feature Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| Camera-Based Identification | ✅ Complete | Two-tier system with 80-90% first-call success |
| Cultural Context & Reviews | ✅ Complete | Two-tier: Free (gpt-4o) + Ultra (gpt-4o-search-preview) |
| Album Information Display | ✅ Complete | Handles partial failures gracefully |
| Scan History | ✅ Complete | Unlimited local storage, swipe-to-delete |
| Branded Launch Screen | ✅ Complete | 1.5 second display with fade |
| Framing Guide | ✅ Complete | Square green-bordered guide |
| Error Banner | ✅ Complete | Top slide-down, auto-dismiss |
| Progress Indicators | ✅ Complete | Four-stage messages with progressive timing |
| Two-Tier Subscription System | ✅ Complete | Free (5 scans), Base ($4.99), Ultra ($11.99) with StoreKit 2 |

---

**Document Accuracy:** This document reflects the actual implementation as of November 4, 2025, verified against CameraManager.swift, CameraView.swift, SettingsView.swift, AppState.swift, OpenAIAPIService.swift, LoadingView.swift, AlbumDetailsView.swift, ScanHistoryView.swift, ScanState.swift, SubscriptionManager.swift, ScanLimitManager.swift, and WelcomePurchaseSheet.swift.

---

**Last Updated:** November 4, 2025
