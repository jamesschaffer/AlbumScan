# PROJECT SUMMARY
# AlbumScan - Music Album Discovery iOS App

**Version:** 1.5 (Two-Tier Subscription & App Store Submission)
**Last Updated:** November 4, 2025
**Platform:** iOS (Minimum iOS 16+)
**Development Stack:** Swift + SwiftUI
**Current API Provider:** OpenAI

---

## PROJECT OVERVIEW

- **App Name:** AlbumScan
- **Purpose:** A music discovery companion that reveals the cultural significance and artistic merit of albums through photo identification
- **Target Audience:** Music collectors, vinyl enthusiasts, record store browsers who prioritize artistic value over financial value
- **Platform:** iOS (minimum iOS 16+)
- **Development Approach:** Native iOS using Swift/SwiftUI

---

## EXECUTIVE SUMMARY

This iOS application celebrates the joy of music discovery by helping collectors identify albums and understand their cultural significance, artistic merit, and historical impact. When digging through record store bins filled with hundreds of unfamiliar albums, collectors need a knowledgeable companion that can answer: "Is this musically important? Did this influence other artists? Is this album beloved by musicians and critics?"

**This app is deliberately NOT about pricing, pressing values, or financial collectibility.** Instead, this app focuses on the artistic and cultural dimensions of music discovery - helping users find albums that matter because of their sound, innovation, influence, and artistry.

---

## COST ANALYSIS

### Current Costs (Post-Optimization, October 2025)

**Daily Cost (100 scans):**
- **Actual measured cost:** $0.10/day
- **Per scan breakdown:**
  - Cache hits (most scans): $0.001 (identification only)
  - New albums: ~$0.10 (identification + review)
  - Deep cuts requiring search: ~$0.03-0.04 (ID Call 1 + ID Call 2)

**Monthly Cost Projection:**
- **API Costs (OpenAI):** ~$3/month (100 scans/day with high cache hit rate)
- **Apple Developer Program:** $99/year (~$8/month)
- **MusicBrainz:** Free (open API)
- **Cover Art Archive:** Free (open API)
- **Firebase Remote Config:** Free tier

**Total Monthly Operating Cost:** ~$11/month

### Cost Reduction Achievements

The app underwent major cost optimization in October 2025, achieving a **98% cost reduction** from initial implementation:

**Before Optimization:** $5.15/day (100 scans) = ~$155/month
**After Optimization:** $0.10/day (100 scans) = ~$3/month
**Savings:** $152/month (98% reduction)

**Key Optimizations:**

1. **Aggressive Caching (90%+ savings on duplicate scans)**
   - Review caching with indefinite duration (music history doesn't change)
   - Failure caching for 30 days (prevents retry loops)
   - Title normalization (matches "Deluxe", "Remastered", "Reissue" variants)
   - Cache check before every API call

2. **Conditional Search Architecture (70-80% search avoidance)**
   - ID Call 1 uses regular `gpt-4o` (no search capability)
   - 80-90% of albums identified without search
   - ID Call 2 only triggered for deep cuts/obscure albums
   - Search gate prevents wasteful searches on text-poor covers

3. **Critical Model Switch for Reviews (100% search cost elimination)**
   - **Problem discovered:** `gpt-4o-search-preview` performed hidden server-side searches ($0.15/review)
   - **Solution implemented:** Switched to regular `gpt-4o` for review generation
   - **Result:** Zero search capability = zero search costs
   - **Rationale:** Music history is stable - search not needed for cultural analysis

4. **Title Normalization (20-30% cache hit improvement)**
   - Strips variant suffixes: Deluxe, Remaster, Reissue, Edition, Anniversary
   - Example: "Dark Side of the Moon (2011 Remaster)" → "Dark Side of the Moon"
   - Matches different editions of same album to cached review

---

## MONETIZATION STRATEGY

### Freemium Model (Implemented - November 2025)

**Free Tier:**
- 5 free scans per user
- Stored in iOS Keychain + UserDefaults (survives app reinstall)
- 95% reinstall protection via Keychain persistence

**Base Subscription:**
- **Price:** $4.99/year (USA only at launch)
- **Features:** 120 scans per month, ID Call 1 only (no web search capability)
- **Use Case:** Casual users scanning well-known albums
- **Implementation:** StoreKit 2 with local transaction validation (no backend)

**Ultra Subscription:**
- **Price:** $11.99/year (USA only at launch)
- **Features:** 120 scans per month, full two-tier identification with web search
- **Use Case:** Serious collectors scanning obscure/deep-cut albums
- **Search Access:** ID Call 2 enabled for difficult identifications

**Shared Features (Both Tiers):**
- Monthly scan limit: 120 scans per month
- Keychain persistence for subscription tier tracking
- Firebase Remote Config kill switch for emergency controls
- StoreKit 2 purchase, restore, and verification

**Unit Economics:**
- Cost per scan (Base user): ~$0.01 (ID Call 1 only, no search)
- Cost per scan (Ultra user): ~$0.01-0.04 (with conditional search)
- Cost per scan (cached): $0.00 (70-80% hit rate after initial usage)
- Annual revenue per Base subscriber: $4.99
- Annual revenue per Ultra subscriber: $11.99
- Break-even Base: ~50 scans/year (~4 scans/month)
- Break-even Ultra: ~120 scans/year (~10 scans/month)
- Target user: Music enthusiasts who scan regularly and value identification accuracy

**Privacy-First Design:**
- Local StoreKit validation (no user accounts)
- Firebase used for config only (no analytics)
- No cloud sync or user data collection

---

## DESIGN PRINCIPLES

**Speed over Perfection:**
- Get users scanning quickly
- Optimize for fast feedback (ID Call 1 in 2-4 seconds)
- Progressive disclosure (show results as they load)
- 80-90% of scans complete without search (faster, cheaper)

**Cost-Conscious Architecture:**
- Two-tier system minimizes expensive search calls
- Aggressive caching eliminates redundant API costs
- Non-search model for reviews (music history is stable)
- Search gate prevents wasteful API calls on poor-quality captures

**Simple over Complex:**
- MVP is intentionally minimal
- Two-tier API adds complexity but delivers clear ROI (speed + cost)
- UI remains simple (no complex state machines exposed to user)
- Binary outcomes: Success or try again

**Offline-First:**
- History works without internet
- Cached albums load instantly ($0.00 cost)
- Cached reviews display immediately
- Graceful degradation when offline

**Music-Focused:**
- NEVER mention prices or collectibility
- Focus on artistic merit and cultural significance
- Honest reviews (calls out mediocre/bad albums)
- Evidence-based analysis (not just opinions)

---

## TECHNOLOGY STACK

**Platform:**
- iOS 16+ (native)
- Swift 5.9+ with SwiftUI
- AVFoundation for camera
- CoreData for persistence

**API Providers:**
- **OpenAI** (primary LLM provider)
  - `gpt-4o` for identification (ID Call 1)
  - `gpt-4o-search-preview` for search finalization (ID Call 2, conditional)
  - `gpt-4o` for review generation (no search)
- **MusicBrainz** (free album metadata)
- **Cover Art Archive** (free album artwork)
- **Firebase Remote Config** (kill switch, free tier)

**Alternative Provider:**
- Claude (Anthropic) - available via `LLMServiceFactory` but not currently active
- Switch providers: `Config.currentProvider = .claude` or `.openAI`

**Storage:**
- CoreData (local only, no cloud sync)
- iOS Keychain (scan count persistence)
- NSCache (in-memory image caching)

---

## CURRENT STATE & NEXT STEPS

**Production Status:**
- Main branch: Two-tier subscription system fully implemented
- App Store: Submitted for review (November 2025)
- Current daily cost: $0.10 for 100 scans (98% reduction achieved)
- OpenAI as primary provider

**Subscription System (Implemented):**
- Two-tier freemium model: Free (5 scans), Base ($4.99/year), Ultra ($11.99/year)
- Monthly scan limits: 120 scans/month for subscribers
- StoreKit 2: Purchase, restore, and verification complete
- Keychain + UserDefaults persistence for scan counts and subscription tiers
- Firebase Remote Config integration for kill switches
- WelcomePurchaseSheet for onboarding and upsell

**App Store Readiness (Complete):**
- Privacy Policy and Terms of Service published (docs/privacy-policy.html, docs/terms-of-service.html)
- Debug controls repositioned for cleaner screenshots
- App Store Connect: Products configured (albumscan_base_annual, albumscan_ultra_annual)
- App submitted to App Store for review

**Next Steps:**
- Monitor App Store review process
- Real-world testing at record stores post-launch
- Long-term cost monitoring to validate 98% savings
- User feedback collection for v2.0 improvements

---

## KEY INNOVATIONS

1. **Two-Tier Conditional Search**
   - 80-90% of albums skip expensive search calls
   - Search gate prevents wasteful attempts
   - Result: Faster scans, lower costs

2. **Zero-Search Review Model**
   - Breakthrough: Use model WITHOUT search capability instead of constraining search-enabled model
   - Eliminates $0.15/review in hidden search costs
   - Music history is stable - search not needed

3. **Aggressive Caching Strategy**
   - Cache reviews indefinitely (music doesn't change)
   - Title normalization matches album variants
   - 30-day failure cooldown prevents retry loops

4. **Privacy-First Monetization**
   - Local subscription validation (no backend)
   - Keychain-based reinstall protection
   - No user accounts or cloud sync required

5. **Two-Tier Subscription Model**
   - Base tier: Affordable entry point for casual users ($4.99/year)
   - Ultra tier: Advanced features for serious collectors ($11.99/year)
   - Differentiator: Search capability (ID Call 2) only available in Ultra
   - Monthly limits prevent abuse while allowing generous usage (120 scans/month)

---

**Document Purpose:** This summary provides an accurate snapshot of AlbumScan's current architecture, costs, and strategic direction as of November 4, 2025, reflecting the successful implementation of cost optimization strategies and two-tier subscription model ahead of App Store launch.
