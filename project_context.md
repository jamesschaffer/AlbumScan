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
  - High-res album artwork (or "Album art unavailable" placeholder)
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
  
  // Album Art
  albumArtData: Data? // cached thumbnail
  albumArtURL: String? // high-res reference
  
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

### Manual Testing
- **Critical:** Test at actual record stores with real albums
- Test various lighting conditions
- Test obscure vs popular albums
- Test error scenarios (airplane mode, denied permissions)
- Test on multiple iPhone models if possible

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

**Document Version:** 1.0  
**Last Updated:** October 19, 2025  
**Status:** Ready for development  
**Next Steps:** Begin Phase 1 - Swift/SwiftUI learning and environment setup
