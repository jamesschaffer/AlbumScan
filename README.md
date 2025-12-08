# AlbumScan

A music discovery companion that reveals the cultural significance and artistic merit of albums through photo identification.

## Overview

AlbumScan is an iOS app that helps music collectors identify albums and understand their cultural significance. When browsing record stores, users can take a photo of an album cover to instantly learn about its musical importance, influence, and artistic merit.

**This app focuses on artistry and cultural value, NOT pricing or collectibility.**

## Features

- **Camera-Based Album Identification**: AI-powered two-tier identification system (80-90% success rate on first call)
- **Cultural Context**: Expert analysis on why an album matters musically with 8-tier recommendation labels
- **Honest Recommendations**: Ratings from "Essential Classic" to "Avoid Entirely"
- **Scan History**: Review all previously scanned albums with offline access
- **Key Information**: View release details, genres, key tracks, and critical reception
- **Subscription Tiers**: Free (5 scans), Base ($4.99/year), Ultra ($11.99/year with search capability)

## Technical Stack

- **Platform**: iOS 16.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Storage**: CoreData
- **Backend**: Firebase Cloud Functions (secure API proxy)
- **API Provider**: OpenAI (gpt-4o, gpt-4o-search-preview)
- **Security**: Firebase App Check with App Attest

## Project Structure

```
AlbumScan/
├── Project_Context/                  # Complete specification (11 files)
├── functions/                        # Firebase Cloud Functions (TypeScript)
├── website/                          # Marketing website
├── docs/                             # Legal documentation
├── AlbumScan/
│   └── AlbumScan/
│       ├── AlbumScanApp.swift        # App entry point
│       ├── ContentView.swift         # Root view coordinator
│       ├── Views/
│       │   ├── Camera/               # CameraView, CameraPreview
│       │   ├── Album/                # AlbumDetailsView
│       │   ├── History/              # ScanHistoryView
│       │   ├── Subscription/         # WelcomePurchaseSheet, ChooseYourPlanView
│       │   ├── Error/                # PermissionErrorView, ScanErrorView
│       │   ├── LoadingView.swift     # Four-stage loading experience
│       │   ├── SettingsView.swift    # Ultra settings toggle
│       │   └── LaunchScreenView.swift
│       ├── ViewModels/               # AppState, CameraManager
│       ├── Models/                   # Album, ScanState, Response models
│       ├── Services/                 # OpenAIAPIService, CloudFunctionsService, SubscriptionManager
│       ├── Utilities/                # Config, KeychainHelper
│       └── Prompts/                  # AI prompt files
├── AlbumScanTests/
└── AlbumScanUITests/
```

## Setup Instructions

### Prerequisites

1. macOS 13.0+ with Xcode 15+ installed
2. Apple Developer account (for device testing)
3. Firebase project (for Cloud Functions)
4. OpenAI API key (for development/debugging)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd AlbumScan
   ```

2. For local development, create `Secrets.plist` with API keys (gitignored):
   ```xml
   <dict>
       <key>OPENAI_API_KEY</key>
       <string>your-openai-api-key</string>
   </dict>
   ```

3. Open the project in Xcode:
   ```bash
   open AlbumScan/AlbumScan.xcodeproj
   ```

4. Build and run on your device (iOS 16.0+)

### Cloud Functions Deployment

See `CLOUD_FUNCTIONS_SETUP.md` for Firebase deployment instructions.

## Usage

1. **First Launch**: Grant camera permissions and view subscription options
2. **Scan Album**: Point camera at album cover and tap "SCAN"
3. **View Details**: See album information, cultural context, and 8-tier recommendation
4. **History**: Access previously scanned albums from the history icon
5. **Settings**: Toggle Advanced Search for Ultra subscribers

## Development Status

Current Phase: **Production (App Store Published)**

### Completed
- ✅ Two-tier identification system (gpt-4o + gpt-4o-search-preview)
- ✅ Firebase Cloud Functions backend (secure API proxy)
- ✅ StoreKit 2 subscription system (Base + Ultra tiers)
- ✅ Firebase App Check with App Attest
- ✅ 98% cost reduction achieved ($0.10/day for 100 scans)
- ✅ Four-stage loading UX with progressive messaging
- ✅ 8-tier recommendation label system
- ✅ Aggressive review caching (70-80% hit rate)

## Cost Architecture

- **API Costs**: ~$0.10/day for 100 scans (with caching)
- **Firebase**: Free tier (2M function invocations/month)
- **Apple Developer Program**: $99/year

**Per-Scan Breakdown**:
- ID Call 1: ~$0.01 (every scan)
- ID Call 2: ~$0.03-0.04 (10-20% of scans)
- Review: ~$0.05-0.10 new, $0.00 cached (70-80% cached)

## Privacy & Security

- **No analytics or tracking**
- **Album data stored locally only** (CoreData)
- **API keys server-side only** (Firebase Secrets Manager)
- **Device attestation** (Firebase App Check)
- **Rate limiting** (10 requests/minute/device)

See `docs/privacy-policy.html` for full privacy policy.

## Documentation

Complete specification available in `Project_Context/` directory:
- 00: Table of contents and version history
- 01-03: Project overview, personas, features
- 04-05: User flows and screen architecture
- 06: Two-tier API architecture
- 07: UX principles and design patterns
- 08-09: Testing and security
- 10: Prompt management

## License

Proprietary - All rights reserved
