# Decision Log

## 2026-02-15 - Backward-compatible review API contract

**Context:** Commit 5377766 changed the `generateReviewGemini` Cloud Function to expect structured fields (`artistName`, `albumTitle`, `releaseYear`, `genres`, `recordLabel`) instead of the original `{prompt, useSearch}` format. However, the iOS client was not updated in the same commit. This broke review generation for all existing App Store installs, because those installs still sent the old format. The issue also affected the Crate app, which shares the same Firebase Cloud Functions backend (project `albumscan-18308`).

**Decision:** Make the `generateReviewGemini` function accept both request formats. A type guard (`isLegacyRequest`) detects incoming requests: if the payload contains a `prompt` string field, it is treated as a legacy request and the prompt is passed through directly. Otherwise, the function expects structured fields and builds the prompt server-side. Legacy requests are logged with a `LEGACY` tag for monitoring.

**Alternatives Considered:**
1. *Force-update all clients* -- Not possible. App Store users cannot be forced to update, and Crate shares the same backend.
2. *Deploy a separate v2 endpoint* -- Would require maintaining two function names and updating client routing logic. More moving parts for a temporary migration.
3. *Revert the structured format and keep client-side prompts* -- Would lose the security and maintainability benefits of server-side prompt construction.

**Rationale:** Backward compatibility is the safest path when a deployed backend serves multiple clients with independent release cycles. The type guard approach keeps a single function name, requires no client-side routing changes for old installs, and lets us monitor deprecation progress via logs.

**Consequences:**
- Old App Store installs continue to work without an update.
- The legacy code path must be maintained until all users have updated. Monitor `LEGACY` tags in Cloud Functions logs to track when it is safe to remove.
- Any future changes to the `generateReviewGemini` input contract must account for both formats until the legacy path is deprecated.

---

## 2026-02-15 - Server-side prompt construction for reviews

**Context:** Previously, the iOS client loaded the review prompt from a bundled text file (`album_review.txt`), interpolated album metadata into it, and sent the complete prompt string to the Cloud Function. This meant the prompt was visible in the app bundle and could only be updated via an App Store release.

**Decision:** Move review prompt construction to the Cloud Function. The iOS client now sends only structured album metadata (artist, title, year, genres, label). The Cloud Function contains the full system instruction (`REVIEW_SYSTEM_INSTRUCTION`) and builds the user message server-side.

**Alternatives Considered:**
1. *Keep client-side prompts* -- Simpler, but locks prompt iteration to App Store release cycles and exposes prompt content in the app binary.
2. *Use Firebase Remote Config for prompts* -- Would allow dynamic updates without code changes, but adds complexity and another dependency. The prompt is tightly coupled to the function logic (e.g., search grounding decisions), so co-locating them makes more sense.

**Rationale:** Server-side prompts can be iterated without an App Store review. They also prevent prompt content from being extracted from the app binary. Since the Cloud Function already makes decisions based on album metadata (e.g., whether to enable search grounding based on release year), co-locating the prompt with that logic reduces the chance of mismatches.

**Consequences:**
- Prompt changes are deployed instantly via `firebase deploy --only functions`.
- The iOS client no longer needs `album_review.txt` for the Cloud Functions path (it may still be needed for the `OpenAIAPIService` dev fallback).
- The review prompt is now only visible to those with access to the Cloud Functions source code.

---

## 2026-02-15 - Shared Cloud Functions backend between AlbumScan and Crate

**Context:** Both AlbumScan and Crate are configured to use Firebase project `albumscan-18308`. This was discovered when a breaking change to `generateReviewGemini` affected both apps simultaneously.

**Decision:** Acknowledge and document that both apps share the same deployed Cloud Functions. Any changes to function input contracts, output formats, or behavior must be treated as multi-client changes requiring backward compatibility.

**Alternatives Considered:**
1. *Split into separate Firebase projects* -- Would eliminate the coupling but require duplicating Cloud Functions, secrets, and billing configuration. Higher operational overhead for a personal project.
2. *Version the functions (e.g., generateReviewGeminiV2)* -- Adds endpoint proliferation. Acceptable for major breaking changes but overkill for contract evolution.

**Rationale:** For a personal project with two apps, sharing a backend is pragmatic. The cost of maintaining backward compatibility (a type guard and a log tag) is much lower than the cost of running parallel infrastructure. The key insight is treating Cloud Function changes like public API changes: assume multiple clients and never break existing callers without a deprecation period.

**Consequences:**
- All Cloud Function changes must be backward-compatible or use a deprecation strategy.
- Both apps should be tested when Cloud Functions are modified.
- This coupling should be documented prominently so future work does not repeat the same mistake.

---

## 2025-12-08 - Gemini as production AI provider

**Context:** AlbumScan originally used OpenAI (gpt-4o) for identification and reviews. Gemini 2.5 Flash (later upgraded to Gemini 3 Flash Preview) was evaluated as an alternative offering lower costs and native Google Search grounding.

**Decision:** Use Gemini as the default production provider. OpenAI functions remain deployed as a fallback but are only accessible in DEBUG builds via a provider toggle in Settings.

**Alternatives Considered:**
1. *Stay with OpenAI only* -- Higher per-call costs and requires a separate search API for web-grounded results.
2. *Let users choose in production* -- Adds UX complexity and doubles the surface area for quality issues.

**Rationale:** Gemini offers comparable quality at significantly lower cost (estimated 70-80% reduction), and its native Google Search grounding eliminates the need for `gpt-4o-search-preview` for the search finalization step. Keeping OpenAI as a debug-only fallback provides a safety net without complicating the user experience.

**Consequences:**
- Production release builds always route to Gemini functions.
- OpenAI functions still consume deployment resources but are not called in production.
- Quality differences between providers need ongoing monitoring.

---

## 2025-12-03 - Firebase Cloud Functions as secure API proxy

**Context:** The initial implementation called OpenAI directly from the iOS app, requiring API keys to be bundled in the app. This is a security risk (keys can be extracted from the binary).

**Decision:** Move all AI API calls behind Firebase Cloud Functions. API keys are stored in Firebase Secrets Manager and never leave the server. The iOS app calls Cloud Functions via Firebase SDK with App Check device attestation.

**Alternatives Considered:**
1. *Keep direct API calls with obfuscation* -- Security through obscurity is not real security.
2. *Use a custom backend (e.g., Vercel, AWS Lambda)* -- More flexibility but more infrastructure to manage. Firebase is already in the stack for App Check.

**Rationale:** Firebase Cloud Functions integrate naturally with the existing Firebase App Check setup. A single deployment command (`firebase deploy --only functions`) handles everything. Server-side key storage is the only truly secure approach for mobile apps.

**Consequences:**
- All API calls go through Firebase, adding a small amount of latency.
- Firebase Blaze plan is required (pay-as-you-go, but 2M free invocations/month).
- API key rotation is handled server-side without requiring an App Store update.
- Rate limiting is enforced server-side (10 requests/minute/device).

---

## 2025-10-30 - Two-tier identification architecture

**Context:** A single AI call could not reliably identify all albums from cover photos alone. Some albums (especially obscure ones or those with minimal text) required additional context from web search.

**Decision:** Implement a two-tier system: ID Call 1 attempts identification from the image alone. If the result indicates low confidence, ID Call 2 uses web search grounding to refine the identification. The second call is gated by the user's subscription tier (Ultra only).

**Alternatives Considered:**
1. *Always use search* -- More expensive and slower for the 80-90% of cases where the first call succeeds.
2. *Single call with optional search* -- API providers at the time did not support conditional search within a single call.

**Rationale:** The two-tier approach optimizes for the common case (fast, cheap identification) while providing a fallback for difficult cases. Gating the second call behind Ultra tier creates a meaningful upgrade incentive.

**Consequences:**
- 80-90% of scans complete with a single API call.
- The remaining 10-20% require a second call, adding latency and cost.
- Search gate validation prevents wasteful second calls when the first call's data is insufficient.
