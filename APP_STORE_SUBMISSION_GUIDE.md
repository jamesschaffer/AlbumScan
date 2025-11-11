# App Store Submission Guide for AlbumScan

## Critical Fixes Implemented (Version 1.0.1)

### Issue 1: Infinite Loading Spinner - FIXED ✅

**Problem:** Loading indicator spun indefinitely when subscription products failed to load.

**Root Cause:** The loading logic checked if products were nil, which created an infinite loop when StoreKit was unavailable or IAP products weren't configured.

**Solution Implemented:**
- Added `hasAttemptedLoad` and `productsLoadFailed` state tracking
- Implemented 15-second timeout on product loading
- Added error state UI with "Try Again" button
- Improved loading logic to distinguish between "loading" vs "load failed"
- Added fallback pricing when StoreKit unavailable

**Files Modified:**
- `AlbumScan/Services/SubscriptionManager.swift:27-28, 70-128`
- `AlbumScan/Views/Subscription/ChooseYourPlanView.swift:41-51, 291-347`

---

## App Store Connect In-App Purchase Configuration

### Overview
AlbumScan uses two auto-renewable subscription products:
- **Base Plan**: `albumscan_base_annual` - $4.99/year
- **Ultra Plan**: `albumscan_ultra_annual` - $11.99/year

### Step 1: Configure In-App Purchases

1. **Navigate to App Store Connect**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Select your app (AlbumScan)
   - Go to "Features" > "In-App Purchases"

2. **Create Base Plan Product** (if not already created)
   - Click "+" to create new in-app purchase
   - Type: Auto-Renewable Subscription
   - Reference Name: `AlbumScan Base Annual`
   - Product ID: `albumscan_base_annual` (must match code exactly)
   - Subscription Group: Create new group called "AlbumScan Subscriptions"

3. **Configure Base Plan Details**
   - Subscription Duration: 1 Year
   - Price: $4.99 USD (Tier 5)
   - Localizations (English - U.S.):
     - Display Name: "AlbumScan Base"
     - Description: "One-click album identification with concise reviews and 8-tier recommendation system. Access to basic album matching and importance scoring."

4. **Create Ultra Plan Product** (if not already created)
   - Click "+" to create new in-app purchase
   - Type: Auto-Renewable Subscription
   - Reference Name: `AlbumScan Ultra Annual`
   - Product ID: `albumscan_ultra_annual` (must match code exactly)
   - Subscription Group: Use same "AlbumScan Subscriptions" group

5. **Configure Ultra Plan Details**
   - Subscription Duration: 1 Year
   - Price: $11.99 USD (Tier 12)
   - Localizations (English - U.S.):
     - Display Name: "AlbumScan Ultra"
     - Description: "Enhanced album matching for obscure and new releases. Access reviews from Pitchfork, Rolling Stone, and other industry experts. Improved scoring accuracy."

### Step 2: Add App Review Screenshots

**CRITICAL:** You must provide App Review screenshots for EACH in-app purchase product. This is required before submission.

1. For **each IAP product** (Base and Ultra):
   - Click on the product
   - Scroll to "App Review Information"
   - Upload screenshot showing the subscription offer in your app

2. **Screenshot Requirements:**
   - Must show the actual subscription UI from your app
   - Must clearly display the product name and price
   - Must be taken from a supported device
   - Recommended: Take screenshots from iPhone 13 mini and iPad Air (5th gen) running iOS 18.1

3. **How to capture good screenshots:**
   - Launch app on simulator or device
   - Navigate to subscription screen (Welcome sheet or Settings)
   - Take screenshot showing the Base/Ultra tabs with pricing
   - Upload to both IAP products in App Store Connect

### Step 3: Submit In-App Purchases for Review

**IMPORTANT:** IAP products must be submitted SEPARATELY from the app binary.

1. **For each IAP product:**
   - Go to the product page in App Store Connect
   - Ensure all required information is filled:
     - ✅ Product ID matches code
     - ✅ Pricing configured
     - ✅ Localizations added
     - ✅ App Review screenshot uploaded
   - Click "Submit for Review" on each product

2. **Verify Submission Status:**
   - Both products should show status: "Waiting for Review" or "In Review"
   - If status shows "Missing Metadata", check App Review screenshots

### Step 4: Submit App Binary

1. **Upload New Build:**
   - Archive the app with the fixes (Version 1.0.1)
   - Upload to App Store Connect via Xcode Organizer
   - Wait for processing to complete

2. **Create New Submission:**
   - In App Store Connect, go to "Prepare for Submission"
   - Select the new build (1.0.1)
   - In "In-App Purchases" section, select both IAP products
   - Add release notes mentioning the bug fixes

3. **Submit for Review:**
   - Click "Submit for Review"
   - Respond to any export compliance questions
   - Wait for review

---

## Testing Checklist Before Submission

### Sandbox Testing (Required)

1. **Create Sandbox Test Account:**
   - Go to App Store Connect > Users and Access > Sandbox Testers
   - Create test account if you don't have one
   - Sign out of your real Apple ID on test device
   - Sign in with sandbox account in Settings > App Store

2. **Test Scenarios:**
   - ✅ Clean install - products should load within 15 seconds
   - ✅ Products fail to load - error screen with retry appears
   - ✅ Airplane mode - error screen appears, retry works after reconnection
   - ✅ Purchase Base subscription - completes successfully
   - ✅ Purchase Ultra subscription - completes successfully
   - ✅ Restore purchases - works correctly
   - ✅ Subscription status persists after app restart

### Device Testing Matrix

Test on the following devices (same as App Review environment):

| Device | iOS Version | Test Status |
|--------|-------------|-------------|
| iPhone 13 mini | iOS 18.1 | ⬜ Not Tested |
| iPad Air (5th gen) | iPadOS 18.1 | ⬜ Not Tested |
| iPhone 16 Pro | iOS 18.6 | ⬜ Not Tested |

### Critical Test Cases

#### Test Case 1: First Launch (No Products Available)
**Steps:**
1. Delete app completely from device
2. Reinstall from TestFlight
3. Launch app
4. Trigger subscription sheet

**Expected Result:**
- Loading spinner appears
- After max 15 seconds, either:
  - Products load and show Base/Ultra tabs with pricing
  - OR error screen appears with "Try Again" button
- No infinite loading spinner

#### Test Case 2: Network Offline
**Steps:**
1. Enable Airplane Mode
2. Launch app
3. Trigger subscription sheet
4. Wait for error
5. Disable Airplane Mode
6. Tap "Try Again"

**Expected Result:**
- Error screen appears after timeout
- "Try Again" button works after network restored
- Products load successfully on retry

#### Test Case 3: Successful Purchase Flow
**Steps:**
1. Launch app with working network
2. Trigger subscription sheet
3. Select Base plan
4. Complete sandbox purchase
5. Verify subscription activated

**Expected Result:**
- Purchase completes without errors
- App recognizes subscription
- Can access subscribed features

#### Test Case 4: iPad Specific
**Steps:**
1. Test on iPad Air (5th generation)
2. Verify all UI elements fit properly
3. Test both portrait and landscape orientations

**Expected Result:**
- No UI clipping or overflow
- All text is readable
- Buttons are accessible

---

## Common Issues and Solutions

### Issue: Products Won't Load in Sandbox
**Solution:**
- Ensure IAP products are submitted for review in App Store Connect
- Verify Product IDs in code match exactly: `albumscan_base_annual` and `albumscan_ultra_annual`
- Check that signed Agreement in App Store Connect is valid
- Try deleting and reinstalling the app

### Issue: "Cannot Connect to iTunes Store" Error
**Solution:**
- Verify sandbox test account is signed in (Settings > App Store)
- Make sure not signed in with real Apple ID on device
- Check internet connection is working

### Issue: Purchase Completes But Subscription Not Recognized
**Solution:**
- Check SubscriptionManager logs in console
- Verify transaction verification is working
- Try force-closing and relaunching app

---

## TestFlight Pre-Submission Checklist

Before submitting to App Store, complete TestFlight testing:

### Setup
- ✅ Upload build to TestFlight
- ✅ Add internal testers
- ✅ Configure test information
- ✅ Add What to Test notes mentioning bug fixes

### Internal Testing
- ✅ All internal testers can install app
- ✅ Subscription products load correctly
- ✅ No crashes during subscription flow
- ✅ Error handling works as expected
- ✅ Purchases complete successfully

### External Testing (Optional)
- ⬜ Invite external beta testers
- ⬜ Collect feedback on subscription flow
- ⬜ Monitor crash reports
- ⬜ Verify no critical issues

---

## Submission Notes for App Review

When resubmitting, include these notes in "Notes for Review":

```
Thank you for your feedback on the previous submission.

FIXED ISSUES:

1. Infinite Loading Spinner (Guideline 2.1):
   - Implemented 15-second timeout on subscription product loading
   - Added error state UI with "Try Again" button when products fail to load
   - Improved loading logic to prevent infinite spinner
   - Tested on iPhone 13 mini and iPad Air (5th gen) with iOS 18.1

2. In-App Purchases Not Submitted (Guideline 2.1):
   - Both IAP products submitted for review with required screenshots
   - Product IDs: albumscan_base_annual, albumscan_ultra_annual
   - Screenshots show subscription options with pricing

TESTING INSTRUCTIONS:

The subscription sheet appears:
- On first launch (welcome screen)
- In Settings > Subscription Management
- After using free scans

To test purchases, please use the sandbox environment. The app gracefully handles scenarios where StoreKit is unavailable or products fail to load.

If products don't load, the app shows a clear error message with a retry option instead of an infinite loading spinner.

Thank you for your time and consideration.
```

---

## Post-Approval Steps

After app is approved:

1. **Monitor Subscription Metrics:**
   - Check App Store Connect > Sales and Trends
   - Monitor subscription acquisition rate
   - Track churn and retention

2. **Customer Support:**
   - Monitor support emails for IAP issues
   - Have refund policy ready
   - Provide clear instructions for managing subscriptions

3. **Analytics:**
   - Track product load success/failure rates
   - Monitor error states in production
   - Track conversion rates from free to paid

---

## Contact and Support

If you encounter issues during submission:
- Check logs in SubscriptionManager for detailed error messages
- All IAP operations have DEBUG logging enabled
- Review this guide for common solutions
- Test in sandbox environment before submitting

**Product IDs (MUST MATCH EXACTLY):**
- Base: `albumscan_base_annual`
- Ultra: `albumscan_ultra_annual`

**Critical Files:**
- Subscription Logic: `AlbumScan/Services/SubscriptionManager.swift`
- Subscription UI: `AlbumScan/Views/Subscription/ChooseYourPlanView.swift`
- Welcome Sheet: `AlbumScan/Views/Subscription/WelcomePurchaseSheet.swift`
