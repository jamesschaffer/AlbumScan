# Privacy Policy for AlbumScan

**Last Updated:** October 24, 2025

## Overview

AlbumScan is committed to protecting your privacy. This privacy policy explains how our app collects, uses, and safeguards your information.

## Information We Collect

### Camera Access
AlbumScan requires access to your device's camera to scan album covers. Photos are only captured when you actively tap the "SCAN" button. We do not access your photo library or store images without your explicit action.

### Album Scan Data
When you scan an album cover, the following data is processed:
- **Photo of album cover** - captured via camera and sent to Anthropic's Claude API for identification
- **Album metadata** - including artist name, album title, release year, genre, and rating information
- **Album artwork** - downloaded from MusicBrainz Cover Art Archive

### Local Storage
Album scan results are stored locally on your device using CoreData. This includes:
- Album title and artist name
- Album artwork (thumbnail and high-resolution)
- Album ratings and recommendations
- Cultural context and track information
- Scan date and timestamp

## How We Use Your Information

### Album Identification
Photos you capture are sent to Anthropic's Claude API to identify the album. This is required for the core functionality of the app. Images are processed according to Anthropic's privacy policy: https://www.anthropic.com/legal/privacy

### Metadata Retrieval
We query the following third-party services to enrich album information:
- **MusicBrainz** - for album metadata (artist, title, release year, label, genre)
- **Cover Art Archive** - for official album artwork

These services may log API requests according to their respective privacy policies.

## Data Storage and Security

### Local Storage
All scan history and album data is stored locally on your device. This data:
- Never leaves your device except during the initial scan process
- Is not backed up to our servers (we don't have any servers)
- Remains under your control at all time
- Can be deleted at any time by deleting the app

### Third-Party Services
We use the following third-party services:
1. **Anthropic Claude API** - processes album cover images for identification
2. **MusicBrainz API** - provides album metadata
3. **Cover Art Archive** - provides official album artwork

## Data Sharing

We do NOT:
- Sell your data to third parties
- Share your data with advertisers
- Track your behavior across other apps or websites
- Collect analytics or usage statistics
- Store your data on remote servers (except as necessary for API processing)

Your album cover images are sent to Anthropic's API solely for identification purposes and are handled according to their privacy policy.

## Your Rights

You have the right to:
- **Access your data** - all scan history is visible in the app
- **Delete your data** - swipe to delete individual albums or delete the app entirely
- **Opt-out** - you can stop using the app at any time
- **Control camera access** - manage camera permissions in iOS Settings

## Children's Privacy

AlbumScan does not knowingly collect information from children under 13. The app is designed for music enthusiasts of all ages and does not require or collect personal information beyond album scans.

## Changes to This Policy

We may update this privacy policy from time to time. Changes will be reflected with an updated "Last Updated" date. Continued use of the app after changes constitutes acceptance of the updated policy.

## Data Retention

- **Scan history** - stored locally on your device until you delete it
- **API requests** - processed images are not retained by us (see Anthropic's policy)
- **Cache data** - album artwork and metadata may be cached locally for performance

## Your Consent

By using AlbumScan, you consent to this privacy policy.

## Contact Us

If you have questions about this privacy policy or your data, please contact:

**Email:** [Your email address]
**GitHub:** https://github.com/jamesschaffer/AlbumScan

## Third-Party Privacy Policies

- **Anthropic Claude API:** https://www.anthropic.com/legal/privacy
- **MusicBrainz:** https://musicbrainz.org/doc/About/Privacy_Policy
- **Cover Art Archive:** Operated by Internet Archive - https://archive.org/about/terms.php

---

## Summary

**What we collect:** Album cover photos (temporarily), scan results (stored locally)
**Why we collect it:** To identify albums and provide music information
**Where it goes:** Anthropic API (for identification), MusicBrainz/Cover Art Archive (for metadata)
**What we don't do:** Sell data, track you, store data on our servers, share with advertisers
**Your control:** Delete scans anytime, manage camera permissions, delete app to remove all data
