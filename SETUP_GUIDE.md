# AlbumScan Setup Guide

This guide will walk you through setting up the AlbumScan iOS project in Xcode.

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- iOS 16.0+ device or simulator
- Anthropic Claude API key

## Step 1: Create Xcode Project

Since this is a SwiftUI app with CoreData, you'll need to create an Xcode project:

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "iOS" → "App"
4. Configure project:
   - **Product Name**: AlbumScan
   - **Team**: Your Apple Developer team
   - **Organization Identifier**: com.yourname.albumscan (or your preference)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: Core Data (check this box)
   - **Include Tests**: Yes
5. Save to: `/Users/jamesschaffer/Documents/Dev-Projects/AlbumScan`

## Step 2: Add Source Files to Xcode Project

All source files have been created in the correct directory structure. Now you need to add them to your Xcode project:

1. In Xcode, select the `AlbumScan` folder in the Project Navigator
2. Delete the default files created by Xcode (you'll replace them):
   - `ContentView.swift` (we have our own)
   - `AlbumScanApp.swift` (we have our own)
   - `AlbumScan.xcdatamodeld` (we have our own)

3. Right-click on `AlbumScan` folder → "Add Files to AlbumScan"
4. Navigate to the project directory and add these folders:
   - `Views/`
   - `ViewModels/`
   - `Models/`
   - `Services/`
   - `Utilities/`

5. Make sure "Copy items if needed" is UNCHECKED (files are already in correct location)
6. Make sure "Create groups" is selected
7. Make sure target "AlbumScan" is checked

## Step 3: Configure Info.plist

The `Info.plist` file has been created with the required camera permission description. Make sure it's added to your Xcode project:

1. Add `Info.plist` to the project if not already included
2. Verify it contains `NSCameraUsageDescription`

## Step 4: Set Up API Key

You need to configure your Claude API key. Choose one of these methods:

### Option A: Environment Variable (Recommended for Development)

1. Edit your scheme in Xcode:
   - Product → Scheme → Edit Scheme
   - Select "Run" → "Arguments"
   - Under "Environment Variables", add:
     - Name: `CLAUDE_API_KEY`
     - Value: `your-api-key-here`

### Option B: Create Secrets.plist (Gitignored)

1. Create a new file: File → New → File → Property List
2. Name it `Secrets.plist`
3. Add your API key:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CLAUDE_API_KEY</key>
       <string>your-api-key-here</string>
   </dict>
   </plist>
   ```
4. This file is already in `.gitignore`

## Step 5: Build Settings

Verify build settings:

1. Select the project in Project Navigator
2. Select "AlbumScan" target
3. Go to "General" tab:
   - **Minimum Deployments**: iOS 16.0
   - **Supported Destinations**: iPhone only

4. Go to "Signing & Capabilities":
   - Select your development team
   - Enable automatic signing

## Step 6: Build and Run

1. Select your target device (iOS 16.0+ device or simulator)
2. Press Cmd+B to build
3. Fix any build errors that appear (typically missing imports or configuration issues)
4. Press Cmd+R to run

## Common Build Issues

### Issue: "Cannot find type 'PersistenceController' in scope"

**Solution**: Make sure `PersistenceController.swift` is added to your target. Check the File Inspector (right panel) and ensure "AlbumScan" is checked under Target Membership.

### Issue: "No such module 'AVFoundation'"

**Solution**: Add import statement at top of files that use camera:
```swift
import AVFoundation
```

### Issue: Camera not working on simulator

**Solution**: Use a physical device for camera testing. Simulators have limited camera support.

### Issue: API key not found

**Solution**: Verify environment variable is set in your scheme (see Step 4).

## Testing the App

### First Launch Test
1. Launch app
2. Should see Welcome screen
3. Tap "Get Started"
4. Grant camera permission
5. Camera view should appear

### Camera Test
1. Point camera at any album cover
2. Tap "SCAN"
3. Should see loading spinner
4. Wait for API response (3-10 seconds)

### Test with Sample Album
For initial testing, use a well-known album cover like:
- Pink Floyd - Dark Side of the Moon
- Nirvana - Nevermind
- The Beatles - Abbey Road

These should have high success rates for identification.

## Next Steps After Setup

1. **Test camera permissions**: Verify camera access works
2. **Test API integration**: Try scanning a real album
3. **Test error handling**: Put device in airplane mode and scan
4. **Test history**: Scan multiple albums and check history view
5. **Review UI/UX**: Make adjustments to match your design preferences

## Development Workflow

1. **Make changes** in your preferred editor or Xcode
2. **Build** (Cmd+B) to check for errors
3. **Run** (Cmd+R) to test on device/simulator
4. **Test thoroughly** with real album covers
5. **Commit** to version control (git)

## Troubleshooting

If you encounter issues:

1. Clean build folder: Shift+Cmd+K
2. Restart Xcode
3. Check console for error messages
4. Verify all files are added to target
5. Check Info.plist for camera permissions

## Getting Your Claude API Key

1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Navigate to API Keys
4. Create a new API key
5. Copy the key and store it securely (you won't see it again)

## Security Reminders

- ⚠️ NEVER commit your API key to git
- ⚠️ NEVER hardcode API keys in source files
- ⚠️ Use environment variables or secure storage
- ⚠️ Add `Secrets.plist` to `.gitignore` (already done)

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [CoreData Documentation](https://developer.apple.com/documentation/coredata)
- [AVFoundation Camera Guide](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture)
- [Anthropic API Documentation](https://docs.anthropic.com/)

---

**Ready to start developing!** 🎵

If you encounter any issues during setup, check PROJECT_CONTEXT.md for the complete specification.
