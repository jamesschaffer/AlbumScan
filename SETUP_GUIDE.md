# AlbumScan Setup Guide

This guide will walk you through setting up the AlbumScan iOS project in Xcode.

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- iOS 16.0+ device or simulator
- **OpenAI API key** (required - primary identification service)
- Anthropic Claude API key (optional - backup service)

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

## Step 4: Set Up API Keys (Critical)

**Current Implementation:** The app uses `Secrets.plist` to load API keys at runtime.

### Create Secrets.plist (Required)

1. Create a new file: File → New → File → Property List
2. Name it `Secrets.plist`
3. Add to target: **AlbumScan** (check the box)
4. Add your API keys:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>OPENAI_API_KEY</key>
       <string>your-openai-api-key-here</string>
       <key>CLAUDE_API_KEY</key>
       <string>your-claude-api-key-here-optional</string>
   </dict>
   </plist>
   ```
5. **Important:** `Secrets.plist` is already in `.gitignore` - never commit API keys!
6. **Template Available:** See `Secrets.plist.template` for reference

### Alternative: Environment Variable (Development Only)

If you prefer environment variables during development:

1. Edit your scheme in Xcode:
   - Product → Scheme → Edit Scheme
   - Select "Run" → "Arguments"
   - Under "Environment Variables", add:
     - Name: `OPENAI_API_KEY`
     - Value: `your-openai-api-key-here`
2. **Note:** Config.swift checks Secrets.plist first, then falls back to environment variables

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

**Expected Behavior:**
- Loading Screen 1: "Flipping through every record bin in existence..." (2-4 seconds)
- Loading Screen 2: "We found [Album] by [Artist]" with artwork (2.5 seconds)
- Loading Screen 3: "Writing a review..." (3-5 seconds or instant if cached)
- Album Details: Full review with 8-tier recommendation label

These well-known albums should identify via ID Call 1 only (no search needed).

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

## Getting Your OpenAI API Key

1. Go to https://platform.openai.com/
2. Sign up or log in
3. Navigate to "API keys" in your account settings
4. Click "Create new secret key"
5. Name it (e.g., "AlbumScan Development")
6. Copy the key immediately and store it securely (you won't see it again)
7. Add billing information and set up usage limits (recommended: $10/month)

**Cost Expectations:**
- ID Call 1: ~$0.01 per scan
- ID Call 2 (10-20% of scans): ~$0.03-0.04 per scan
- Review Generation: ~$0.05-0.10 per new album (or $0 if cached)
- **Total: ~$0.10/day for 100 scans** with caching

## Getting Your Claude API Key (Optional Backup)

1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Navigate to API Keys
4. Create a new API key
5. Copy the key and store it securely

**Note:** Claude API is configured as a backup provider. To use it, change `Config.currentProvider` to `.claude` in Config.swift.

## Security Reminders

- ⚠️ NEVER commit your API key to git
- ⚠️ NEVER hardcode API keys in source files
- ⚠️ Use environment variables or secure storage
- ⚠️ Add `Secrets.plist` to `.gitignore` (already done)

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [CoreData Documentation](https://developer.apple.com/documentation/coredata)
- [AVFoundation Camera Guide](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Anthropic API Documentation](https://docs.anthropic.com/) (backup provider)
- **Project Documentation**: See `Project_Context/` directory for complete specification

---

**Ready to start developing!** 🎵

If you encounter any issues during setup, check `Project_Context/` directory for the complete specification (11 organized documents covering architecture, APIs, UX, testing, and more).
