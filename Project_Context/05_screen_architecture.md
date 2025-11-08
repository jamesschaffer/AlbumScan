## SCREEN ARCHITECTURE

### Screen 1: Camera View (Default Home Screen)
- **Purpose:** Live camera feed for scanning album covers
- **Key Elements:**
  - Full-screen live camera feed
  - Square framing guide overlay (to center album covers)
    - The area outside the guide overlay is black with 80% opacity
    - Square guide is screen width minus 40px (20px margins on left and right)
    - Positioned vertically centered with slight 1.5% downward adjustment
    - Green border (4px stroke) using brand color
  - When picture is taken, crops to guide boundaries (excludes background records)
  - Camera lens set to 1x default zoom
  - **Bottom control bar (3 buttons):**
    - Settings button (bottom-left): Gear icon, 64x64, green border, black semi-transparent bg
    - SCAN button (bottom-center): "SCAN" text in Bungee font, 201px wide, green border, black semi-transparent bg
    - History button (bottom-right): Hamburger icon (three lines), 64x64, green border, black semi-transparent bg - only visible after first successful scan
  - AlbumScan logo displayed at top center
- **Navigation:**
  - App launches directly to this screen (after first-time onboarding)
  - Settings button → Settings Screen (sheet)
  - History button → Scan History Screen
  - SCAN button → Loading Screen 1 (Identification)

### Loading Screen 1: Identification + Artwork Retrieval
- **Purpose:** Indicates album identification and artwork retrieval in progress (two-tier system) with progressive messaging to reduce perceived wait time
- **Processing:**
  - **ID Call 1:** Single-prompt identification using `gpt-4o` (2-4 seconds, 80-90% success rate)
  - **ID Call 2 (Conditional):** Search finalization using `gpt-4o-search-preview` - only when Call 1 returns "search needed" (3-5 seconds, 10-20% of scans)
  - **Search Gate:** Validates search is worthwhile before triggering Call 2 (requires 3+ readable characters AND medium/high text confidence)
  - **Artwork Retrieval:** Fetches high-resolution artwork from MusicBrainz + Cover Art Archive after identification succeeds (1-2 seconds)
- **Key Elements:**
  - AlbumScan logo at top center
  - **Two-stage messaging during ID Call 1 (UX improvement):**
    - **Stage 1a (0-3.5s):** "Extracting text and examining album art..."
    - **Stage 1b (3.5s+):** "Flipping through every record bin in existence..."
    - Transition at 3.5s breaks up perceived wait time
    - Slide-out animation (0.3s) when transitioning between messages
  - Text animation: ellipsis cycles through 1, 2, 3 dots every 0.5 seconds
  - Text positioned at 50% screen height consistently
  - Text width: 75% of screen width, left-aligned
  - No cancel button
  - Black background, white text with brand green ellipsis
- **Duration:**
  - Without search: 5-7 seconds (Call 1 + artwork + review)
  - With search: 8-13 seconds (Call 1 + Call 2 + artwork + review)
- **Navigation:**
  - Success (identification + artwork complete) → Loading Screen 2 (Album Identified Confirmation)
  - Failure (identification fails OR search gate blocks) → Error Banner (top slide-down)

### Loading Screen 2: Album Identified Confirmation
- **Purpose:** Shows user the album we matched with brief confirmation hold
- **Processing Complete:** ID Call 1/2 + artwork retrieval finished successfully
- **Key Elements:**
  - AlbumScan logo at top center
  - Album artwork (high-resolution from Cover Art Archive, or gray placeholder if unavailable)
  - Text: "We found {Album Title} by {Artist Name}" (album/artist names in brand green)
  - Clean, left-aligned layout
  - Static display (no animated ellipsis)
  - Black background, white/green text
- **Duration:** 2.5 seconds total (2-second internal transition timer + 0.5s animation)
- **Purpose:** Allows user to visually confirm correct album match before review generation begins
- **Navigation:**
  - After 2.5 seconds → Automatically transitions to Loading Screen 3 (Review Generation)

### Loading Screen 3: Review Generation
- **Purpose:** Indicates review generation in progress after user has confirmed album match
- **Processing:** Review generation using `gpt-4o` (NO search capability) with aggressive caching
  - Cache check performed BEFORE API call (CoreData lookup with title normalization)
  - If cached: Returns instantly ($0 cost)
  - If not cached: Generates new review (3-5 seconds)
  - Model: `gpt-4o` regular model (music history is stable, search not needed)
- **Key Elements:**
  - AlbumScan logo at top center
  - Album artwork displayed (from previous screen)
  - Animated text with trailing ellipsis (...): "Writing a review that's somehow both pretentious and correct..."
  - Text animation: ellipsis cycles through 1, 2, 3 dots every 0.5 seconds
  - Dynamic text in brand green
  - Black background, white/green text
- **Duration:** 3-5 seconds for new review, or instant if cached
- **Navigation:**
  - Success → Album Details Screen (full review display)
  - Failure → Album Details Screen with "Review Temporarily Unavailable" message (no retry button)

### Album Details Screen
- **Purpose:** Display album information and cultural context
- **Key Elements:**
  - AlbumScan logo at top center (white semi-transparent background)
  - High-res album artwork from Cover Art Archive (500px preferred, scales to full screen width)
  - If artwork unavailable: Gray placeholder rectangle with text "Album art unavailable"
  - Artwork fills screen width with square aspect ratio
  - Recommendation badge overlaid at bottom of artwork (full width, black semi-transparent background)
    - Left: Recommendation label in white uppercase (e.g., "ESSENTIAL CLASSIC", "CULT ESSENTIAL")
    - Right: Rating in brand green using Bungee font (e.g., "8.5")
    - 8-tier tiered contextual label system (NOT emoji categories):
      - **TIER 1:** Essential Classic, Genre Landmark, Cultural Monument
      - **TIER 2:** Indie Masterpiece, Cult Essential, Critics' Choice
      - **TIER 3:** Crowd Favorite, Radio Gold, Crossover Success
      - **TIER 4:** Deep Cut, Surprise Excellence, Scene Favorite
      - **TIER 5:** Time Capsule, Influential Curio, Pioneering Effort
      - **TIER 6:** Reliable Listen, Fan Essential, Genre Staple
      - **TIER 7:** Ambitious Failure, Divisive Work, Uneven Effort
      - **TIER 8:** Forgettable Entry, Career Low, Avoid Entirely
  - Artist name (26pt bold Helvetica Neue)
  - Album title (22pt bold Helvetica Neue)
  - Metadata row format (18pt Helvetica Neue):
    - **Released:** [year]
    - **Genre:** [genres comma-separated]
    - **Label:** [record label]
  - Cultural context summary (2-3 sentences, 18pt body text)
  - Bullet points (3-5) with evidence (• bullets, indented 8pt from left)
  - Rating out of 10 (displayed separately in body text)
  - Key Tracks section with 🎵 emoji header (3-7 tracks)
  - AI disclaimer at bottom: "These ratings are generated fresh each time and may vary wildly..."
  - Close button (X icon) at bottom right - circular with green border, matches history button style
- **Partial Failure States:**
  - If artwork fails: Show gray placeholder, display all text content
  - If review generation fails: Show artwork + basic metadata + error message:
    - Orange warning triangle icon
    - "Review Temporarily Unavailable" heading
    - Explanation text
    - "💡 Tip: Scan this album again to retry generating the review." (suggestion only, NO retry button)
- **Navigation:**
  - X button → Returns to previous screen (Camera View or Scan History)
  - User must close details and rescan album to retry failed review (no inline retry)

### Scan History Screen
- **Purpose:** Chronological list of all scanned albums (newest first)
- **Key Elements:**
  - AlbumScan logo at top center (black semi-transparent background)
  - Scrollable list ordered by scannedDate descending (CoreData sort)
  - Each entry: album artwork thumbnail (200px cached), artist name, album title
  - Swipe-left-to-delete functionality:
    - Partial swipe shows red trash icon
    - Full swipe left immediately deletes (no tap required)
  - Camera icon button at bottom right - circular with green border, white camera icon
  - List extends to bottom edge, scrolls behind floating camera button
  - Empty state when no scans:
    - Clock icon
    - Text: "Scan your first album to begin"
  - Black background throughout
- **Navigation:**
  - Tap album row → Album Details Screen
  - Camera button → Camera View
  - Delete action → Removes album from CoreData

### Error Banner (Identification Failure)
- **Purpose:** Non-blocking error notification for failed identification attempts
- **Trigger:** ID Call 1 returns unresolved OR search gate blocks ID Call 2 (insufficient text/confidence)
- **Key Elements:**
  - Red banner slides down from top of screen
  - Text: "Unable to identify this cover art"
  - Semi-bold 16pt white text
  - Appears over camera view (does not block entire screen)
  - Spring animation (response: 0.4, dampingFraction: 0.8)
- **Behavior:**
  - Auto-dismisses after 3 seconds
  - Automatically resets camera to idle state (ready for next scan)
  - No user interaction required
- **Navigation:**
  - After auto-dismiss → Camera View (returns to idle, ready for new scan)

**Note:** Full-screen `ScanErrorView.swift` exists in codebase but is NOT used in actual implementation. Error handling uses this top slide-down banner instead.

### Welcome Screen (First-time only)
- **Purpose:** App introduction and branding for first launch
- **Trigger:** Shown when `appState.isFirstLaunch` is true (ContentView.swift routing)
- **Key Elements:**
  - Record circle icon (80pt, blue)
  - App name "AlbumScan" (large title, bold)
  - Tagline: "Discover music that matters" (title3, secondary color)
  - "Get Started" button (blue rounded, full width)
  - Clean vertical layout with spacers
- **Navigation:**
  - Get Started → Triggers camera permission request via `appState.requestCameraPermission()`
  - After permission granted → Camera View
  - If permission denied → Permission Error Screen

### Permission Error Screen (Edge case)
- **Purpose:** Handle camera permission denial
- **Trigger:** Shown when `appState.cameraPermissionDenied` is true (ContentView.swift routing)
- **Key Elements:**
  - Camera badge exclamationmark icon (70pt, orange)
  - Heading: "Camera Access Required" (title2, bold)
  - Explanation: "AlbumScan needs access to your camera to identify album covers." (body, secondary, centered)
  - "Open Settings" button (blue rounded, full width)
  - Clean vertical layout with spacers
- **Navigation:**
  - Open Settings → Opens `UIApplication.openSettingsURLString`
  - User returns after granting permission → App detects permission change → Camera View

### Settings Screen (Sheet Presentation)
- **Purpose:** Configure AlbumScan Ultra advanced search features
- **Trigger:** Tapping settings button (gear icon) on Camera View
- **Presentation:** Sheet with fixed 460pt height, no X button (dismisses via swipe-down gesture)
- **Key Elements:**
  - Black background (matches app branding)
  - **AlbumScan Ultra Benefits Card:** White semi-transparent background (10% opacity), 16pt corner radius
    - Title: "AlbumScan Ultra" (28pt bold, white)
    - Price: "$11.99/year" (20pt semibold, brand green)
    - Four benefit bullets with green checkmark icons:
      1. "Advanced search for obscure albums"
      2. "Enhanced accuracy for modern releases (2020+)"
      3. "Detailed reviews with cited sources"
      4. "Support continued development"
    - Toggle control: "Enable Advanced Search" label with iOS Toggle
      - Green tint when ON
      - Persists state to UserDefaults
  - Card padding: 24pt inside, 20pt horizontal/vertical margins
- **Functionality:**
  - **Toggle OFF (Free Tier):**
    - Uses `gpt-4o` for review generation (no search)
    - Uses `album_review.txt` prompt
    - Cost: ~$0.05-0.10 per review
  - **Toggle ON (Ultra Tier):**
    - Uses `gpt-4o-search-preview` for review generation (with search)
    - Uses `album_review_ultra.txt` prompt with source prioritization
    - Bypasses ID Call 2 search gate for obscure album identification
    - Cost: ~$0.08-0.13 per review (includes ~$0.03 search cost)
  - State saved to `UserDefaults.standard` with key `"searchEnabled"`
  - AppState broadcasts changes via `@Published var searchEnabled`
- **Navigation:**
  - Swipe down → Dismisses sheet → Camera View
  - Tap outside → Dismisses sheet → Camera View
- **Note:** Currently a placeholder UI for future subscription implementation - toggle works immediately without purchase validation

---

## Verification Summary

**Document Accuracy:** This document has been verified against the actual codebase implementation as of November 4, 2025.

**Files Verified:**
- `CameraView.swift` (Screen 1 - camera interface, settings/history buttons, error banner, framing guide)
- `SettingsView.swift` (Settings Screen - Ultra benefits card, toggle, sheet presentation)
- `CameraManager.swift` (cropping logic, framing guide positioning, identification flow, timing)
- `LoadingView.swift` (Loading Screens 1-3 - four-stage messages, animations, transitions)
- `SubscriptionManager.swift` (two-tier subscription system)
- `ScanLimitManager.swift` (free scan tracking)
- `WelcomePurchaseSheet.swift` (subscription onboarding)
- `AlbumDetailsView.swift` (Album Details Screen - layout, typography, close button, failure states)
- `ScanHistoryView.swift` (Scan History Screen - list implementation, camera button)
- `WelcomeView.swift` (Welcome Screen - first launch)
- `PermissionErrorView.swift` (Permission Error Screen - denial handling)
- `AppState.swift` (searchEnabled state management, UserDefaults persistence)
- `ContentView.swift` (app routing logic)
- `ScanErrorView.swift` (confirmed exists but NOT used)

**Major Updates (November 4, 2025):**
1. **Loading Screen 1 Enhancement:** Two-stage progressive messaging added
   - Stage 1a (0-3.5s): "Extracting text and examining album art..."
   - Stage 1b (3.5s+): "Flipping through every record bin in existence..."
   - 3.5-second transition timer (LoadingView.swift:182)
   - Slide-out animation (0.3s) between messages
   - UX improvement: Breaks up perceived wait time during ID Call 1
2. **Subscription System:** Two-tier model fully implemented
   - Free: 5 scans with Keychain + UserDefaults persistence
   - Base: $4.99/year, 120 scans/month, ID Call 1 only
   - Ultra: $11.99/year, 120 scans/month, full two-tier with search
3. **Text Positioning:** Consistently at 50% screen height (LoadingView.swift:73)
4. **Album Artwork Size:** 150px square in Loading Screen 2 (LoadingView.swift:27)

**Evidence-Based Changes:**
- LoadingView.swift:182 - 3.5 second timer triggers message transition
- LoadingView.swift:219-255 - Four distinct content text states
- LoadingView.swift:27 - Album size constant: 150px
- LoadingView.swift:34 - Text width: 75% of screen width
- Framing guide: 20px margins, 4px green border, vertical adjustment of 1.5%
- History button: Three horizontal rectangles (lines 90-98 in CameraView.swift)
- Loading Screen 2 hold: 2.5 seconds (CameraManager.swift:750)
- Error banner: Spring animation, 3-second auto-dismiss, red background
- Album details close button: Bottom right with green border
- Recommendation system: 8 tiers defined in album_review.txt prompt

**Architecture Verified:**
- Two-tier identification: ID Call 1 (gpt-4o, no search) → ID Call 2 conditional (gpt-4o-search-preview, with search)
- Review generation: gpt-4o (no search capability) with cache check
- State machine: `.idle → .identifying → .identified → .loadingReview → .complete` (ScanState.swift)
- Error states: `.identificationFailed` triggers banner, `.reviewFailed` shows partial results

---

**Last Updated:** November 4, 2025