# AlbumScan File Structure

Complete file structure for the AlbumScan iOS project.

**Last Updated:** December 7, 2025
**Version:** 1.6 (Firebase Cloud Functions + App Check)

```
AlbumScan/
├── .gitignore                                    ✅ Git ignore file
├── README.md                                     ✅ Project overview
├── SETUP_GUIDE.md                               ✅ Xcode setup instructions
├── QUICK_START.md                               ✅ Quick start checklist
├── CLOUD_FUNCTIONS_SETUP.md                     ✅ Firebase deployment guide
├── FILE_STRUCTURE.md                            ✅ This file
├── PRIVACY_POLICY.md                            ✅ Privacy policy (markdown)
├── firebase.json                                ✅ Firebase project config
├── GoogleService-Info.plist                     ✅ Firebase iOS config
│
├── Project_Context/                             ✅ Complete specification (11 files)
│   ├── 00_project_context.md                   ✅ Table of contents + version history
│   ├── 01_summary.md                           ✅ Project overview
│   ├── 02_user_personas.md                     ✅ Target users
│   ├── 03_core_features.md                     ✅ Feature specs
│   ├── 04_user_flows.md                        ✅ User journeys
│   ├── 05_screen_architecture.md               ✅ Screen specs
│   ├── 06_apis.md                              ✅ Two-tier API architecture
│   ├── 07_ux.md                                ✅ UX principles
│   ├── 08_qa.md                                ✅ Testing strategy
│   ├── 09_security_privacy.md                  ✅ Security & privacy
│   └── 10_prompt_management.md                 ✅ Prompt engineering
│
├── functions/                                   ✅ Firebase Cloud Functions
│   ├── src/
│   │   └── index.ts                            ✅ Cloud Functions (TypeScript)
│   ├── lib/                                    ✅ Compiled JavaScript
│   ├── package.json                            ✅ Node dependencies
│   ├── tsconfig.json                           ✅ TypeScript config
│   └── .eslintrc.js                            ✅ ESLint config
│
├── website/                                     ✅ Marketing website
│   ├── index.html                              ✅ Landing page
│   ├── privacy.html                            ✅ Privacy policy page
│   ├── terms.html                              ✅ Terms of service page
│   ├── styles.css                              ✅ Website styles
│   └── assets/                                 ✅ Marketing images
│
├── docs/                                        ✅ Legal documentation (HTML)
│   ├── privacy-policy.html                     ✅ Privacy policy
│   ├── terms-of-service.html                   ✅ Terms of service
│   └── support.html                            ✅ Support page
│
└── AlbumScan/                                   # Main Xcode project folder
    ├── AlbumScan.xcodeproj/                    ✅ Xcode project file
    └── AlbumScan/                               # App source code
        ├── AlbumScanApp.swift                   ✅ App entry point (Firebase, App Check init)
        ├── ContentView.swift                    ✅ Root view coordinator
        ├── Info.plist                           ✅ App configuration
        ├── Secrets.plist                        ⚠️ API keys (gitignored, dev only)
        │
        ├── Views/                               # All SwiftUI views
        │   ├── Camera/
        │   │   ├── CameraView.swift             ✅ Main camera screen
        │   │   └── CameraPreview.swift          ✅ Camera feed display
        │   ├── Album/
        │   │   └── AlbumDetailsView.swift       ✅ Album info display
        │   ├── History/
        │   │   └── ScanHistoryView.swift        ✅ Scan history list
        │   ├── Subscription/
        │   │   ├── WelcomePurchaseSheet.swift   ✅ First-launch subscription prompt
        │   │   └── ChooseYourPlanView.swift     ✅ Plan selection screen
        │   ├── Error/
        │   │   ├── PermissionErrorView.swift    ✅ Camera permission error
        │   │   └── ScanErrorView.swift          ⚠️ Legacy (not used)
        │   ├── LoadingView.swift                ✅ Four-stage loading screens
        │   ├── SettingsView.swift               ✅ Settings with Ultra toggle
        │   └── LaunchScreenView.swift           ✅ Launch screen
        │
        ├── ViewModels/                          # State management
        │   ├── AppState.swift                   ✅ App-level state + searchEnabled toggle
        │   └── CameraManager.swift              ✅ Camera + API orchestration
        │
        ├── Models/                              # Data models
        │   ├── Album.swift                      ✅ CoreData entity
        │   ├── AlbumResponse.swift              ✅ API response models
        │   ├── Phase1AResponse.swift            ✅ Legacy Claude response
        │   ├── Phase1Response.swift             ✅ Legacy phase response
        │   ├── Phase2Response.swift             ✅ Review response model
        │   ├── SinglePromptResponses.swift      ✅ OpenAI response models
        │   ├── ScanState.swift                  ✅ State machine enum
        │   └── AlbumScan.xcdatamodeld/
        │       └── AlbumScan.xcdatamodel/
        │           └── contents                 ✅ CoreData schema
        │
        ├── Services/                            # Business logic
        │   ├── CloudFunctionsService.swift      ✅ Firebase callable functions (DEFAULT)
        │   ├── OpenAIAPIService.swift           ✅ Direct OpenAI API (dev fallback)
        │   ├── ClaudeAPIService.swift           ✅ Legacy Claude API (backup)
        │   ├── LLMService.swift                 ✅ Protocol definition
        │   ├── LLMServiceFactory.swift          ✅ Service provider factory
        │   ├── MusicBrainzService.swift         ✅ Album metadata lookup
        │   ├── CoverArtService.swift            ✅ Cover art retrieval
        │   ├── PersistenceController.swift      ✅ CoreData management
        │   ├── SubscriptionManager.swift        ✅ StoreKit 2 subscriptions
        │   ├── ScanLimitManager.swift           ✅ Free scan tracking
        │   └── RemoteConfigManager.swift        ✅ Firebase Remote Config
        │
        ├── Utilities/                           # Helper code
        │   ├── Config.swift                     ✅ Configuration + provider selection
        │   └── KeychainHelper.swift             ✅ Secure storage
        │
        ├── Prompts/                             # AI prompt files
        │   ├── single_prompt_identification.txt ✅ ID Call 1 prompt
        │   ├── search_finalization.txt          ✅ ID Call 2 prompt
        │   ├── album_review.txt                 ✅ Review prompt (Free tier)
        │   ├── album_review_ultra.txt           ✅ Review prompt (Ultra tier)
        │   └── Archive/
        │       └── Claude/
        │           ├── phase1a_vision_extraction.txt  ✅ Legacy
        │           └── phase1b_web_search_mapping.txt ✅ Legacy
        │
        └── Resources/                           # Assets
            └── Assets.xcassets                  ✅ App icons, colors

    ├── AlbumScanTests/                          # Unit tests (empty)
    └── AlbumScanUITests/                        # UI tests (empty)
```

## File Purposes

### Core App Files

- **AlbumScanApp.swift**: SwiftUI app entry point, initializes Firebase, App Check, subscription manager
- **ContentView.swift**: Root view that routes to Camera/Error screens
- **Info.plist**: Camera permission description and app settings

### Views (See Project_Context/05_screen_architecture.md)

- **CameraView.swift**: Main camera screen with framing guide and SCAN button
- **CameraPreview.swift**: AVFoundation camera preview wrapper
- **LoadingView.swift**: Four-stage loading screens with progressive disclosure
  - Stage 1a (0-3.5s): "Extracting text and examining album art..."
  - Stage 1b (3.5s+): "Flipping through every record bin in existence..."
  - Stage 2 (confirmation): "We found [Album] by [Artist]" with artwork
  - Stage 3: "Writing a review that's somehow both pretentious and correct..."
- **AlbumDetailsView.swift**: Album information display with 8-tier recommendations
- **ScanHistoryView.swift**: Chronological list of scanned albums (newest first)
- **SettingsView.swift**: Settings screen with Advanced Search toggle for Ultra subscribers
- **LaunchScreenView.swift**: App launch screen
- **WelcomePurchaseSheet.swift**: First-launch subscription prompt
- **ChooseYourPlanView.swift**: Plan selection screen (Free/Base/Ultra)
- **PermissionErrorView.swift**: Camera permission denial handling
- **ScanErrorView.swift**: ⚠️ Legacy file (not used - error banner pattern instead)

### ViewModels

- **AppState.swift**: App-level state (first launch, permissions, searchEnabled toggle)
- **CameraManager.swift**: Orchestrates camera session, photo capture, two-tier identification, and review generation

### Models

- **Album.swift**: CoreData entity for saved albums with computed properties
- **AlbumResponse.swift**: Codable structs for API JSON responses
- **Phase1AResponse.swift**: Legacy Claude response model
- **Phase1Response.swift**: Legacy phase response model
- **Phase2Response.swift**: Review response model
- **SinglePromptResponses.swift**: OpenAI identification response models
- **ScanState.swift**: State machine enum (idle, identifying, identified, loadingReview, complete, errors)
- **AlbumScan.xcdatamodeld**: CoreData schema definition

### Services

- **CloudFunctionsService.swift**: DEFAULT provider - Firebase callable functions (secure, server-side API keys)
- **OpenAIAPIService.swift**: Development fallback - direct OpenAI API calls
- **ClaudeAPIService.swift**: Legacy backup - Anthropic Claude API
- **LLMService.swift**: Protocol defining API service interface
- **LLMServiceFactory.swift**: Factory for swapping between providers based on Config.currentProvider
- **MusicBrainzService.swift**: Album metadata lookup for MBID retrieval
- **CoverArtService.swift**: Cover art retrieval from Cover Art Archive
- **PersistenceController.swift**: CoreData operations (save, fetch, delete, cache)
- **SubscriptionManager.swift**: StoreKit 2 subscription management (Base + Ultra tiers)
- **ScanLimitManager.swift**: Free scan tracking (5 scans) with Keychain persistence
- **RemoteConfigManager.swift**: Firebase Remote Config for feature flags

### Utilities

- **Config.swift**: Configuration (API keys, provider selection: `.cloudFunctions` default)
- **KeychainHelper.swift**: Secure storage for subscription state and scan count backup

## Next Steps

1. **Open SETUP_GUIDE.md** for Xcode setup instructions
2. **Review Project_Context/** for complete specification (11 documents)
3. **Deploy Cloud Functions** - follow CLOUD_FUNCTIONS_SETUP.md
4. **Build and test** on iOS device (camera required)

## Key Features Implemented

✅ Complete screen architecture (10+ screens including 4-stage loading)
✅ Firebase Cloud Functions backend (secure API proxy)
✅ Firebase App Check with App Attest (device attestation)
✅ StoreKit 2 subscription system (Free/Base/Ultra tiers)
✅ CoreData persistence with aggressive review caching (70-80% hit rate)
✅ Camera capture with AVFoundation and framing guide overlay
✅ Two-tier identification system (ID Call 1 + conditional ID Call 2)
✅ Rate limiting (10 requests/minute/device)
✅ Swipe-to-delete history management
✅ 8-tier recommendation label system
✅ Error banner pattern (3-second auto-dismiss, non-blocking)
✅ Offline access to cached scan history
✅ Search gate validation (prevents wasteful API calls)
✅ Cost optimization: $0.10/day for 100 scans (98% reduction achieved)

## Architecture Highlights

**MVVM Pattern**:
- Views: SwiftUI view files
- ViewModels: AppState, CameraManager
- Models: Album, ScanState, Response models

**API Architecture (Three Providers)**:
1. **CloudFunctionsService** (DEFAULT): Secure Firebase callable functions
2. **OpenAIAPIService**: Direct API calls (development fallback)
3. **ClaudeAPIService**: Legacy backup provider

**Two-Tier Identification Flow**:
1. User taps SCAN → CameraManager captures photo
2. CameraManager → CloudFunctionsService → `identifyAlbum` function
3. If searchNeeded + passes search gate → `searchFinalizeAlbum` function
4. After identification → Artwork retrieval (MusicBrainz + Cover Art Archive)
5. Cache check → If miss: `generateReview` function
6. Response → PersistenceController → CoreData
7. CoreData → SwiftUI views (via @FetchRequest or @Published)

**Navigation Flow**:
```
Camera → Loading 1a/1b → Loading 2 (Confirmed) → Loading 3 (Review) → Album Details
    ↓ (error)
Error Banner (3s auto-dismiss) → Camera (ready to retry)
```

**Security Flow**:
```
iOS App → App Check Token → Cloud Functions → Firebase Secrets → OpenAI API
```

## Code Quality Notes

- All views follow SwiftUI best practices
- Proper error handling throughout
- Type-safe models with Codable
- CoreData with computed properties for arrays
- Async/await for API calls
- MVVM separation of concerns
- Protocol-based service abstraction

---

**Status**: ✅ Production iOS app published on App Store

**Current Implementation**: Firebase Cloud Functions (secure proxy to OpenAI) with 98% cost reduction

**API Provider**: `.cloudFunctions` (configurable in Config.swift)
