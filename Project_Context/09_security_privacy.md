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

**Document Accuracy:** This security and privacy document has been verified and updated to reflect the actual codebase implementation as of October 29, 2025.

**Major Corrections Made:**

1. **API Provider Update:**
   - **Before:** "Anthropic Claude API"
   - **After:** "OpenAI API"
   - **Reason:** Complete migration from Claude to OpenAI completed in October 2025

2. **API Key Management:**
   - **Before:** Generic example with `CLAUDE_API_KEY`
   - **After:** Updated to `OPENAI_API_KEY` with current implementation details
   - **Added:** `Secrets.plist` implementation details

3. **API Data Transmission:**
   - **Before:** "Phase 1" and "Phase 2" terminology
   - **After:** "ID Call 1", "ID Call 2 (conditional)", "Review Generation" terminology
   - **Added:** Search-based identification clarification (10-20% of scans)
   - **Added:** MusicBrainz and Cover Art Archive details (free public APIs)
   - **Added:** TLS 1.2+ specification
   - **Clarified:** No user accounts or authentication

4. **Privacy Policy Section:**
   - **Updated:** OpenAI API provider reference (not Anthropic)
   - **Added:** MusicBrainz and Cover Art Archive usage disclosure
   - **Added:** No user accounts clarification
   - **Added:** Local-only history storage clarification

5. **Data Retention Section:**
   - **Added:** New section covering data retention policies
   - **OpenAI:** Reference to their data retention policies
   - **MusicBrainz/Cover Art Archive:** No user data transmitted
   - **Local device:** User controls all data

**Security Implementation Verified:**

**API Key Storage:**
- Stored in `Secrets.plist` (verified in Config.swift:18-19)
- `Secrets.plist` added to .gitignore (verified in .gitignore file)
- Template provided in repository with placeholder values
- Keys loaded at runtime via `Config.swift`

**Data Privacy:**
- ✅ No analytics or tracking implemented
- ✅ No user behavior logging
- ✅ No telemetry
- ✅ CoreData local storage only (no cloud sync)
- ✅ No third-party SDKs (besides OpenAI API client)
- ✅ Camera only used when user taps SCAN button
- ✅ No photo library access

**Network Security:**
- ✅ All API calls use HTTPS (TLS 1.2+)
- ✅ URLSession default configuration (App Transport Security enabled)
- ✅ No insecure HTTP connections

**App Store Readiness:**
- Privacy policy required before submission
- Must disclose OpenAI API usage (data processing)
- Must disclose camera usage (NSCameraUsageDescription in Info.plist)
- Must disclose local data storage (CoreData)
- No additional permissions required

**Data Flow Summary:**
1. User taps SCAN → Photo captured locally
2. Photo sent to OpenAI API (ID Call 1) → Album identified
3. If needed: Photo + query sent to OpenAI API (ID Call 2 with search)
4. Album metadata sent to MusicBrainz → MBID retrieved
5. MBID sent to Cover Art Archive → Artwork URL retrieved
6. Album metadata sent to OpenAI API → Review generated
7. All data (album + artwork + review) saved to CoreData locally
8. No data leaves device except for API calls (identification, review, artwork)

**Status:** Document accurately reflects current OpenAI API implementation, API key management via Secrets.plist, and privacy-first architecture with local-only data storage