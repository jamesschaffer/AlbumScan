# AlbumScan - Quick Start Checklist

Follow this checklist to get your AlbumScan project up and running.

## ✅ Pre-Setup Checklist

- [ ] macOS 13.0+ installed
- [ ] Xcode 15.0+ installed
- [ ] Apple Developer account (free or paid)
- [ ] Firebase project configured (for Cloud Functions)
- [ ] OpenAI API key obtained (for development/debugging)
- [ ] iOS 16.0+ device ready (camera required)

## 📋 Setup Steps

### Step 1: Review Project Documentation
- [ ] Read `README.md` for project overview
- [ ] Read `Project_Context/` directory for complete specification
- [ ] Read `FILE_STRUCTURE.md` to understand code organization

### Step 2: Create Xcode Project
Follow `SETUP_GUIDE.md` for detailed instructions:

- [ ] Open Xcode
- [ ] Create new iOS App project
- [ ] Name: **AlbumScan**
- [ ] Interface: **SwiftUI**
- [ ] Language: **Swift**
- [ ] Storage: **Core Data** (checked)
- [ ] Save location: `/Users/jamesschaffer/Documents/Dev-Projects/AlbumScan`

### Step 3: Add Source Files to Xcode
- [ ] Delete default `ContentView.swift`
- [ ] Delete default `AlbumScanApp.swift`
- [ ] Delete default `.xcdatamodeld` file
- [ ] Add `Views/` folder to project
- [ ] Add `ViewModels/` folder to project
- [ ] Add `Models/` folder to project
- [ ] Add `Services/` folder to project
- [ ] Add `Utilities/` folder to project
- [ ] Add `Info.plist` to project
- [ ] Verify all files show in Project Navigator

### Step 4: Configure Build Settings
- [ ] Set minimum iOS deployment to **16.0**
- [ ] Set supported devices to **iPhone only**
- [ ] Configure signing (select your team)
- [ ] Enable automatic signing

### Step 5: Configure API Access
Choose one method:

**Option A: Cloud Functions (Production - Recommended)**
- [ ] Follow `CLOUD_FUNCTIONS_SETUP.md` for deployment
- [ ] Set OpenAI API key in Firebase Secrets: `firebase functions:secrets:set OPENAI_API_KEY`
- [ ] Ensure `Config.currentProvider = .cloudFunctions` in Config.swift

**Option B: Direct API (Development Only)**
- [ ] Create `Secrets.plist` file with `OPENAI_API_KEY`
- [ ] Verify file is in `.gitignore`
- [ ] Change `Config.currentProvider` to `.openAI` for development

### Step 6: Build and Test
- [ ] Clean build folder (⇧⌘K)
- [ ] Build project (⌘B)
- [ ] Fix any build errors
- [ ] Run on simulator (⌘R)
- [ ] Test on physical device (recommended for camera)

## 🧪 Testing Checklist

### First Launch Test
- [ ] App launches successfully
- [ ] Welcome screen appears
- [ ] "Get Started" button works
- [ ] Camera permission requested
- [ ] Camera view appears after granting permission

### Camera Test
- [ ] Camera feed displays
- [ ] Square framing guide visible
- [ ] "SCAN" button appears
- [ ] History icon hidden (no scans yet)

### Album Scan Test
Use a well-known album for testing:
- [ ] Point at album cover
- [ ] Tap "SCAN" button
- [ ] Loading stage 1a: "Extracting text and examining album art..." (0-3.5s)
- [ ] Loading stage 1b: "Flipping through every record bin in existence..." (3.5s+)
- [ ] Loading stage 2: "We found [Album] by [Artist]" with artwork (2s confirmation)
- [ ] Loading stage 3: "Writing a review that's somehow both pretentious and correct..."
- [ ] Wait 5-13 seconds total
- [ ] Album details appear
- [ ] All information displays correctly:
  - [ ] Album artwork (from Cover Art Archive)
  - [ ] Artist name
  - [ ] Album title
  - [ ] 8-tier recommendation badge (e.g., "ESSENTIAL CLASSIC")
  - [ ] Context summary (2-3 sentences)
  - [ ] Evidence bullets (3-5 points)
  - [ ] Rating out of 10
  - [ ] Key tracks (3-7 tracks)
  - [ ] Metadata (year, genre, label)

### History Test
- [ ] History icon now visible on camera view
- [ ] Tap history icon
- [ ] Scanned album appears in list
- [ ] Album has thumbnail, title, artist, date
- [ ] Tap album in history
- [ ] Details view opens
- [ ] Swipe left on album
- [ ] Delete button appears
- [ ] Delete removes album from history

### Error Handling Test
- [ ] Enable airplane mode
- [ ] Try to scan album
- [ ] Error banner appears at top (auto-dismisses in 3 seconds)
- [ ] Camera returns to ready state
- [ ] Disable airplane mode
- [ ] Scan successfully completes

### Permission Test
- [ ] Deny camera permission in Settings
- [ ] Launch app
- [ ] Permission error screen appears
- [ ] "Open Settings" button works
- [ ] Grant permission in Settings
- [ ] Return to app
- [ ] Camera view appears

## 🎯 Recommended Test Albums

These albums should identify easily:
- Pink Floyd - "The Dark Side of the Moon"
- Nirvana - "Nevermind"
- The Beatles - "Abbey Road"
- Fleetwood Mac - "Rumours"
- Michael Jackson - "Thriller"

## 🐛 Common Issues & Solutions

### Camera not working
- **Problem**: Camera feed is black or frozen
- **Solution**: Use physical device; simulator has limited camera support

### Cloud Functions not responding
- **Problem**: "An unexpected error occurred" error
- **Solution**:
  1. Verify Cloud Functions deployed: `firebase deploy --only functions`
  2. Check Firebase console for function logs
  3. Ensure App Check is configured correctly

### API key not found (Direct API mode)
- **Problem**: "API key not configured" error
- **Solution**: Verify `Secrets.plist` exists with `OPENAI_API_KEY` key

### Build errors
- **Problem**: "Cannot find type in scope" errors
- **Solution**: Check file target membership; ensure all files are added to AlbumScan target

### CoreData errors
- **Problem**: CoreData context errors
- **Solution**: Verify `.xcdatamodeld` file is properly added to project

### Album art not showing
- **Problem**: Grey placeholder instead of album art
- **Solution**: Check API response includes `album_art_url`; verify network connection

## 📱 Deployment Checklist

### Before Testing on Device
- [ ] Connect iPhone via USB
- [ ] Trust computer on iPhone
- [ ] Select iPhone as run destination in Xcode
- [ ] Build and run (⌘R)
- [ ] Grant camera permissions on device

### Before Submitting to App Store (Future)
- [ ] Complete all MVP features
- [ ] Test on multiple iOS versions
- [ ] Test on different iPhone models
- [ ] Create app icon
- [ ] Create App Store screenshots
- [ ] Write privacy policy
- [ ] Prepare App Store listing
- [ ] Submit for review

## 🔐 Security Checklist

- [ ] API keys stored in Firebase Secrets Manager (production)
- [ ] `Secrets.plist` in `.gitignore` (development)
- [ ] No sensitive data in git history
- [ ] Camera permission properly described in Info.plist
- [ ] Firebase App Check enabled and enforced
- [ ] Rate limiting active (10 req/min/device)

## 📊 Performance Checklist

- [ ] App launches in < 2 seconds
- [ ] Camera feed starts immediately
- [ ] ID Call 1 completes in 2-4 seconds
- [ ] Full scan with review in 5-13 seconds
- [ ] History scrolls smoothly
- [ ] No memory leaks (test in Instruments)
- [ ] Works on iOS 16.0+ devices

## 🎨 UI/UX Checklist

- [ ] App works in light mode
- [ ] App works in dark mode
- [ ] Text is readable at all sizes
- [ ] Tap targets are minimum 44x44pt
- [ ] Animations are smooth (60fps)
- [ ] Loading states are clear
- [ ] Error messages are helpful

## ✨ Next Steps After Setup

Once the app is running:
1. Test with 20+ different albums across genres
2. Verify subscription flow works correctly
3. Test error handling and edge cases
4. Monitor Firebase console for function logs
5. Check cost tracking in OpenAI dashboard

## 📚 Resources

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed Xcode setup instructions
- [CLOUD_FUNCTIONS_SETUP.md](CLOUD_FUNCTIONS_SETUP.md) - Firebase deployment
- [Project_Context/](Project_Context/) - Complete 11-document specification
- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - Code organization
- [README.md](README.md) - Project overview

---

**Ready to build!**

Start with Step 1 and work through each section. Good luck with your AlbumScan project!
