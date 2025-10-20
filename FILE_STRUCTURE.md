# AlbumScan File Structure

Complete file structure created for the AlbumScan iOS project.

```
AlbumScan/
├── .gitignore                                    ✅ Git ignore file
├── README.md                                     ✅ Project overview
├── SETUP_GUIDE.md                               ✅ Xcode setup instructions
├── PROJECT_CONTEXT.md                           ✅ Complete specification
├── FILE_STRUCTURE.md                            ✅ This file
│
└── AlbumScan/                                   # Main project folder
    └── AlbumScan/                               # App source code
        ├── AlbumScanApp.swift                   ✅ App entry point
        ├── ContentView.swift                    ✅ Root coordinator
        ├── Info.plist                           ✅ App configuration
        │
        ├── Views/                               # All SwiftUI views
        │   ├── Camera/
        │   │   ├── CameraView.swift             ✅ Main camera screen
        │   │   ├── CameraPreview.swift          ✅ Camera feed display
        │   │   └── SearchPreLoaderView.swift    ✅ Loading spinner
        │   ├── Album/
        │   │   └── AlbumDetailsView.swift       ✅ Album info display
        │   ├── History/
        │   │   └── ScanHistoryView.swift        ✅ Scan history list
        │   ├── Welcome/
        │   │   └── WelcomeView.swift            ✅ First-time welcome
        │   └── Error/
        │       ├── PermissionErrorView.swift    ✅ Camera permission error
        │       └── ScanErrorView.swift          ✅ Scan failure error
        │
        ├── ViewModels/                          # State management
        │   ├── AppState.swift                   ✅ App-level state
        │   └── CameraManager.swift              ✅ Camera operations
        │
        ├── Models/                              # Data models
        │   ├── Album.swift                      ✅ CoreData entity
        │   ├── AlbumResponse.swift              ✅ API response model
        │   └── AlbumScan.xcdatamodeld/
        │       └── AlbumScan.xcdatamodel/
        │           └── contents                 ✅ CoreData schema
        │
        ├── Services/                            # Business logic
        │   ├── ClaudeAPIService.swift           ✅ API integration
        │   └── PersistenceController.swift      ✅ CoreData management
        │
        ├── Utilities/                           # Helper code
        │   └── Config.swift                     ✅ App configuration
        │
        └── Resources/                           # Assets (empty for now)

    ├── AlbumScanTests/                          # Unit tests
    └── AlbumScanUITests/                        # UI tests
```

## File Purposes

### Core App Files

- **AlbumScanApp.swift**: SwiftUI app entry point, configures CoreData
- **ContentView.swift**: Root view that routes to Welcome/Camera/Error screens
- **Info.plist**: Camera permission description and app settings

### Views (Screen 1-5 from PROJECT_CONTEXT.md)

- **WelcomeView.swift**: First-time onboarding screen
- **CameraView.swift**: Main camera screen with scan button (Screen 1)
- **CameraPreview.swift**: AVFoundation camera preview wrapper
- **SearchPreLoaderView.swift**: Loading state during API call (Screen 2)
- **AlbumDetailsView.swift**: Album information display (Screen 3)
- **ScanHistoryView.swift**: List of scanned albums (Screen 4)
- **ScanErrorView.swift**: Error handling for failed scans (Screen 5)
- **PermissionErrorView.swift**: Camera permission denial handling

### ViewModels

- **AppState.swift**: Manages app-level state (first launch, permissions, etc.)
- **CameraManager.swift**: Handles camera session, photo capture, and API calls

### Models

- **Album.swift**: CoreData entity for saved albums with computed properties
- **AlbumResponse.swift**: Codable struct for API JSON response
- **AlbumScan.xcdatamodeld**: CoreData schema definition

### Services

- **ClaudeAPIService.swift**: Handles all Anthropic Claude API communication
- **PersistenceController.swift**: Manages CoreData operations (save, fetch, delete)

### Utilities

- **Config.swift**: Centralized configuration (API keys, constants, settings)

## Next Steps

1. **Open SETUP_GUIDE.md** for Xcode project creation instructions
2. **Create Xcode project** following the guide
3. **Add all source files** to the Xcode project
4. **Configure API key** using environment variables
5. **Build and test** on a physical iOS device

## Key Features Implemented

✅ Complete MVP screen architecture (7 screens)
✅ CoreData persistence with Album entity
✅ Camera capture with AVFoundation
✅ Claude API integration for album identification
✅ Swipe-to-delete history management
✅ Recommendation badge system (ESSENTIAL/RECOMMENDED/SKIP/AVOID)
✅ Error handling (permissions, network, API failures)
✅ Offline access to scan history

## Missing Components (To Add in Xcode)

These will be added when you create the Xcode project:
- Assets.xcassets (app icons, colors)
- Preview Content
- Xcode project file (.xcodeproj)
- Build configurations
- Signing certificates

## Architecture Highlights

**MVVM Pattern**:
- Views: SwiftUI view files
- ViewModels: AppState, CameraManager
- Models: Album, AlbumResponse

**Data Flow**:
1. User taps SCAN → CameraManager captures photo
2. CameraManager → ClaudeAPIService → API call
3. API response → PersistenceController → CoreData
4. CoreData → SwiftUI views (via @FetchRequest)

**Navigation Flow**:
```
Welcome → Camera → (Loading) → Album Details → History
                ↓ (error)
              Error → Retry
```

## Code Quality Notes

- All views follow SwiftUI best practices
- Proper error handling throughout
- Type-safe models with Codable
- CoreData with computed properties for arrays
- Async/await for API calls
- MVVM separation of concerns

---

**Status**: ✅ All starter files created and ready for Xcode integration

**Next**: Follow SETUP_GUIDE.md to create the Xcode project and add these files.
