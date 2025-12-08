## SECURITY & PRIVACY

### API Key Management

**NEVER hardcode API keys in source code.**

**Storage Options:**
- **Xcode Build Configuration:** Store in xcconfig file (add to .gitignore)
- **Environment Variables:** Use Xcode build settings
- **Keychain:** For production apps (overkill for MVP)

**Git:**
- Add API keys to .gitignore
- Add xcconfig files to .gitignore
- Never commit sensitive credentials

**Best Practice:**
```swift
// Read from build configuration
let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
```

**Current Implementation:**
- OpenAI API key stored in `Secrets.plist` (added to .gitignore)
- Loaded via `Config.swift` at runtime
- `Secrets.plist` template provided in repository with placeholder values

### Data Privacy

**No Analytics:**
- No tracking or analytics in MVP
- No user behavior logging
- No telemetry

**No External Data Sharing:**
- Album scan data stays on device
- No cloud sync (CoreData local only)
- No third-party SDKs

**Camera Access:**
- Only used when explicitly triggered by user (SCAN button)
- Not running in background
- Not accessing photo library

**API Data Transmission:**
- Album cover photo sent to OpenAI API (ID Call 1: identification)
- Album cover photo + search query sent to OpenAI API (ID Call 2: conditional search-based identification, 10-20% of scans)
- Album metadata sent to OpenAI API (Review Generation: cultural context and ratings)
- Album metadata sent to MusicBrainz (for artwork lookup - free public API)
- Artwork URL fetched from Cover Art Archive (free public API)
- No personal user data transmitted (no user accounts, no authentication)
- All API calls over HTTPS (TLS 1.2+)

**Privacy Policy (Required for App Store):**
Before App Store submission, create privacy policy explaining:
- Camera usage (to capture album covers for identification)
- API data transmission (images and metadata sent to OpenAI for identification and review generation)
- MusicBrainz and Cover Art Archive usage (free public APIs for artwork retrieval)
- Local storage only (CoreData on-device, no cloud sync)
- No data sharing with third parties beyond API providers
- No user tracking or analytics
- No user accounts or authentication required
- Album scan history stored locally only

**Data Retention:**
- OpenAI: Data retention policies apply (check OpenAI terms for current policy)
- MusicBrainz/Cover Art Archive: Public APIs, no user data transmitted
- Local device: User controls all data (can delete history at any time)

---

## Verification Summary

**Document Accuracy:** This security and privacy document has been verified and updated to reflect the actual codebase implementation as of December 7, 2025.

---

## Version 1.6 Update: Firebase Cloud Functions Security

### API Architecture Change (December 2025)

**Current Production Architecture:** Firebase Cloud Functions proxy

| Component | Change |
|-----------|--------|
| **API Keys** | Moved from app bundle to Firebase Secrets Manager |
| **API Calls** | Routed through Firebase callable functions |
| **Device Verification** | Firebase App Check with App Attest |
| **Rate Limiting** | 10 requests/minute/device |

### Cloud Functions Security Features

**Server-Side API Key Storage:**
- OpenAI API key stored in Firebase Secrets Manager
- Key NEVER shipped in iOS app bundle (production)
- Key retrieved server-side via `defineSecret("OPENAI_API_KEY")`
- Development fallback: `Secrets.plist` (gitignored) for direct API mode

**Firebase App Check:**
- Device attestation via App Attest (iOS 14+)
- Prevents unauthorized API access
- Enforced on all Cloud Functions (`enforceAppCheck: true`)
- Debug provider for development builds

**Rate Limiting:**
- 10 requests per minute per device
- In-memory rate limiting (production could use Firestore)
- Returns HTTP 429 on limit exceeded
- Configurable via `RATE_LIMIT_MAX_REQUESTS` constant

**Input Validation:**
- Image size limit: 5MB maximum
- Required field validation
- Prevents abuse with oversized requests

### Cloud Functions Deployed

| Function | Purpose | Model | Security |
|----------|---------|-------|----------|
| `identifyAlbum` | ID Call 1 (vision) | gpt-4o | App Check + Rate Limit |
| `searchFinalizeAlbum` | ID Call 2 (search) | gpt-4o-search-preview | App Check + Rate Limit |
| `generateReview` | Review generation | gpt-4o or gpt-4o-search-preview | App Check + Rate Limit |
| `healthCheck` | Monitoring | N/A | No Auth (health only) |

### Data Flow (Cloud Functions Architecture)

```
1. User taps SCAN → Photo captured locally
2. App Check token generated → Sent with request
3. Cloud Function validates token → Checks rate limit
4. Photo sent to Firebase → Cloud Function calls OpenAI API
5. Response returned to app → Album identified
6. If needed: Search finalization via `searchFinalizeAlbum`
7. Album metadata sent to MusicBrainz → MBID retrieved (direct, no proxy)
8. MBID sent to Cover Art Archive → Artwork URL retrieved (direct, no proxy)
9. Review generated via `generateReview` function
10. All data saved to CoreData locally
```

**Key Security Improvements:**
- ✅ API keys never leave server
- ✅ Device attestation prevents unauthorized access
- ✅ Rate limiting prevents abuse
- ✅ No credentials in iOS app bundle (production)

---

## Previous Version History

**Major Corrections (October 2025):**

1. **API Provider Update:**
   - Migrated from Anthropic Claude API to OpenAI API
   - Two-tier identification architecture implemented

2. **API Key Management:**
   - Development: `Secrets.plist` (gitignored)
   - Production: Firebase Secrets Manager (server-side only)

3. **Terminology Update:**
   - "Phase 1/2" → "ID Call 1", "ID Call 2 (conditional)", "Review Generation"

---

**Security Implementation Verified (December 2025):**

**API Key Storage:**
- Production: Firebase Secrets Manager (server-side)
- Development: `Secrets.plist` (verified in Config.swift, gitignored)
- Provider selection: `Config.currentProvider = .cloudFunctions` (default)

**Data Privacy:**
- ✅ No analytics or tracking implemented
- ✅ No user behavior logging
- ✅ No telemetry
- ✅ CoreData local storage only (no cloud sync)
- ✅ Firebase SDK for callable functions only (no Firestore, no Analytics)
- ✅ Camera only used when user taps SCAN button
- ✅ No photo library access

**Network Security:**
- ✅ All API calls via Firebase Cloud Functions (HTTPS)
- ✅ App Check token validation on every request
- ✅ Rate limiting enforced server-side
- ✅ TLS 1.2+ for all connections
- ✅ No insecure HTTP connections

**App Store Status:**
- ✅ Published on App Store
- ✅ Privacy policy: docs/privacy-policy.html
- ✅ Terms of service: docs/terms-of-service.html
- ✅ Camera permission disclosed in Info.plist
- ✅ API data transmission disclosed in privacy policy

**Status:** Document accurately reflects current Firebase Cloud Functions architecture with server-side API key storage, App Check device attestation, and privacy-first design

---

**Last Updated:** December 7, 2025