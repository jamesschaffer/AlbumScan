# AlbumScan Testing Checklist - App Store Submission v1.0.1

## Overview
This checklist covers all critical test scenarios that must pass before submitting to App Store.
Focus on the fixes for Guideline 2.1 violations (infinite loading spinner and IAP submission).

---

## Test Environment Setup

### Required Test Devices
Match Apple's review environment as closely as possible:

- [ ] iPhone 13 mini (or simulator) - iOS 18.1
- [ ] iPad Air (5th generation) (or simulator) - iPadOS 18.1
- [ ] Additional device: iPhone 16 Pro - iOS 18.6 (recommended)

### Sandbox Account Setup
- [ ] Created sandbox tester account in App Store Connect
- [ ] Signed out of production Apple ID on test device
- [ ] Signed in with sandbox account (Settings > App Store)
- [ ] Verified sandbox account email received confirmation

### App Configuration
- [ ] Build 1.0.1 (or higher) with subscription fixes installed
- [ ] Debug logging enabled for SubscriptionManager
- [ ] Network connectivity available
- [ ] IAP products submitted in App Store Connect

---

## Critical Bug Fixes Verification

### Fix #1: Infinite Loading Spinner

#### Test Case 1.1: Products Load Successfully
**Priority:** CRITICAL ⚠️

**Pre-conditions:**
- Clean install of app
- Network connected
- IAP products configured in App Store Connect

**Steps:**
1. Launch app for first time
2. Proceed to subscription screen
3. Observe loading state

**Expected Results:**
- [ ] Loading spinner appears with "Loading subscription options..." message
- [ ] Products load within 15 seconds
- [ ] Base and Ultra tabs display with correct pricing
- [ ] No infinite spinner
- [ ] All UI elements render correctly

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

#### Test Case 1.2: Products Fail to Load - Error State
**Priority:** CRITICAL ⚠️

**Pre-conditions:**
- Clean install of app
- Enable Airplane Mode BEFORE launching
- OR IAP products not configured

**Steps:**
1. Launch app with no network
2. Navigate to subscription screen
3. Wait for loading to complete

**Expected Results:**
- [ ] Loading spinner appears initially
- [ ] After timeout (max 15 seconds), error screen appears
- [ ] Error shows orange warning icon
- [ ] Message: "Unable to Load Subscriptions"
- [ ] "Try Again" button is present and tappable
- [ ] If free scans available, "Use your 5 free scans" button shows
- [ ] NO infinite spinner

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

#### Test Case 1.3: Retry After Network Restored
**Priority:** CRITICAL ⚠️

**Pre-conditions:**
- Error state showing from Test Case 1.2
- Airplane Mode enabled

**Steps:**
1. Disable Airplane Mode
2. Wait for network to reconnect
3. Tap "Try Again" button
4. Observe loading behavior

**Expected Results:**
- [ ] Loading spinner shows again
- [ ] Products load successfully within 15 seconds
- [ ] Base and Ultra tabs appear with pricing
- [ ] Purchase buttons are enabled
- [ ] No errors

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

#### Test Case 1.4: Partial Product Load
**Priority:** HIGH

**Pre-conditions:**
- Only one IAP product configured in App Store Connect
- OR one product ID has typo

**Steps:**
1. Launch app
2. Navigate to subscription screen
3. Observe behavior

**Expected Results:**
- [ ] Products that are available show with correct pricing
- [ ] Products that failed show fallback pricing ($4.99 or $11.99)
- [ ] Error message indicates "Some subscription products are not available"
- [ ] "Try Again" button is available
- [ ] App does not crash

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Fix #2: IAP Products Submission

#### Test Case 2.1: Verify Product IDs Match
**Priority:** CRITICAL ⚠️

**Steps:**
1. Check SubscriptionManager.swift lines 30-31
2. Verify Product IDs in code:
   - baseProductID = "albumscan_base_annual"
   - ultraProductID = "albumscan_ultra_annual"
3. Check App Store Connect > In-App Purchases
4. Verify exact match (case-sensitive)

**Expected Results:**
- [ ] Base product ID matches exactly: `albumscan_base_annual`
- [ ] Ultra product ID matches exactly: `albumscan_ultra_annual`
- [ ] No typos or extra characters
- [ ] Both products exist in App Store Connect
- [ ] Both products submitted for review with screenshots

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

## Subscription Flow Testing

### Test Case 3.1: Base Subscription Purchase
**Priority:** CRITICAL ⚠️

**Pre-conditions:**
- Products loaded successfully
- Sandbox account signed in
- No existing subscription

**Steps:**
1. Navigate to subscription screen
2. Select "Base" tab
3. Verify price displays correctly
4. Tap "Buy Base - [price]" button
5. Complete sandbox purchase (use sandbox password)
6. Observe post-purchase state

**Expected Results:**
- [ ] Base tab shows correct price (from StoreKit or fallback $4.99)
- [ ] Features list shows Base features
- [ ] Purchase sheet appears (iOS system sheet)
- [ ] Purchase completes without errors
- [ ] App recognizes subscription immediately
- [ ] Subscription sheet dismisses
- [ ] Debug logs show: "✅ [Subscription] Purchase successful for base"

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 3.2: Ultra Subscription Purchase
**Priority:** CRITICAL ⚠️

**Pre-conditions:**
- Products loaded successfully
- Sandbox account signed in
- No existing subscription

**Steps:**
1. Navigate to subscription screen
2. Select "Ultra" tab
3. Verify price displays correctly
4. Tap "Buy Ultra - [price]" button
5. Complete sandbox purchase
6. Observe post-purchase state

**Expected Results:**
- [ ] Ultra tab shows correct price (from StoreKit or fallback $11.99)
- [ ] Features list shows Ultra features
- [ ] Purchase completes without errors
- [ ] App recognizes Ultra subscription
- [ ] Can access Ultra features (enhanced search, expert reviews)
- [ ] Debug logs show: "✅ [Subscription] Purchase successful for ultra"

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 3.3: Upgrade from Base to Ultra
**Priority:** HIGH

**Pre-conditions:**
- Active Base subscription
- Products loaded

**Steps:**
1. Navigate to subscription screen (Settings or welcome)
2. Verify UI shows "You have AlbumScan Base"
3. Observe upgrade UI
4. Tap "Upgrade to Ultra"
5. Complete purchase

**Expected Results:**
- [ ] Shows "You have AlbumScan Base" in green
- [ ] Shows "Upgrade to AlbumScan Ultra" header
- [ ] Shows Ultra price and features
- [ ] Purchase completes
- [ ] Subscription tier updates to Ultra
- [ ] Can access Ultra features

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 3.4: User Cancels Purchase
**Priority:** MEDIUM

**Steps:**
1. Navigate to subscription screen
2. Select any tier
3. Tap purchase button
4. Tap "Cancel" on iOS purchase sheet

**Expected Results:**
- [ ] Purchase sheet dismisses
- [ ] App returns to subscription selection
- [ ] No error message shown
- [ ] Purchase button remains enabled
- [ ] Can try again
- [ ] Debug logs show: "⚠️ [Subscription] User cancelled purchase"

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 3.5: Restore Purchases
**Priority:** HIGH

**Pre-conditions:**
- Previously purchased subscription in sandbox
- App reinstalled (clean state)
- Sandbox account signed in

**Steps:**
1. Launch app
2. Navigate to subscription screen
3. Look for "Restore Purchases" option (if available)
4. OR let app auto-check on launch

**Expected Results:**
- [ ] App automatically detects existing subscription
- [ ] Subscription tier updates correctly
- [ ] Can access subscribed features
- [ ] Debug logs show subscription detected
- [ ] No manual restore needed (auto-restoration)

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

## Device-Specific Testing

### Test Case 4.1: iPhone 13 mini - Portrait
**Priority:** CRITICAL ⚠️

**Device:** iPhone 13 mini (iOS 18.1)

**Steps:**
1. Launch app on iPhone 13 mini
2. Navigate to subscription screen
3. Test all subscription scenarios (1.1-3.5)

**Expected Results:**
- [ ] All UI elements fit on screen
- [ ] No text cutoff or overflow
- [ ] Buttons are fully visible and tappable
- [ ] Loading state displays correctly
- [ ] Error state displays correctly
- [ ] No layout issues

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 4.2: iPad Air (5th gen) - Portrait
**Priority:** CRITICAL ⚠️

**Device:** iPad Air 5th gen (iPadOS 18.1)

**Steps:**
1. Launch app on iPad Air
2. Navigate to subscription screen
3. Verify layout adapts to larger screen
4. Test all subscription scenarios

**Expected Results:**
- [ ] UI scales appropriately for iPad
- [ ] All elements visible and accessible
- [ ] No awkward spacing or stretching
- [ ] Sheet presentation works correctly
- [ ] All interactions work (tap, scroll)

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 4.3: iPad Air (5th gen) - Landscape
**Priority:** MEDIUM

**Device:** iPad Air 5th gen (iPadOS 18.1)

**Steps:**
1. Rotate device to landscape
2. Navigate to subscription screen
3. Verify layout

**Expected Results:**
- [ ] UI adapts to landscape orientation
- [ ] No layout breaking
- [ ] All elements accessible
- [ ] Sheet displays correctly

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

## Edge Cases and Error Handling

### Test Case 5.1: Network Loss During Product Load
**Priority:** HIGH

**Steps:**
1. Launch app
2. Navigate to subscription screen
3. As products start loading, enable Airplane Mode
4. Wait for timeout

**Expected Results:**
- [ ] Loading times out within 15 seconds
- [ ] Error screen appears
- [ ] Error message about connection
- [ ] "Try Again" button available
- [ ] No crash or freeze

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 5.2: Network Loss During Purchase
**Priority:** HIGH

**Steps:**
1. Start purchase flow
2. When iOS purchase sheet appears, enable Airplane Mode
3. Try to complete purchase
4. Observe behavior

**Expected Results:**
- [ ] iOS shows appropriate error
- [ ] App handles error gracefully
- [ ] Can retry when network restored
- [ ] No corrupted state
- [ ] Transaction properly cleaned up

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 5.3: App Backgrounding During Purchase
**Priority:** MEDIUM

**Steps:**
1. Start purchase flow
2. After tapping purchase, quickly press home button
3. Wait 30 seconds
4. Return to app

**Expected Results:**
- [ ] Purchase completes or properly fails
- [ ] App state is correct
- [ ] No stuck loading states
- [ ] Transaction is handled

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 5.4: Multiple Rapid "Try Again" Taps
**Priority:** LOW

**Steps:**
1. Get app into error state
2. Rapidly tap "Try Again" button 10 times

**Expected Results:**
- [ ] Only one load request is made
- [ ] Button becomes disabled during load
- [ ] No crashes or race conditions
- [ ] Products load normally

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

## Persistence and State Testing

### Test Case 6.1: Subscription Persists After App Restart
**Priority:** HIGH

**Pre-conditions:**
- Active subscription purchased

**Steps:**
1. Purchase subscription (Base or Ultra)
2. Completely close app (swipe up from app switcher)
3. Relaunch app
4. Check subscription status

**Expected Results:**
- [ ] Subscription status loads on launch
- [ ] Tier is remembered (Keychain)
- [ ] Features are accessible
- [ ] No need to "restore purchases"
- [ ] Debug logs show tier loaded from Keychain

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 6.2: Subscription Persists After Device Restart
**Priority:** MEDIUM

**Pre-conditions:**
- Active subscription

**Steps:**
1. Restart device
2. Launch app
3. Check subscription status

**Expected Results:**
- [ ] Subscription still active
- [ ] Features accessible
- [ ] No errors

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

## UI/UX Verification

### Test Case 7.1: Fallback Pricing Display
**Priority:** MEDIUM

**Pre-conditions:**
- Products fail to load OR StoreKit unavailable

**Steps:**
1. Force product load failure (airplane mode)
2. After error, note if any pricing is visible
3. OR check code for fallback values

**Expected Results:**
- [ ] Fallback prices defined: $4.99/year (Base), $11.99/year (Ultra)
- [ ] Fallback prices display when StoreKit unavailable
- [ ] Pricing format is consistent
- [ ] No "$null" or blank prices

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 7.2: Loading State Appearance
**Priority:** MEDIUM

**Steps:**
1. Launch app with good network
2. Navigate to subscription screen
3. Observe loading state (may be brief)

**Expected Results:**
- [ ] Progress indicator (spinner) visible
- [ ] Message: "Loading subscription options..."
- [ ] Brand green color (#00DE52)
- [ ] Centered layout
- [ ] Appropriate size (1.5x scale)

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 7.3: Error State Appearance
**Priority:** MEDIUM

**Steps:**
1. Trigger error state (airplane mode)
2. Review error UI elements

**Expected Results:**
- [ ] Orange warning icon visible
- [ ] Title: "Unable to Load Subscriptions"
- [ ] Error message displayed (from SubscriptionManager)
- [ ] "Try Again" button (green, rounded)
- [ ] Refresh icon on button
- [ ] Skip button (if free scans available)
- [ ] Proper spacing and padding

**Actual Results:** _________________

**Status:** ⬜ Pass ⬜ Fail

---

## Debug Logging Verification

### Test Case 8.1: Product Load Success Logs
**Priority:** LOW (but helpful)

**Steps:**
1. Connect device to Xcode
2. Launch app
3. Trigger product load
4. Check console logs

**Expected Logs:**
```
💳 [Subscription] Manager initialized
📦 [Subscription] Loaded 2 products
✅ [Subscription] Base loaded: AlbumScan Base - $4.99
✅ [Subscription] Ultra loaded: AlbumScan Ultra - $11.99
```

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 8.2: Product Load Failure Logs
**Priority:** LOW

**Steps:**
1. Connect device
2. Trigger load failure (airplane mode)
3. Check console

**Expected Logs:**
```
❌ [Subscription] Load error: [error details]
⏱️ [Subscription] Load timeout after 15 seconds
```

**Status:** ⬜ Pass ⬜ Fail

---

### Test Case 8.3: Purchase Success Logs
**Priority:** LOW

**Steps:**
1. Complete purchase
2. Check console

**Expected Logs:**
```
💳 [Subscription] Starting purchase for [tier]...
✅ [Subscription] Purchase successful for [tier]
✅ [Subscription] Active [TIER] subscription found
```

**Status:** ⬜ Pass ⬜ Fail

---

## Final Pre-Submission Checklist

Before submitting to App Store:

### Code Review
- [ ] All TODOs and FIXMEs resolved
- [ ] Debug code removed or properly gated with #if DEBUG
- [ ] No hardcoded test values
- [ ] Product IDs match App Store Connect exactly

### App Store Connect
- [ ] Both IAP products created and submitted for review
- [ ] App Review screenshots uploaded for BOTH products
- [ ] Product metadata complete (names, descriptions, pricing)
- [ ] Subscription group configured
- [ ] App binary uploaded (v1.0.1+)

### Testing Summary
- [ ] All CRITICAL tests passed
- [ ] All HIGH priority tests passed
- [ ] Device testing complete (iPhone & iPad)
- [ ] Sandbox purchases work correctly
- [ ] No infinite loading spinners observed
- [ ] Error handling verified
- [ ] Network edge cases handled

### Documentation
- [ ] Release notes updated
- [ ] "Notes for Review" prepared for App Store
- [ ] Screenshots updated (if needed)
- [ ] Privacy policy reviewed

### Final Build
- [ ] Build number incremented
- [ ] Version number: 1.0.1 (or higher)
- [ ] Provisioning profiles valid
- [ ] Archive uploaded to App Store Connect
- [ ] Build marked for submission

---

## Test Execution Summary

**Date:** _________________

**Tester:** _________________

**Build Version:** _________________

**Total Tests:** 28

**Passed:** _____ / 28

**Failed:** _____ / 28

**Critical Issues:** _________________

**Notes:**
_________________________________________
_________________________________________
_________________________________________

**Ready for Submission:** ⬜ Yes ⬜ No

**If No, blocking issues:**
_________________________________________
_________________________________________
