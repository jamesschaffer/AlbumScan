# PROJECT_CONTEXT.md
# Music Album Discovery iOS App - Complete Development Guide

**Version:** 1.0 MVP  
**Last Updated:** October 19, 2025  
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
7. [Technical Stack](#technical-stack)
8. [API Integration](#api-integration)
9. [Data Model](#data-model)
10. [Camera Implementation](#camera-implementation)
11. [UI/UX Requirements](#uiux-requirements)
12. [Error Handling](#error-handling)
13. [Testing Strategy](#testing-strategy)

---

## PROJECT OVERVIEW

- **App Name:** TBD (suggestions: VinylID, AlbumSpot, RecordFinder, SpinID, Crate, DiscoverDisc)
- **Version:** 1.0 (MVP)
- **Purpose:** A music discovery companion that reveals the cultural significance and artistic merit of albums through photo identification
- **Target Audience:** Music collectors, vinyl enthusiasts, record store browsers who prioritize artistic value over financial value
- **Platform:** iOS (minimum iOS 16+)
- **Development Approach:** Native iOS using Swift/SwiftUI
- **MVP Scope:** Photo identification + cultural context only. NO Spotify playback integration in MVP.

---

## EXECUTIVE SUMMARY

This iOS application celebrates the joy of music discovery by helping collectors identify albums and understand their cultural significance, artistic merit, and historical impact. When digging through record store bins filled with hundreds of unfamiliar albums, collectors need a knowledgeable companion that can answer: "Is this musically important? Did this influence other artists? Is this album beloved by musicians and critics?"

**This app is deliberately NOT about pricing, pressing values, or financial collectibility.** Instead, this app focuses on the artistic and cultural dimensions of music discovery - helping users find albums that matter because of their sound, innovation, influence, and artistry.

**The MVP is intentionally simple:** Take a photo, identify the album, see rich cultural context and musical significance. That's it. No playback integration, no complex features - just the core discovery loop.

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
  - Photo is processed within 3-5 seconds with generic loading spinner
  - App displays album name and artist upon successful identification
  - Takes best match if multiple similar albums exist
  - If identification fails, displays "Couldn't find a match" message with "Try Again" button that returns user to Camera View
  - Works with various cover conditions (worn, angled, partially visible)
  - Stores only the album cover art, NOT the user's original photo

#### Sub-Feature 1A: High-Resolution Album Artwork Retrieval
- **Priority:** MUST-HAVE (Required for Feature 3 display)
- **Description:** After Claude API identifies an album, retrieve high-resolution album artwork from MusicBrainz + Cover Art Archive
- **Technical Approach:** Sequential API calls using artist + album metadata
- **User Story:** "As a user, I want to see high-quality album artwork so that I can visually identify and appreciate the album"
- **Acceptance Criteria:**
  - After Claude API returns album identification (artist name + album title), immediately initiate MusicBrainz artwork search
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
  - All content generated via Claude API using a provided prompt that handles web search and formatting internally
  - Shows cached content if album has been scanned before (avoids redundant API calls)

### Feature 3: Album Information Display
- **Priority:** MUST-HAVE
- **Description:** Detailed view showing comprehensive album metadata in a specific visual hierarchy
- **User Story:** "As a music enthusiast, I want to see complete album information so that I can learn about the album before listening"
- **Acceptance Criteria:**
  - All information loads within 3 seconds
  - Content displays in the following order:
    1. Album artwork (high resolution) - sourced from Claude API response, with fallback to image search if needed
    2. Artist name and album title
    3. Recommendation badge (ESSENTIAL/RECOMMENDED/SKIP/AVOID with emoji)
    4. Cultural context summary (from Feature 2)
    5. Key Tracks section - Lists most popular/significant tracks from the album (Claude identifies these)
  - Also displays: Release year, genre(s), record label
  - Loads instantly from cache if previously scanned (offline access for historical albums)
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

### Flow 2: Primary Use Case - Album Scan & Musical Discovery
```
Launch App → Camera View (Screen 1) → Tap "SCAN" Button → Search Pre-Loader (Screen 2) → Album Details (Screen 3) → Auto-saved to History → Tap "X" → Camera View (Screen 1)
```

### Flow 3: Album Scan - Error Handling
```
Launch App → Camera View (Screen 1) → Tap "SCAN" Button → Search Pre-Loader (Screen 2) → Scan Error (Screen 5) → Tap "TRY AGAIN" → Camera View (Screen 1)
```

### Flow 4: Review Scan History
```
Launch App → Camera View (Screen 1) → Tap History Icon → Scan History (Screen 4) → Tap Album → Album Details (Screen 3) → Tap "X" → Scan History (Screen 4)
```

### Flow 5: Scan from History View
```
Scan History (Screen 4) → Tap "SCAN" Button → Camera View (Screen 1) → Tap "SCAN" Button → Search Pre-Loader (Screen 2) → Album Details (Screen 3) → Auto-saved to History → Tap "X" → Camera View (Screen 1)
```

### Flow 6: Delete Album from History
```
Scan History (Screen 4) → Swipe Left on Album → Tap Delete → Album Removed from List
```

### Flow 7: Re-scan Existing Album (Duplicate Allowed)
```
Camera View (Screen 1) → Tap "SCAN" Button → Search Pre-Loader (Screen 2) → Album Details (Screen 3) → Auto-saved to History → Tap "X" → Camera View (Screen 1)
```
**Note:** All scans are saved to history, including duplicates. Users manage duplicates by swiping to delete.

### Flow 8: Camera Permission Denied
```
Launch App (First Time) → Welcome Screen → Camera Permission Request → User Denies → Permission Error Screen → "Open Settings" Button → iOS Settings → User Grants Permission → Return to App → Camera View (Screen 1)
```

---

## SCREEN ARCHITECTURE

### Screen 1: Camera View (Default Home Screen)
- **Purpose:** Live camera feed for scanning album covers
- **Key Elements:**
  - Full-screen live camera feed
  - Square framing guide overlay (to center album covers)
    - The area outside the guide overlay should be black with 80% opacity
    - This square should be large as possible with ~20px margin on the left and right of the screen
    - This square should be positioned perfecting center measured from the top and bottom of the iphone
  - When the picture is taken, you need to crop everything that is outside the guide so other records in the background are not included
  - You need to set the camera lens to the 1x default zoom
  - Large "SCAN" button at bottom
  - History icon (clock symbol) - only visible after first successful scan
- **Navigation:** 
  - App launches directly to this screen (after first-time onboarding)
  - History icon → Scan History (Screen 4)
  - SCAN button → Search Pre-Loader (Screen 2)

### Screen 2: Search Pre-Loader (Loading State)
- **Purpose:** Indicates processing during API call
- **Key Elements:**
  - Generic loading spinner
  - Text: "Identifying album..."
  - No cancel button (quick 3-5 second process)
- **Navigation:** 
  - Success → Album Details (Screen 3)
  - Failure → Scan Error (Screen 5)

### Screen 3: Album Details
- **Purpose:** Display album information and cultural context
- **Key Elements:**
  - High-res album artwork from Cover Art Archive (minimum 500x500px when available, scales up to full width of screen)
  -   If artwork unavailable: Display centered placeholder with text "Album art unavailable" on neutral gray background
  -   Artwork should fill width of screen with appropriate aspect ratio (typically square for albums)
  -   Loading state: Show shimmer/skeleton placeholder while artwork downloads
  - Artist name and album title (prominent)
  - Recommendation badge with emoji (ESSENTIAL/RECOMMENDED/SKIP/AVOID)
  - Cultural context summary (2-3 sentences)
  - Bullet points (3-5) with evidence
  - Rating out of 10
  - Key Tracks section
  - Release year, genre(s), record label
  - "X" button (top right)
  - History icon (top right, next to X)
- **Navigation:** 
  - X button → Returns to previous screen (Camera View or Scan History)
  - History icon → Scan History (Screen 4)

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

### Screen 5: Scan Error
- **Purpose:** Handle failed identification attempts
- **Key Elements:**
  - Error icon
  - Message: "Couldn't find a match"
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

#### Networking & Image Handling
- **HTTP Client:** URLSession (native iOS)
- **Image Caching:** NSCache for in-memory caching + FileManager for persistent disk cache
- **Image Loading:** SwiftUI AsyncImage with custom caching layer
- **Async/Await:** Modern Swift concurrency for sequential API calls
- **Image Formats:** JPEG (primary), PNG (fallback)

---

## API INTEGRATION

### Anthropic Claude API
- **Purpose:** Album identification via computer vision + cultural context generation
- **Capabilities Used:**
  - Vision API: Analyze album cover photos
  - Text Generation: Create cultural context, ratings, recommendations
  - Web Search: Research current album information (via Claude's built-in tools)
- **API Calls Per Scan:**
  - Single API call that combines vision + text generation
  - Estimated cost: ~$0.10-0.30 per scan (depending on response length)
- **Authentication:** API key (stored securely, not hardcoded)
- **Rate Limits:** Monitor and implement retry logic
- **Caching Strategy:** Cache full responses locally to avoid redundant API calls for same album

### Expected JSON Response Structure
```json
{
  "album_title": "string",
  "artist_name": "string",
  "release_year": "string",
  "genres": ["string"],
  "record_label": "string",
  "context_summary": "string (2-3 sentences)",
  "context_bullets": ["string (3-5 bullets)"],
  "rating": number (0-10),
  "recommendation": "ESSENTIAL|RECOMMENDED|SKIP|AVOID",
  "key_tracks": ["string"],
  "album_art_url": "string (optional)"
}
```
### MusicBrainz API
- **Purpose:** Search for album releases and retrieve MusicBrainz IDs (MBIDs)
- **Endpoint:** `https://musicbrainz.org/ws/2/release`
- **Authentication:** None required (open API)
- **Rate Limiting:** 1 request per second (implement with delay if needed)
- **User Agent Required:** Must include custom User-Agent header with app name and contact email
  - Format: `AppName/1.0 (contact@email.com)`
- **Query Parameters:**
  - `query`: Lucene-style search query combining artist and album
  - `fmt`: Response format (use `json`)
  - `limit`: Number of results (use `5` to handle multiple variants)
- **Search Strategy:**
  - Primary search: `artist:{artist_name} AND release:{album_title}`
  - If no results: Try fuzzy search with `artist:{artist_name} release:{album_title}~`
  - Select first result with matching artist name (case-insensitive)
- **Response Contains:** Release MBID, release title, artist credit, date, country
- **Caching:** Cache MBIDs with album metadata to avoid repeat searches

**Example Request:**
```
GET https://musicbrainz.org/ws/2/release?query=artist:Radiohead%20AND%20release:OK%20Computer&fmt=json&limit=5
```

### Cover Art Archive API
- **Purpose:** Retrieve high-resolution album artwork using MusicBrainz release ID
- **Endpoint:** `https://coverartarchive.org/release/{mbid}`
- **Authentication:** None required (open API)
- **Rate Limiting:** No strict limits, but respect reasonable use
- **Image Selection Priority:**
  1. `front` image (primary album cover)
  2. First available image if no front designation
  3. Prefer larger images (check `thumbnails` object for sizes)
- **Response Contains:** Array of images with URLs, types, and thumbnail variants
- **Image Sizes Available:**
  - `small`: 250px
  - `large`: 500px  
  - `original`: Full resolution (often 1000-1500px)
- **Download Strategy:** 
  - Download `large` (500px) for detail view
  - Generate thumbnail (200x200) from large image for history list
  - Store both in local cache
- **404 Handling:** Common for obscure releases - gracefully fall back to placeholder

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

### API Call Sequence for Album Identification
1. **Claude Vision API** (3-5 seconds)
   - Send album cover photo
   - Receive: Album metadata + cultural context
   
2. **MusicBrainz Search API** (0.5-1 second)
   - Query: artist name + album title from Claude response
   - Receive: Release MBID
   
3. **Cover Art Archive API** (0.5-1 second)
   - Query: Release MBID
   - Receive: Artwork URLs
   
4. **Image Download** (0.5-1 second)
   - Download large (500px) image
   - Generate thumbnail (200px)
   - Cache both locally

**Total Time:** 5-8 seconds from scan to full display

### Recommendation Emojis (Hardcoded in App)
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
  id: UUID (primary key)
  albumTitle: String
  artistName: String
  releaseYear: String?
  genres: [String]
  recordLabel: String?
  
  // Cultural Context (from Claude API)
  contextSummary: String // 2-3 sentence opening
  contextBulletPoints: [String] // 3-5 bullets
  rating: Double // 0-10
  recommendation: String // ESSENTIAL/RECOMMENDED/SKIP/AVOID
  keyTracks: [String]
  
  // Album Art (MusicBrainz + Cover Art Archive)
  musicbrainzID: String? // MBID for future reference
  albumArtURL: String? // Cover Art Archive URL (large/500px)
  albumArtThumbnailData: Data? // Cached 200x200 JPEG for history
  albumArtHighResData: Data? // Cached 500px JPEG for detail view
  albumArtRetrievalFailed: Bool // Track if artwork lookup failed
  
  // Metadata
  scannedDate: Date
  lastViewedDate: Date?
  
  // Raw API Response (optional, for debugging)
  rawAPIResponse: String?
}
```

### Storage Strategy
- **Auto-save:** Every scan immediately persists to CoreData
- **Duplicates Allowed:** No duplicate detection - every scan creates new entry
- **User Management:** Users delete duplicates manually via swipe-to-delete
- **Album Art Caching:** 
  - Thumbnail (~200x200 JPEG) for history list
  - High-res (original size JPEG) for detail view
  - Both stored as Data in CoreData for offline access
- **Offline Access:** All scanned albums viewable without internet
- **No Size Limit:** Unlimited storage (phone storage is constraint)

---

## CAMERA IMPLEMENTATION

### AVFoundation Framework
- **Camera Access:** AVCaptureSession for live camera feed
- **Photo Capture:** JPEG capture on SCAN button tap
- **Permissions:** Request camera access on first launch
- **No Photo Library:** Direct camera only (no picking from library in MVP)

### Camera Settings
- **Live Feed:** Camera activates immediately when Screen 1 loads
- **Orientation:** Locked to portrait mode only
- **Performance:** Prioritize speed - minimal processing
- **Capture Settings:**
  - Resolution: 1024x1024 (square, optimized for album covers)
  - Format: JPEG compressed to 1-2MB
  - Quality: Balanced (fast upload, sufficient detail for identification)
- **Square Framing Guide:** Overlay guide to help users center album cover

### Image Pipeline
```
User taps SCAN → Capture at 1024x1024 → Compress to JPEG (1-2MB) → Send to API
```

---

## UI/UX REQUIREMENTS

### Design System
- **Follow iOS Guidelines:** Use native iOS patterns and components
- **SF Symbols:** Use Apple's icon library (clock icon for history, etc.)
- **Dark Mode:** Support system dark mode (iOS handles automatically with SwiftUI)
- **Dynamic Type:** Support accessibility text sizing
- **Haptic Feedback:** Subtle haptics on button taps and actions

### Performance Targets
- **App Launch:** < 2 seconds to Camera View
- **API Response:** Display results within 3-5 seconds of scan
- **Screen Transitions:** 60fps, smooth animations
- **History Scrolling:** Smooth scrolling even with 100+ albums
- **Offline Access:** History loads instantly from cache

### Accessibility
- **VoiceOver:** All interactive elements properly labeled
- **Dynamic Type:** Text scales with system settings
- **Color Contrast:** Sufficient contrast ratios (WCAG AA minimum)
- **Tap Targets:** Minimum 44x44pt for all interactive elements

---

## ERROR HANDLING

### Critical Error Scenarios

1. **No Internet Connection**
   - Detect before API call if possible
   - Show user-friendly error message
   - Offer retry button
   - Route to Scan Error Screen (Screen 5)
   
2. **API Failure**
   - Timeout (10 seconds)
   - Invalid response
   - Rate limit hit
   - All route to Scan Error Screen (Screen 5)
   
3. **Camera Issues**
   - Permission denied → Permission Error Screen
   - Hardware failure → Error message with troubleshooting
   - Poor lighting → May affect identification quality (acceptable for MVP)
   
4. **Storage Issues**
   - Disk full → Graceful handling (unlikely with album metadata)
   - CoreData failure → Alert user, offer to retry
   
5. **Album Not Identified**
   - Claude can't identify album → "Couldn't find a match"
   - Route to Scan Error Screen (Screen 5)
   - Single "TRY AGAIN" action for all error types

6. **Album Artwork Retrieval Failures**
   - MusicBrainz search returns no results → Use placeholder, continue display
   - Cover Art Archive returns 404 → Use placeholder, continue display
   - Network timeout during artwork download → Use placeholder, continue display
   - Image download fails or corrupted → Use placeholder, continue display
   - **Important:** All artwork failures are non-blocking - album information always displays
   - Consider retry logic: If artwork fails, store flag and allow manual refresh in future

### Networking
- **Framework:** URLSession (native iOS)
- **Timeout:** 10 seconds
- **Retry Logic:** Single auto-retry on transient failures, then show error
- **HTTPS Only:** All API calls over secure connection

---

## TESTING STRATEGY

### Unit Tests
- CoreData operations (save, fetch, delete)
- API response parsing
- Data model validation
- Caching logic

### Integration Tests
- Camera capture → API call → Parse response → Save to CoreData
- Navigation flows
- Error handling paths
- MusicBrainz search → Parse MBID → Cover Art Archive query → Image download → Cache storage
- Test artwork retrieval with popular albums (high success rate)
- Test artwork retrieval with obscure albums (expect some failures)
- Test placeholder display when artwork unavailable
- Test offline behavior (cached artwork displays, non-cached shows placeholder)

### Manual Testing
- **Critical:** Test at actual record stores with real albums
- Test various lighting conditions
- Test obscure vs popular albums
- Test error scenarios (airplane mode, denied permissions)
- Test on multiple iPhone models if possible
- Test artwork quality on various iPhone screen sizes
- Test artwork loading speed on slow network connections
- Test albums with multiple releases (ensure correct variant selected)
- Test non-English album titles and artist names
- Test albums known to be missing from Cover Art Archive

### Test Data
- Maintain a list of known albums for testing
- Include edge cases: damaged covers, partial covers, bootlegs
- Test albums with controversial artists (ensure unbiased assessment)

---

## SECURITY & PRIVACY

### API Key Management
- **NEVER hardcode API keys in source code**
- **Store in:** Xcode build configuration or secure environment variables
- **Git:** Add API keys to .gitignore

### Data Privacy
- **No Analytics:** No tracking or analytics in MVP
- **No External Data Sharing:** Album scan data stays on device
- **Camera Access:** Only used when explicitly triggered by user
- **Privacy Policy:** Required before App Store submission
  - Explain camera usage
  - Explain API data transmission (image sent to Anthropic)
  - Explain local storage only

---

## COST ESTIMATES

### Monthly Costs (Hobby Use)
- **Anthropic Claude API:** ~$10-30/month (50-100 scans)
- **Apple Developer Program:** $99/year (~$8/month)
- **Total:** ~$18-38/month

### Mitigation
- Implement aggressive caching
- Set spending alerts with Anthropic
- Monitor usage weekly

---

## OUT OF SCOPE (MVP)

**Explicitly NOT in v1.0:**
- ❌ Spotify playback integration (deferred to v2.0)
- ❌ Manual search functionality
- ❌ Cloud sync / iCloud
- ❌ iPad support
- ❌ Social sharing features
- ❌ Export functionality
- ❌ Multiple language support
- ❌ Comprehensive crash reporting

---

## IMPLEMENTATION NOTES

### Artwork Retrieval Priority
- Speed is critical: Users should see album info + artwork within 5-8 seconds total
- Artwork retrieval happens in parallel with UI rendering of text content
- Never block album information display waiting for artwork
- Implement aggressive timeout (5 seconds max for entire artwork retrieval process)

### Caching Strategy
- **Memory Cache:** NSCache holds recently viewed artwork (limit to 20-30 images)
- **Disk Cache:** FileManager stores all downloaded artwork permanently
- **Cache Key:** Use MBID or fallback to "{artist}_{album_title}" hash
- **Cache Invalidation:** No automatic expiration (artwork doesn't change)

### User-Agent Header (REQUIRED)
MusicBrainz requires a proper User-Agent or requests may be blocked:
```
User-Agent: VinylID/1.0 (james@jamesschaffer.com)
```

### Rate Limiting Compliance
- MusicBrainz: Maximum 1 request per second
- Implement 1-second delay between searches if needed
- Cover Art Archive: No strict limits, but don't hammer the API
- Consider implementing exponential backoff for retries

### Placeholder Artwork Design
- Neutral gray background (#E5E5E5 for light mode, #2C2C2C for dark mode)
- Centered text: "Album art unavailable"
- Match aspect ratio of album covers (1:1 square)
- Subtle icon (optional): music note or vinyl record symbol

## DEVELOPMENT NOTES

### Prompt Management
The Claude API prompt will be maintained as a separate versioned artifact. This allows:
- Independent iteration on prompt quality
- Version control separate from code
- Easy testing of prompt variations
- Clear separation of concerns (product vs engineering)

### Key Navigation Rules
- History icon (clock symbol) only appears after first successful scan
- All scans automatically save to history (including duplicates)
- Single "X" button returns to previous screen
- Single "TRY AGAIN" action for all error types (keep it simple)
- Camera View is the default home screen

### Design Philosophy
- **Speed over perfection:** Get users scanning quickly
- **Simple over complex:** MVP is intentionally minimal
- **Offline-first:** History works without internet
- **Music-focused:** NEVER mention prices or collectibility

---

**Document Version:** 1.1  
**Last Updated:** October 20, 2025  
**Status:** Ready for development  
**Next Steps:** Fix album artwork
