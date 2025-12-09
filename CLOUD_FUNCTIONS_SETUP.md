# Firebase Cloud Functions Setup Guide

This guide walks you through deploying the secure API proxy for AlbumScan.

## Overview

The Cloud Functions implementation provides:
- **Server-side API key protection** - OpenAI key never leaves your server
- **Device attestation** - Firebase App Check verifies legitimate app instances
- **Rate limiting** - 10 requests per minute per device
- **Usage monitoring** - Token usage logged in Firebase console

## Prerequisites

- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project: `albumscan-18308`
- OpenAI API key

## Setup Steps

### Step 1: Login to Firebase

```bash
cd /Users/jamesschaffer/Documents/Dev-Projects/iOS\ App/AlbumScan
firebase login
```

### Step 2: Select Your Project

```bash
firebase use albumscan-18308
```

Or if not listed:
```bash
firebase use --add
# Select albumscan-18308 from the list
```

### Step 3: Enable Required APIs

In Google Cloud Console (https://console.cloud.google.com):
1. Select project `albumscan-18308`
2. Enable **Secret Manager API**
3. Enable **Cloud Functions API** (if not already enabled)

Or via CLI:
```bash
gcloud services enable secretmanager.googleapis.com --project=albumscan-18308
gcloud services enable cloudfunctions.googleapis.com --project=albumscan-18308
```

### Step 4: Set API Key Secrets

**OpenAI API Key (required):**
```bash
cd functions
firebase functions:secrets:set OPENAI_API_KEY
# Paste your OpenAI API key when prompted (input is hidden)
```

**Gemini API Key (required for Gemini provider):**
```bash
firebase functions:secrets:set GEMINI_API_KEY
# Paste your Google AI API key when prompted (input is hidden)
```

### Step 5: Upgrade to Blaze Plan (if needed)

Cloud Functions require the Blaze (pay-as-you-go) plan:
1. Go to Firebase Console → Project Settings → Usage and Billing
2. Upgrade to Blaze plan
3. Set a budget alert (recommended: $25/month initially)

Note: You get 2 million free function invocations per month.

### Step 6: Deploy Cloud Functions

```bash
cd /Users/jamesschaffer/Documents/Dev-Projects/iOS\ App/AlbumScan
firebase deploy --only functions
```

Expected output:
```
✔ functions[identifyAlbum]: Successful create operation.
✔ functions[searchFinalizeAlbum]: Successful create operation.
✔ functions[generateReview]: Successful create operation.
✔ functions[identifyAlbumGemini]: Successful create operation.
✔ functions[searchFinalizeAlbumGemini]: Successful create operation.
✔ functions[generateReviewGemini]: Successful create operation.
✔ functions[healthCheck]: Successful create operation.
```

### Step 7: Enable App Check in Firebase Console

1. Go to Firebase Console → App Check
2. Click "Get started" or "Register apps"
3. Select your iOS app (jamesschaffer.AlbumScan)
4. Choose **App Attest** as the attestation provider
5. Click "Register"

### Step 8: Enforce App Check on Functions

1. In Firebase Console → App Check
2. Go to "APIs" tab
3. Find "Cloud Functions"
4. Click "Enforce"

**Important:** Only enforce after verifying the app works with App Check enabled!

### Step 9: Remove API Keys from iOS Bundle (Production)

Once Cloud Functions are deployed and working:

1. In `Config.swift`, the API keys are no longer used when `currentProvider = .cloudFunctions`
2. You can remove `Secrets.plist` from the app bundle for production builds
3. Or leave it empty (the keys won't be used)

## Testing

### Local Testing with Emulator

```bash
cd functions
npm run serve
```

In iOS app, uncomment the emulator line in `CloudFunctionsService.swift`:
```swift
#if DEBUG
functions.useEmulator(withHost: "localhost", port: 5001)
#endif
```

### Production Testing

1. Build and run the iOS app
2. Scan an album
3. Check Firebase Console → Functions → Logs for activity

## Deployed Functions (7 Total)

### OpenAI Functions
| Function | Purpose | Model |
|----------|---------|-------|
| `identifyAlbum` | ID Call 1 - Vision identification | gpt-4o |
| `searchFinalizeAlbum` | ID Call 2 - Web search fallback | gpt-4o-search-preview |
| `generateReview` | Review generation | gpt-4o (± search) |

### Gemini Functions
| Function | Purpose | Model |
|----------|---------|-------|
| `identifyAlbumGemini` | ID Call 1 - Vision identification | gemini-2.5-flash |
| `searchFinalizeAlbumGemini` | ID Call 2 - Google Search grounding | gemini-2.5-flash |
| `generateReviewGemini` | Review generation | gemini-2.5-flash (± grounding) |

### Utility Functions
| Function | Purpose | Auth |
|----------|---------|------|
| `healthCheck` | Service health monitoring | None |

## Monitoring

- **Logs:** Firebase Console → Functions → Logs
- **Metrics:** Firebase Console → Functions → Dashboard
- **Errors:** Firebase Console → Functions → Health

## Cost Estimation

| Monthly Scans | Function Invocations | Firebase Cost | OpenAI Cost |
|--------------|---------------------|---------------|-------------|
| 1,000 | ~3,000 | FREE | ~$10-40 |
| 10,000 | ~30,000 | FREE | ~$100-400 |
| 100,000 | ~300,000 | FREE | ~$1,000-4,000 |

Firebase Functions: 2M free invocations/month, then $0.40/million.

## Troubleshooting

### "Permission denied" when deploying
- Ensure you're logged in: `firebase login`
- Ensure correct project: `firebase use albumscan-18308`
- Check IAM permissions in Google Cloud Console

### "Secret not found" error
- Run `firebase functions:secrets:set OPENAI_API_KEY` again
- Verify with `firebase functions:secrets:get OPENAI_API_KEY`

### App Check failures in development
- Debug provider should be automatically used in DEBUG builds
- Check console for debug token and register it in Firebase Console if needed

### Rate limit errors
- Default: 10 requests/minute/device
- Adjust `RATE_LIMIT_MAX_REQUESTS` in `functions/src/index.ts` if needed

## Switching Back to Direct API (Emergency)

If Cloud Functions have issues, temporarily switch back:

In `Config.swift`:
```swift
static let currentProvider: LLMProvider = .openAI  // Was .cloudFunctions
```

This uses the local API key from `Secrets.plist` directly.

## Security Checklist

- [ ] Firebase secrets set (not in code)
- [ ] App Check enabled in Firebase Console
- [ ] App Check enforced on Cloud Functions
- [ ] Blaze plan budget alerts configured
- [ ] API keys removed from production iOS bundle
- [ ] Rate limiting verified working
