# PROJECT SUMMARY
# AlbumScan - Music Album Discovery iOS App

**Version:** 1.3 (Two-Tier Identification with Cost Optimizations)
**Last Updated:** October 29, 2025
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

### Freemium Model (In Development)

**Free Tier:**
- 10 free scans per user
- Stored in iOS Keychain (survives app reinstall)
- 95% reinstall protection (only tech-savvy users can bypass)

**Unlimited Subscription:**
- **Price:** $4.99/year (USA only at launch)
- **Features:** Unlimited album scans
- **Implementation:** StoreKit 2 with local transaction validation (no backend)
- **Kill Switch:** Firebase Remote Config for emergency controls

**Unit Economics:**
- Cost per scan: ~$0.10 (average with cache hits)
- Annual revenue per subscriber: $4.99
- Break-even: ~50 scans/year per subscriber
- Target user: Music enthusiasts who scan >10 albums/year

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
- Main branch has merged cost optimizations (98% reduction achieved)
- Current daily cost: $0.10 for 100 scans
- OpenAI as primary provider

**In Development (subscription-setup branch):**
- Freemium subscription system
- 10 free scans with Keychain persistence
- $4.99/year unlimited subscription
- Firebase Remote Config integration
- StoreKit 2 local validation

**Pending Work:**
- Subscription system testing
- App Store Connect subscription product setup
- Real-world testing at record stores
- Long-term cost monitoring to validate 98% savings

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

---

**Document Purpose:** This summary provides an accurate snapshot of AlbumScan's current architecture, costs, and strategic direction as of October 29, 2025, reflecting the successful implementation of cost optimization strategies.
