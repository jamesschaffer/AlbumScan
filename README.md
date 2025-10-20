# AlbumScan

A music discovery companion that reveals the cultural significance and artistic merit of albums through photo identification.

## Overview

AlbumScan is an iOS app that helps music collectors identify albums and understand their cultural significance. When browsing record stores, users can take a photo of an album cover to instantly learn about its musical importance, influence, and artistic merit.

**This app focuses on artistry and cultural value, NOT pricing or collectibility.**

## Features (MVP v1.0)

- **Camera-Based Album Identification**: Take a photo of any album cover for instant AI-powered identification
- **Cultural Context**: Get expert analysis on why an album matters musically
- **Honest Recommendations**: See clear ratings (ESSENTIAL/RECOMMENDED/SKIP/AVOID)
- **Scan History**: Review all previously scanned albums with offline access
- **Key Information**: View release details, genres, key tracks, and critical reception

## Technical Stack

- **Platform**: iOS 16.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Storage**: CoreData
- **API**: Anthropic Claude API (Vision + Text Generation)

## Project Structure

```
AlbumScan/
├── AlbumScan/
│   ├── AlbumScanApp.swift           # App entry point
│   ├── ContentView.swift            # Root view coordinator
│   ├── Views/
│   │   ├── Camera/
│   │   │   ├── CameraView.swift
│   │   │   ├── CameraPreview.swift
│   │   │   └── SearchPreLoaderView.swift
│   │   ├── Album/
│   │   │   └── AlbumDetailsView.swift
│   │   ├── History/
│   │   │   └── ScanHistoryView.swift
│   │   ├── Welcome/
│   │   │   └── WelcomeView.swift
│   │   └── Error/
│   │       ├── PermissionErrorView.swift
│   │       └── ScanErrorView.swift
│   ├── ViewModels/
│   │   ├── AppState.swift
│   │   └── CameraManager.swift
│   ├── Models/
│   │   ├── Album.swift              # CoreData entity
│   │   ├── AlbumResponse.swift      # API response model
│   │   └── AlbumScan.xcdatamodeld   # CoreData schema
│   ├── Services/
│   │   ├── ClaudeAPIService.swift
│   │   └── PersistenceController.swift
│   ├── Utilities/
│   │   └── Config.swift
│   └── Info.plist
├── AlbumScanTests/
├── AlbumScanUITests/
└── PROJECT_CONTEXT.md               # Complete project specification
```

## Setup Instructions

### Prerequisites

1. macOS with Xcode 15+ installed
2. Apple Developer account (for device testing)
3. Anthropic Claude API key

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd AlbumScan
   ```

2. Set up API key:
   ```bash
   export CLAUDE_API_KEY="your-api-key-here"
   ```

   Or create a `Secrets.plist` file (gitignored) with your API key.

3. Open the project in Xcode:
   ```bash
   open AlbumScan/AlbumScan.xcodeproj
   ```

4. Build and run on your device or simulator (iOS 16.0+)

### API Key Configuration

**IMPORTANT**: Never commit your API key to version control.

Options for storing your API key:
- Environment variable (recommended for development)
- Build configuration file
- Keychain (for production)

See `AlbumScan/AlbumScan/Utilities/Config.swift` for implementation details.

## Usage

1. **First Launch**: Grant camera permissions
2. **Scan Album**: Point camera at album cover and tap "SCAN"
3. **View Details**: See album information, cultural context, and recommendations
4. **History**: Access previously scanned albums from the history icon

## Development Status

Current Phase: **Initial Setup Complete**

### Completed
- ✅ Project structure created
- ✅ Core Data model defined
- ✅ View hierarchy implemented
- ✅ API service scaffolding
- ✅ Camera manager setup

### Next Steps
1. Create Xcode project file
2. Test camera functionality
3. Implement API integration
4. Test with real album covers
5. Refine UI/UX

## Cost Estimates

- **Claude API**: ~$0.10-0.30 per scan
- **Apple Developer Program**: $99/year
- **Estimated monthly usage** (50-100 scans): $10-30

## Out of Scope (MVP)

The following features are NOT included in v1.0:
- ❌ Spotify playback integration
- ❌ Manual search functionality
- ❌ Cloud sync
- ❌ iPad support
- ❌ Social sharing
- ❌ Export functionality

## Privacy & Security

- No analytics or tracking
- Album data stored locally only
- Camera access only when user initiates scan
- Images sent to Anthropic API for identification only
- API key never hardcoded in source

## Contributing

This is a personal hobby project. See PROJECT_CONTEXT.md for complete specifications.

## License

TBD

## Contact

TBD
