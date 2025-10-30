## USER FLOWS

### Flow 1: First-Time User Onboarding
```
Launch App (First Time) → Welcome Screen → Camera Permission Request → Camera View
```

### Flow 2: Primary Use Case - Album Scan & Musical Discovery (Two-Tier Identification)
```
Launch App → Camera View
  → Tap "SCAN" Button
  → Loading Screen 1: "Flipping through every record bin in existence..."
     (Runs ID Call 1: Single-prompt identification, 2-4 sec)
     (If search needed: Runs ID Call 2 with search gate validation, 3-5 sec)
     (After identification succeeds: Artwork retrieval, 1-2 sec)
  → Loading Screen 2: Shows album artwork + "We found {Album Title} by {Artist Name}"
     (2-second confirmation hold)
  → Loading Screen 3: "Writing a review that's somehow both pretentious and correct..."
     (Runs Review Generation with cache check, 3-5 sec or instant if cached)
  → Album Details Screen (Full review display)
  → Auto-saved to History
  → Tap "X" → Camera View
```

**Timing:** 8-13 seconds for new album with search, 5-7 seconds without search, instant for cached reviews

### Flow 3: Album Scan - Identification Failed
```
Launch App → Camera View
  → Tap "SCAN" Button
  → Loading Screen 1: "Flipping through every record bin in existence..."
     (ID Call 1 returns unresolved OR search gate blocks ID Call 2)
  → Error Banner slides down from top: "Unable to identify this cover art"
     (Auto-dismisses after 3 seconds)
  → Camera View (returns to idle, ready for next scan)
```

**Note:** Error banner uses spring animation, does not block camera view, no user interaction required

### Flow 4: Album Scan - Review Generation Failed
```
Launch App → Camera View
  → Tap "SCAN" Button
  → Loading Screen 1: "Flipping through every record bin in existence..."
     (Identification succeeds)
  → Loading Screen 2: Shows album artwork + "We found {Album Title} by {Artist Name}"
     (2-second confirmation)
  → Loading Screen 3: "Writing a review that's somehow both pretentious and correct..."
     (Review generation fails)
  → Album Details Screen with basic metadata + artwork + error message
     - Shows: "Review Temporarily Unavailable" with explanation
  → User must close details and rescan album to retry (no inline retry button)
```

### Flow 5: Review Scan History
```
Launch App → Camera View → Tap History Icon 
  → Scan History Screen 
  → Tap Album → Album Details Screen 
  → Tap "X" → Scan History Screen
```

### Flow 6: Return to Camera from History View
```
Scan History Screen → Tap Camera Icon Button (bottom right) → Camera View
  → Tap "SCAN" Button → [Follow Flow 2]
```

**Note:** Camera button is a circular button with green border containing camera icon, positioned bottom right

### Flow 7: Delete Album from History
```
Scan History Screen → Swipe Left on Album → Tap Red Trash Icon → Album Removed from List
```

**Alternative:** Full swipe left (without tapping) immediately deletes album

### Flow 8: Re-scan Existing Album (Duplicate Allowed)
```
Camera View → Tap "SCAN" Button → [Follow Flow 2]
```
**Note:** All scans are saved to history, including duplicates. Users manage duplicates by swiping to delete. Review generation uses cache if album was scanned before (instant display, $0 cost).

### Flow 9: Camera Permission Denied
```
Launch App (First Time) → Welcome Screen → Camera Permission Request → User Denies
  → Permission Error Screen → "Open Settings" Button → iOS Settings
  → User Grants Permission → Return to App → Camera View
```

### Flow 10: Access Settings and Toggle AlbumScan Ultra
```
Camera View → Tap Settings Button (gear icon, bottom-left)
  → Settings Screen (sheet presentation, 460pt height)
  → View AlbumScan Ultra benefits card
  → Toggle "Enable Advanced Search" ON/OFF
    - Toggle ON: Reviews use gpt-4o-search-preview with source prioritization (~$0.08-0.13/review)
    - Toggle OFF: Reviews use gpt-4o with no search (~$0.05-0.10/review)
  → State persists to UserDefaults
  → Swipe down or tap outside sheet to dismiss
  → Returns to Camera View
```

**Note:** Toggle change affects future scans immediately - cached reviews remain unaffected

---

## Verification Summary

**Document Accuracy:** This document has been verified against the actual codebase implementation as of October 30, 2025.

**Files Verified:**
- `CameraManager.swift` (identification flow, timing, error handling, Ultra search bypass)
- `CameraView.swift` (error banner implementation, UI buttons, settings button)
- `SettingsView.swift` (Ultra benefits card, toggle, sheet presentation)
- `AppState.swift` (searchEnabled state management)
- `LoadingView.swift` (loading state messages and transitions)
- `AlbumDetailsView.swift` (review failure handling, no retry button)
- `ScanHistoryView.swift` (history list, swipe-to-delete, camera button)
- `ContentView.swift` (app routing, first launch, permission handling)
- `WelcomeView.swift` (onboarding screen)
- `PermissionErrorView.swift` (camera permission denied screen)
- `ScanState.swift` (state machine validation)

**Major Corrections Made:**
1. **Architecture Update**: Changed from "Four-Phase" to "Two-Tier Identification System"
2. **New Flow Added (October 30, 2025)**: Flow 10 - Access Settings and Toggle AlbumScan Ultra
3. **Error Handling**: Corrected Flow 3 to describe error banner (not full-screen error view)
4. **Review Retry**: Removed non-existent "Retry Review" button from Flow 4
5. **Button Labels**: Corrected Flow 6 to describe camera icon button (not "SCAN" button)
6. **Timing Estimates**: Updated with accurate timing from actual implementation
7. **Cache Behavior**: Added note about instant cached review display in Flow 8

**Evidence-Based Changes:**
- Error banner slides down from top, auto-dismisses after 3 seconds (spring animation)
- Loading screens show three distinct states with specific messages
- Review failure shows suggestion message only, no interactive retry button
- History view has camera icon button (circular, green border, bottom right)
- Swipe-to-delete supports full swipe for immediate deletion
- Settings button (gear icon) added to camera view (bottom-left)
- Ultra toggle affects future scans, not cached reviews

**No Implementation Found:**
- `ScanErrorView.swift` exists in codebase but is NOT used in actual flow
- Full-screen error view with "TRY AGAIN" button is not part of current implementation