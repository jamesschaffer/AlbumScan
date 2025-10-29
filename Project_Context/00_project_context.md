# AlbumScan - Project Context Documentation

**Version:** 1.4 (Subscription Implementation)
**Last Updated:** October 29, 2025
**Platform:** iOS (Minimum iOS 16+)
**Development Stack:** Swift + SwiftUI

---

## TABLE OF CONTENTS

### **01_summary.md** - Project Overview & Business Model
High-level project description, value proposition, four-phase API architecture, cost estimates, and revenue model.

### **02_user_personas.md** - Target User Profiles
Detailed profiles of primary and secondary target users including goals, pain points, and collection philosophies.

### **03_core_features.md** - Feature Specifications
Complete requirements and acceptance criteria for the 4 core MVP features: camera identification, cultural context, album display, and scan history.

### **04_user_flows.md** - User Journey Maps
Step-by-step flows for all user interactions from onboarding through scanning, history management, and error scenarios.

### **05_screen_architecture.md** - Screen Specifications
Detailed design specs for every screen including layouts, navigation, loading states, and error handling.

### **06_apis.md** - Two-Tier Identification System & Data Model
Technical specification of the two-tier identification architecture, data structures, caching mechanisms, and CoreData schema.

### **07_ux.md** - UI/UX Principles & Design Patterns
UX principles, brand identity, design system guidelines, performance targets, accessibility requirements, error handling philosophy, and reusable design patterns.

### **08_qa.md** - Testing Strategy
Unit test, integration test, and manual test plans including real-world testing requirements and test data sets.

### **09_security_privacy.md** - Security & Privacy Requirements
API key management, data privacy policies, and privacy-first architecture documentation.

### **10_prompt_management.md** - Prompt Engineering Strategy
AI prompt file management, version control strategy, and cost optimization through prompt engineering.

---

## DOCUMENT EVOLUTION TIMELINE

### Version 1.0 (Initial Design - Claude API)
Single-call API architecture with vision, identification, and review in one prompt using Claude Sonnet 4.5.

### Version 1.1 (Four-Phase Architecture - Claude API)
Split into Phase 1A (vision extraction), Phase 1B (web search mapping), Phase 2 (artwork retrieval), and Phase 3 (review generation) using Claude Sonnet 4.5 with Exa.ai search integration.

### Version 1.2 (OpenAI Migration - October 2025)
Complete migration from Claude API to OpenAI API. Implemented two-tier identification system: ID Call 1 (`gpt-4o`, no search) → ID Call 2 conditional (`gpt-4o-search-preview` with search gate validation). Maintained four-phase structure with artwork retrieval and review generation.

### Version 1.3 (Cost Optimization - October 2025)
Implemented aggressive caching, title normalization, prompt optimizations, and switched to regular `gpt-4o` for reviews (eliminating hidden search costs). Achieved 98% cost reduction ($5.15/day → $0.10/day). Final architecture: Two-tier identification (ID Call 1 + conditional ID Call 2) → Artwork Retrieval → Review Generation.

### Version 1.4 (Subscription Implementation - October 2025)
Added freemium model: 10 free scans with Keychain persistence, $4.99/year unlimited subscription, Firebase Remote Config kill switch, StoreKit 2 validation.

---

## CURRENT STATE (October 29, 2025)

**Active Branch:** project-context (documentation restructure)
**Production Branch:** main (cost optimizations merged)
**API Costs:** $0.10/day for 100 scans (98% reduction achieved)
**Pending Work:** Subscription testing, App Store Connect setup, real-world testing

---

## NAVIGATING THIS DOCUMENTATION

**Product/Design:** Start with 01, 02, 03
**Technical Implementation:** Read 06, 07, 10
**Testing:** See 08
**Business/Monetization:** Review 01 and evolution timeline
**Privacy/Security:** Consult 09
**User Experience:** Study 04 and 05

---

**Document Maintainer:** Project team
**Review Frequency:** After each major feature branch merge
**Version Control:** All files tracked in Git under Project_Context/

---

## Verification Summary

**Document Accuracy:** This table of contents has been verified and updated to reflect the actual codebase implementation as of October 29, 2025.

**Major Corrections Made:**

1. **06_apis.md Description:**
   - **Before:** "Four-Phase API Architecture & Data Model"
   - **After:** "Two-Tier Identification System & Data Model"
   - **Reason:** Architecture has evolved to two-tier identification with conditional search

2. **07_ux.md Description:**
   - **Before:** "UI/UX Requirements"
   - **After:** "UI/UX Principles & Design Patterns"
   - **Reason:** Document has been significantly enhanced to focus on UX principles and reusable design patterns

3. **Architecture Evolution Timeline:**
   - **Corrected Version 1.0:** Added "Claude API" context
   - **Corrected Version 1.1:** Changed from "Two-Phase" to "Four-Phase Architecture - Claude API" (historical accuracy)
   - **Added Version 1.2:** Documented OpenAI migration and two-tier identification implementation
   - **Enhanced Version 1.3:** Added specific architecture details and hidden search cost elimination
   - **Maintained Version 1.4:** Subscription implementation details accurate

**Architecture Evolution Clarified:**
- **Version 1.0-1.1:** Claude API (Sonnet 4.5) with Exa.ai search
- **Version 1.2:** Migration to OpenAI with two-tier identification (`gpt-4o` + `gpt-4o-search-preview`)
- **Version 1.3:** Cost optimization with regular `gpt-4o` for reviews (current implementation)
- **Version 1.4:** Subscription monetization layer

**Current Implementation (October 29, 2025):**
- **API Provider:** OpenAI (not Claude)
- **Architecture:** Two-tier identification system
- **ID Call 1:** `gpt-4o` (no search capability)
- **ID Call 2:** `gpt-4o-search-preview` (conditional, with search gate)
- **Review Generation:** `gpt-4o` (no search capability)
- **Cost per 100 scans:** $0.10/day

**Status:** Table of contents now accurately reflects the current two-tier architecture and complete project evolution history