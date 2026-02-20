# AlbumScan

## Overview

AlbumScan is an iOS app that helps music collectors identify albums and understand their cultural significance. Users photograph album covers in record stores and receive AI-generated reviews covering artistic merit, critical reception, and cultural impact. The app focuses on artistry and cultural value, not pricing or collectibility.

The app is published on the App Store and in active production use.

## Current State

**Last Updated:** February 20, 2026
**App Version:** 1.8 (Review API backward compatibility)
**Production AI Provider:** Gemini 3 Flash (via Firebase Cloud Functions)
**Firebase Project:** `albumscan-18308` (shared with Crate app)
**CI/CD:** GitHub Actions (tests) + Fastlane (TestFlight)

### What is built and working

- Two-tier album identification: ID Call 1 (vision) followed by conditional ID Call 2 (Google Search grounding for uncertain results)
- Review generation via Gemini with server-side prompt construction and an 8-tier recommendation system
- Backward-compatible review API contract: the `generateReviewGemini` Cloud Function accepts both legacy `{prompt, useSearch}` format (for older App Store installs) and the new structured format `{artistName, albumTitle, releaseYear, genres, recordLabel}`
- StoreKit 2 subscriptions (Free: 5 scans, Base: $4.99/year, Ultra: $11.99/year with search)
- Firebase App Check with App Attest for device attestation
- CoreData persistence with aggressive review caching (70-80% hit rate)
- Rate limiting at 10 requests per minute per device

### What was recently changed (February 2026)

**CI/CD and test infrastructure (latest commit, feature/ci-cd-setup branch):**
- Added 41 unit tests across 5 Swift Testing suites: `ScanStateTests`, `Phase1ResponseTests`, `Phase2ResponseTests`, `AlbumIdentificationResponseTests`, and `AlbumModelTests`. Tests cover model properties, state machine behavior, JSON round-trips, and response parsing. No network or API keys required.
- Added GitHub Actions workflow (`.github/workflows/test.yml`) with three jobs: iOS tests (macOS 15, iPhone 16 simulator), Cloud Functions tests (Node.js 20, `npm test`), and a summary gate job.
- Added Fastlane configuration (`Gemfile`, `fastlane/Fastfile`, `fastlane/Appfile`) with a `beta` lane for one-command TestFlight deployment. Build numbers auto-increment via timestamp.
- Added `Secrets.plist.example` as a CI stub so the Xcode project builds without real API keys.
- Hardened `.gitignore` with `*.p8`, `*.p12`, `*.pem`, `*.crash`, `vendor/bundle/`, and `.bundle/` entries to prevent accidental commit of signing keys or Ruby dependencies.
- This brings AlbumScan to CI/CD parity with Crate and QueryGram.

**Prior changes (commit 2a4e15d):**
- **Backend:** `generateReviewGemini` now accepts both legacy and structured request formats using an `isLegacyRequest()` type guard. Legacy requests are logged with a `LEGACY` tag for monitoring deprecation progress.
- **iOS client:** `CloudFunctionsService.swift` updated to send structured fields (`artistName`, `albumTitle`, `releaseYear`, `genres`, `recordLabel`) directly instead of building a prompt string client-side. The `reviewPrompt` property and `album_review.txt` bundle loading were removed.
- **Removed:** The OpenAI `generateReview` function was deleted from deployed functions. Production always routes to the Gemini variant.
- **Security:** `GoogleService-Info.plist` was refreshed after an API key rotation. This file is gitignored and must be obtained from Firebase Console.

### What is NOT working or requires attention

- Legacy `{prompt, useSearch}` format is still supported but should be monitored for deprecation. Once all App Store users have updated, the legacy path can be removed.
- The OpenAI `identifyAlbum` and `searchFinalizeAlbum` functions are still deployed but unused in production (Gemini is the default). They exist as a fallback option.
- UI test suite (`AlbumScanUITests/`) is still empty. Unit tests are now implemented but UI tests are not.

## Architecture

### High-Level Structure

```
iOS App (SwiftUI + CoreData)
    |
    v
Firebase Cloud Functions (TypeScript, project albumscan-18308)
    |
    +-- identifyAlbumGemini        (Gemini 3 Flash + Google Search)
    +-- searchFinalizeAlbumGemini  (Gemini 3 Flash + Google Search grounding)
    +-- generateReviewGemini       (Gemini 3 Flash, server-side prompt, backward-compatible)
    +-- identifyAlbum              (OpenAI gpt-4o, fallback only)
    +-- searchFinalizeAlbum        (OpenAI gpt-4o-search-preview, fallback only)
    +-- healthCheck                (unauthenticated monitoring endpoint)
    |
    v
Google AI (Gemini API) / OpenAI API
```

### Shared Backend

The Firebase project `albumscan-18308` serves both **AlbumScan** and the **Crate** app. They share the same deployed Cloud Functions. This means any change to a Cloud Function's input contract, output format, or behavior affects both apps. The backward-compatible API pattern used in `generateReviewGemini` exists specifically because of this constraint -- existing App Store installs of either app must continue to work after backend changes.

### Key Components

- **CloudFunctionsService.swift** (iOS): Routes API calls to the appropriate Cloud Function based on the current provider. In production (release builds), always uses Gemini variants. In debug builds, the provider can be toggled between OpenAI and Gemini.
- **functions/src/index.ts** (Backend): All Cloud Functions in a single file. Contains rate limiting, input validation, JSON cleaning, response normalization, and the review system instruction prompt.
- **CameraManager.swift** (iOS): Orchestrates the full scan flow -- camera capture, two-tier identification, artwork retrieval, review generation, and CoreData persistence.
- **PersistenceController.swift** (iOS): CoreData management with review caching logic.

### Data Flow: Scan to Review

1. User photographs album cover
2. `CameraManager` captures image, converts to base64
3. `CloudFunctionsService` calls `identifyAlbumGemini` with image + identification prompt
4. If identification is uncertain and user has Ultra tier, calls `searchFinalizeAlbumGemini`
5. After identification: artwork retrieved from MusicBrainz + Cover Art Archive
6. Cache check: if review exists in CoreData, skip API call
7. If cache miss: `CloudFunctionsService` calls `generateReviewGemini` with structured album metadata
8. Cloud Function builds the review prompt server-side and calls Gemini API
9. Response saved to CoreData; UI updates

### CI/CD Pipeline

```
GitHub (push/PR to main)
  --> GitHub Actions (.github/workflows/test.yml)
        --> iOS Tests (macOS 15, Xcode, iPhone 16 Simulator)
        --> Cloud Functions Tests (Node.js 20, npm test)
        --> Summary gate (fails if either job fails)

Local (developer machine)
  --> bundle exec fastlane beta
        --> Auto-increment build number (timestamp)
        --> Build .ipa (App Store export method)
        --> Upload to TestFlight
```

### Security Model

```
iOS App
  --> App Check Token (App Attest)
    --> Cloud Functions (validates token, checks rate limit)
      --> Firebase Secrets Manager (API keys)
        --> Gemini / OpenAI API
```

- API keys never leave the server
- Review prompts are constructed server-side (not shipped in the app bundle)
- `GoogleService-Info.plist` is gitignored; an `.example` file documents the expected structure
- `Secrets.plist` is gitignored; used only for local development fallback

## Features

| Feature | Description |
|---------|-------------|
| Camera Identification | AI-powered two-tier identification from album cover photos (80-90% success rate) |
| Cultural Context Reviews | Honest, evidence-based album reviews with 8-tier recommendation labels |
| Scan History | Chronological list of all scanned albums with offline access via CoreData |
| Subscription Tiers | Free (5 scans), Base ($4.99/year, 120/month), Ultra ($11.99/year, search enabled) |
| Provider Selection | Gemini (production default), OpenAI (debug toggle) |
| Review Caching | Aggressive caching with 70-80% hit rate, title normalization for deduplication |
| Backward-Compatible API | Review endpoint accepts both legacy and structured formats for safe rolling updates |
| Unit Test Suite | 41 tests across 5 suites covering models, state machine, and response parsing (Swift Testing) |
| GitHub Actions CI | Automated iOS and Cloud Functions tests on push/PR to main |
| Fastlane TestFlight | One-command beta deployment via `bundle exec fastlane beta` |

## Known Issues / Technical Debt

- **UI tests not implemented**: Unit tests are in place (41 tests, 5 suites) but `AlbumScanUITests/` remains empty.
- **Legacy request format**: The `{prompt, useSearch}` format in `generateReviewGemini` should be removed once all users have updated past the breaking change.
- **Legacy services in codebase**: `ClaudeAPIService.swift`, `OpenAIAPIService.swift`, and several legacy response models (`Phase1AResponse`, `Phase1Response`) remain in the codebase but are not used in production.
- **OpenAI functions still deployed**: `identifyAlbum` and `searchFinalizeAlbum` are deployed but unused in production release builds. They could be removed to simplify the deployed surface area.
- **In-memory rate limiting**: Rate limits reset when Cloud Functions cold-start. The code notes this should use Firestore for production scale.
- **Prompt files partially stale**: `album_review.txt` and `album_review_ultra.txt` exist in the iOS bundle Prompts directory but are no longer loaded by `CloudFunctionsService`. They may still be referenced by `OpenAIAPIService` (dev fallback).

## Future Considerations

- **Deprecate legacy review format**: Monitor `LEGACY` log tags in Cloud Functions logs. Once traffic drops to zero, remove the `isLegacyRequest` code path.
- **Remove unused OpenAI functions**: Once confirmed unnecessary, delete `identifyAlbum`, `searchFinalizeAlbum` from deployed functions.
- **Clean up legacy iOS services**: Remove `ClaudeAPIService.swift` and unused response models.
- **Add UI tests**: Unit tests are in place; UI tests are the next gap. The `AlbumScanUITests/` directory exists and is ready for implementation.
- **Automate TestFlight via CI**: The Fastlane `beta` lane currently runs locally. A future GitHub Actions workflow could trigger TestFlight uploads on tagged releases or merges to main.
- **Persistent rate limiting**: Move from in-memory `Map` to Firestore for rate limiting that survives cold starts.
