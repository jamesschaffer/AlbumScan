# AlbumScan - Quick Start Checklist

Follow this checklist to get your AlbumScan project up and running.

## ✅ Pre-Setup Checklist

- [ ] macOS 13.0+ installed
- [ ] Xcode 15.0+ installed
- [ ] Apple Developer account (free or paid)
- [ ] Anthropic Claude API key obtained
- [ ] iOS 16.0+ device or simulator ready

## 📋 Setup Steps

### Step 1: Review Project Documentation
- [ ] Read `README.md` for project overview
- [ ] Read `PROJECT_CONTEXT.md` for complete specification
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

### Step 5: Set Up API Key
Choose one method:

**Option A: Environment Variable** (Recommended)
- [ ] Edit Scheme → Run → Arguments tab
- [ ] Add environment variable: `CLAUDE_API_KEY`
- [ ] Paste your API key as the value

**Option B: Secrets.plist**
- [ ] Create `Secrets.plist` file
- [ ] Add your API key
- [ ] Verify file is in `.gitignore`

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
- [ ] Loading spinner appears
- [ ] "Identifying album..." text shows
- [ ] Wait 3-10 seconds
- [ ] Album details appear
- [ ] All information displays correctly:
  - [ ] Album artwork
  - [ ] Artist name
  - [ ] Album title
  - [ ] Recommendation badge (with emoji)
  - [ ] Context summary
  - [ ] Bullet points
  - [ ] Rating
  - [ ] Key tracks
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
- [ ] Error message appears
- [ ] "TRY AGAIN" button works
- [ ] Returns to camera view

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

### API key not found
- **Problem**: "API key not configured" error
- **Solution**: Verify environment variable is set in scheme

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

- [ ] API key NOT hardcoded in source
- [ ] `.gitignore` includes `Secrets.plist`
- [ ] `.gitignore` includes environment files
- [ ] No sensitive data in git history
- [ ] Camera permission properly described in Info.plist

## 📊 Performance Checklist

- [ ] App launches in < 2 seconds
- [ ] Camera feed starts immediately
- [ ] API response in 3-10 seconds
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

## ✨ Next Steps After MVP

Once the MVP is working:
1. Test with 20+ different albums
2. Gather feedback from friends
3. Refine UI based on usage
4. Consider adding features from "Out of Scope" list
5. Optimize API costs with caching
6. Prepare for App Store submission

## 📚 Resources

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Complete specification
- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - Code organization
- [README.md](README.md) - Project overview

---

**Ready to build!** 🚀

Start with Step 1 and work through each section. Good luck with your AlbumScan project!
