# PROJECT_CONTEXT.md
# AlbumScan - Music Album Discovery iOS App - Complete Development Guide

## USER PERSONAS

### Primary Persona: "Record Store Browser Sarah"
- **Demographics:** 28 years old, urban professional, moderate vinyl collector
- **Goals/Needs:** 
  - Discover musically significant albums while digging through bins
  - Learn about albums that influenced her favorite contemporary artists
  - Find hidden gems and culturally important records she's never heard of
  - Understand why certain albums are considered classics or important
  - Remember discoveries so she can listen to them later (on her own via Spotify/Apple Music/etc.)
- **Pain Points:** 
  - Surrounded by thousands of albums but doesn't know their musical significance
  - Doesn't want to just buy "valuable" records - wants artistically meaningful ones
  - Can't tell which obscure album might be an influential masterpiece
  - Frustrated by price-focused collecting culture - she cares about the music
  - Forgets album names by the time she gets home to look them up
- **Technical Proficiency:** High - comfortable with modern apps and streaming services
- **Collection Philosophy:** "I collect albums that move me or taught me something about music, not albums that are worth money"

### Secondary Persona: "Vinyl Enthusiast Mike"
- **Demographics:** 45 years old, seasoned music lover with 500+ records
- **Goals/Needs:**
  - Discover the musical stories behind unfamiliar albums
  - Understand an album's place in music history and its influence
  - Learn about artists he's never encountered before
  - Find connections between albums (samples, influences, collaborations)
  - Share musical knowledge and discoveries with fellow enthusiasts
- **Pain Points:**
  - Tired of apps that only tell him what an album is "worth"
  - Wants to know WHY an album matters, not what it sells for
  - Difficult to quickly assess musical significance of unknown albums
  - Estate sales and thrift stores full of albums with no context about their artistry
  - Time-consuming to research every interesting album cover he sees
- **Technical Proficiency:** Moderate - uses smartphone regularly but not highly technical
- **Collection Philosophy:** "I dig for music that expanded boundaries or captured a moment in time, not for investment pieces"

### Secondary Persona: "Genre Explorer Jordan"
- **Demographics:** 19-24 years old, college student or recent grad, first apartment, limited budget
- **Collection Status:** Just started collecting (5-20 albums), may have inherited parents'/grandparents' records
- **Goals/Needs:**
  - Learn fundamentals of music history and understand what makes albums significant
  - Build confidence at record stores and avoid feeling intimidated by knowledgeable collectors
  - Understand genre foundations and differences (shoegaze vs dream pop, classic rock vs prog rock)
  - Validate inherited or gifted albums - which ones should actually be kept and listened to
  - Avoid embarrassing purchases on a limited budget
  - Fill gaps in musical literacy without asking "dumb questions" about famous albums
- **Pain Points:**
  - Imposter syndrome at record stores - feels like everyone knows more
  - Overwhelming choice with no framework for "where to start" with decades of music history
  - Genre confusion - streaming algorithms don't explain WHY albums are important
  - Social anxiety about revealing musical ignorance to friends or dates
  - Budget constraints - can't afford to buy "wrong" albums when building from zero
  - Gap between knowing albums are "important" and understanding why they matter
- **Technical Proficiency:** Very high (digital native) but low music historical literacy
- **Collection Philosophy:** "I want to understand what makes music important so I can form my own taste, not just follow what TikTok or Spotify tells me to like"
- **Key Behavioral Difference:** Uses app for education and confidence-building, not just discovery. Scans higher volume during learning phase (inherited collections, store browsing for education, pre-purchase research).
- **Unique Use Cases:** Inherited collection triage, pre-purchase research before engaging with store staff, social preparation (scanning friend's collection before listening party), deliberately scanning canonical albums to build foundational knowledge

---

## Verification Summary

**Document Accuracy:** This document has been verified against the actual codebase implementation and app purpose as of October 29, 2025.

**Verification Notes:**

**User Personas Alignment:**
- All three personas (Sarah, Mike, Jordan) accurately reflect the target users for AlbumScan
- Core values emphasized in personas match the app's actual implementation:
  - Focus on musical significance over financial value ✓
  - Cultural importance and music history education ✓
  - Discovery and learning about albums ✓
  - Remembering albums for later listening on streaming services ✓

**No Corrections Required:**
- This document contains no technical implementation details
- No references to outdated architecture (no "four-phase" mentions)
- User goals and pain points remain accurate regardless of API backend changes
- Collection philosophies align with the app's music-focused (not price-focused) approach

**Feature Alignment Verified:**
- **Sarah's needs** → Met by scan history (remembering discoveries), cultural context reviews (understanding significance)
- **Mike's needs** → Met by honest reviews that explain WHY albums matter, not what they're worth
- **Jordan's needs** → Met by educational review content, 8-tier recommendation system, confidence-building through knowledge

**Persona Use in Development:**
- These personas informed the review prompt design (no pricing/investment language)
- Jordan persona justifies high scan volume expectations (inherited collection triage, educational scanning)
- Sarah persona validates scan history feature (remembering for later streaming)
- Mike persona validates focus on cultural significance over market value

**Status:** Document is accurate and requires no corrections. User personas continue to guide feature development and app positioning