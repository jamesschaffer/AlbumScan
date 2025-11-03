# AlbumScan Subscription Testing Guide

## Overview
This document provides a step-by-step process to test the two-tier subscription system (Base and Ultra) before production release.

---

## Phase 1: Local Testing with StoreKit Configuration File

### Step 1.1: Create StoreKit Configuration File

1. **In Xcode**, go to: `File > New > File...`
2. Search for "StoreKit" and select **"StoreKit Configuration File"**
3. Name it: `StoreKitConfiguration.storekit`
4. Save location: `/AlbumScan/` (root of your project)

### Step 1.2: Add Products to Configuration

1. **Open `StoreKitConfiguration.storekit`** in Xcode
2. Click the **"+"** button at the bottom left
3. Select **"Add Auto-Renewable Subscription"**

#### Base Product Configuration:
- **Reference Name**: AlbumScan Base Annual
- **Product ID**: `albumscan_base_annual` (MUST match exactly)
- **Price**: $4.99
- **Subscription Duration**: 1 Year
- **Group Name**: AlbumScan Subscriptions
- **Group Level**: 1

#### Ultra Product Configuration:
- Click **"+"** again, select **"Add Auto-Renewable Subscription"**
- **Reference Name**: AlbumScan Ultra Annual
- **Product ID**: `albumscan_ultra_annual` (MUST match exactly)
- **Price**: $11.99
- **Subscription Duration**: 1 Year
- **Group Name**: AlbumScan Subscriptions (SAME as Base)
- **Group Level**: 2

4. **Save** the file (Cmd+S)

### Step 1.3: Configure Scheme to Use StoreKit File

1. In Xcode, go to: `Product > Scheme > Edit Scheme...`
2. Select **"Run"** on the left
3. Go to **"Options"** tab
4. Under **"StoreKit Configuration"**, select: `StoreKitConfiguration.storekit`
5. Click **"Close"**

### Step 1.4: Local Testing - No Subscription Flow

**Test Objective**: Verify free user experience and scan limits

1. **Clean build and run** on simulator
2. If you see debug controls, tap **"Clear"** button to reset state
3. Verify you see: **"Start with 5 free scans"** on WelcomeView
4. Tap **"Start with 5 free scans"**
5. Grant camera permission when prompted

**Expected Results**:
- ✅ Bottom-left button shows: **5** inside circle (white text)
- ✅ No "$" symbol visible
- ✅ Button is NOT hidden

6. **Perform a scan** (or tap debug button to decrement if available)
7. After scan, verify button shows: **4**
8. Continue until you reach **0 scans**

**Expected Results at 0 scans**:
- ✅ Button shows: **$** (white, not green)
- ✅ Scan button shows overlay: "No scans left - upgrade to continue"
- ✅ Tapping scan button opens SettingsView (Choose Your Plan)
- ✅ Tapping $ button opens SettingsView (Choose Your Plan)

### Step 1.5: Local Testing - Base Purchase Flow

**Test Objective**: Verify Base tier purchase and features

1. **Tap the $ button** (or scan button when at 0 scans)
2. Verify you see **"Choose Your Plan"** screen
3. Verify **"Base"** tab is selected by default
4. Verify you see:
   - ✅ "Base" and "$4.99/yr" labels
   - ✅ Three benefits listed
   - ✅ "Buy Base - $4.99" button enabled

5. **Tap "Buy Base - $4.99"**
6. StoreKit will show a purchase dialog (local mode)
7. **Tap "Subscribe"** in the dialog
8. Wait for purchase to complete

**Expected Results After Base Purchase**:
- ✅ Screen dismisses automatically
- ✅ Scan button works (no limit)
- ✅ Bottom-left button is HIDDEN completely
- ✅ Open SettingsView and verify it shows: **"AlbumScan Ultra"** upgrade pitch
- ✅ Message: "You have AlbumScan Base"
- ✅ Button: "Upgrade to Ultra"

9. **Perform a scan with Base tier**

**Expected Scan Results**:
- ✅ Review appears with album details
- ✅ Review has NO Wikipedia links (no URLs at all)
- ✅ Review uses base prompt (standard AI-generated content)

### Step 1.6: Local Testing - Upgrade to Ultra

**Test Objective**: Verify Base → Ultra upgrade flow

1. **Open SettingsView** (swipe up from bottom or use debug menu)
2. You should see upgrade pitch for Ultra
3. Verify button shows: **"Upgrade to Ultra"**
4. **Tap "Upgrade to Ultra"**
5. StoreKit shows upgrade dialog
6. **Tap "Subscribe"**
7. Wait for purchase to complete

**Expected Results After Ultra Upgrade**:
- ✅ Screen updates automatically
- ✅ SettingsView now shows: "You are now leveraging AlbumScan Ultra"
- ✅ Green success message visible
- ✅ No upgrade button (replaced with success state)

8. **Close settings and perform a scan**

**Expected Scan Results with Ultra**:
- ✅ Review appears with album details
- ✅ Review INCLUDES Wikipedia links and other URLs
- ✅ Multiple sources cited (max 2 from any domain)
- ✅ At least 3 different sources used
- ✅ Review uses Ultra prompt (enhanced search)

### Step 1.7: Local Testing - Ultra Direct Purchase

**Test Objective**: Verify direct Ultra purchase (skip Base)

1. **Reset app state**:
   - Tap debug **"Clear"** button
   - OR delete app and reinstall
2. **Start fresh** with 5 free scans
3. Use all 5 scans to reach 0
4. **Tap $ button**
5. In "Choose Your Plan" screen, tap **"Ultra"** tab
6. Verify Ultra features show (4 benefits)
7. **Tap "Buy Ultra - $11.99"**
8. StoreKit shows purchase dialog
9. **Tap "Subscribe"**

**Expected Results**:
- ✅ Purchase completes
- ✅ SettingsView shows Ultra success state
- ✅ Bottom-left button HIDDEN
- ✅ Scans include Wikipedia links and citations

### Step 1.8: Local Testing - App Restart Persistence

**Test Objective**: Verify subscription persists across app restarts

1. **With Ultra active**, force quit the app (swipe up in app switcher)
2. **Reopen the app**
3. Wait for subscription check to complete (~2 seconds)

**Expected Results**:
- ✅ Ultra subscription still active
- ✅ SettingsView shows Ultra success state
- ✅ Scans still include Wikipedia links
- ✅ No scan limit enforced
- ✅ Bottom-left button still hidden

### Step 1.9: Local Testing - Subscription Expiration

**Test Objective**: Verify behavior when subscription expires

1. **In Xcode**, open `StoreKitConfiguration.storekit`
2. Find your active subscription
3. Click **"Edit"** button
4. Set **"Subscription Duration"** to a short time (e.g., 5 minutes)
5. Wait for expiration, OR
6. In StoreKit Transaction Manager: `Debug > StoreKit > Manage Transactions`
7. Find your subscription and click **"Expire Subscription"**

**Expected Results**:
- ✅ App detects expiration
- ✅ Returns to free tier (5 scans available)
- ✅ Bottom-left button shows scan count again
- ✅ SettingsView shows "Choose Your Plan"
- ✅ Scans no longer include Wikipedia links

---

## Phase 2: Sandbox Testing with Real App Store

**IMPORTANT**: This phase requires approved products in App Store Connect. Your Base and Ultra products must be in "Ready to Submit" or "Approved" status.

### Step 2.1: Create Sandbox Test Account

1. Go to **App Store Connect** → https://appstoreconnect.apple.com
2. Navigate to: **Users and Access** → **Sandbox Testers**
3. Click **"+"** to add a new tester
4. Fill in details:
   - **Email**: Use a NEW email (not associated with any Apple ID)
   - **Password**: Create a strong password
   - **Country**: United States
   - **First/Last Name**: Test User Base / Test User Ultra (or any name)
5. **Save** the account
6. **IMPORTANT**: Do NOT sign into this account on your device yet

### Step 2.2: Configure Scheme for Sandbox Testing

1. In Xcode: `Product > Scheme > Edit Scheme...`
2. Select **"Run"** → **"Options"** tab
3. Under **"StoreKit Configuration"**, select: **"None"**
4. Click **"Close"**

This switches from local StoreKit file to real App Store (sandbox mode).

### Step 2.3: Sign Out of Your Apple ID on Test Device

**On iOS Device or Simulator**:
1. Go to: **Settings → App Store**
2. Tap your Apple ID at the top
3. Tap **"Sign Out"**
4. Confirm sign out

**DO NOT** sign in with sandbox account yet - wait for app to prompt you.

### Step 2.4: Sandbox Testing - Base Purchase

1. **Delete AlbumScan** from device (if installed)
2. **Build and run** from Xcode to test device
3. **Launch app** and complete onboarding
4. Use 5 free scans to reach 0
5. **Tap $ button** to open purchase screen
6. Select **"Base"** tab
7. **Tap "Buy Base - $4.99"**

**Expected**:
- ✅ App Store dialog appears asking for Apple ID
- ✅ Enter your **sandbox test account** email/password
- ✅ Dialog says "Environment: Sandbox" (MUST say this!)
- ✅ Purchase completes within ~5-10 seconds

8. **Verify Base subscription active**:
   - ✅ SettingsView shows upgrade pitch
   - ✅ Scans work with no Wikipedia links
   - ✅ Bottom-left button hidden

### Step 2.5: Sandbox Testing - Restore Purchases

1. **Delete the app** from device
2. **Reinstall** from Xcode
3. **Launch app** - you'll be in free tier
4. **Open SettingsView** or trigger paywall
5. Look for **"Restore Purchases"** button (if available in PaywallView)
6. OR go to SettingsView and purchase again (it will restore instead)

**Expected**:
- ✅ Subscription restored automatically
- ✅ Base tier active
- ✅ No charge occurs (shows "You're already subscribed")

### Step 2.6: Sandbox Testing - Upgrade Base → Ultra

1. **With Base active**, open SettingsView
2. Verify upgrade pitch shows
3. **Tap "Upgrade to Ultra"**
4. App Store shows upgrade dialog
5. **Complete upgrade**

**Expected**:
- ✅ Shows price difference or prorated amount
- ✅ Upgrade completes successfully
- ✅ SettingsView shows Ultra success state
- ✅ Scans now include Wikipedia links
- ✅ Debug console shows: "Active ULTRA subscription found"

### Step 2.7: Sandbox Testing - Direct Ultra Purchase (New User)

1. **Create a second sandbox account** in App Store Connect
2. **Sign out** of first sandbox account on device: Settings → App Store
3. **Delete AlbumScan** app
4. **Reinstall** from Xcode
5. Use 5 free scans to reach 0
6. **Open purchase screen**
7. Select **"Ultra"** tab
8. **Tap "Buy Ultra - $11.99"**
9. Sign in with **second sandbox account** when prompted

**Expected**:
- ✅ Ultra purchase completes
- ✅ Scans include Wikipedia links immediately
- ✅ SettingsView shows Ultra success state

### Step 2.8: Sandbox Testing - Subscription Management

1. **On device**: Go to **Settings → App Store → Sandbox Account → Manage**
2. Verify you see:
   - ✅ AlbumScan subscription listed
   - ✅ Current tier (Base or Ultra) shown
   - ✅ Renewal date displayed
   - ✅ Downgrade/Cancel options available

3. **Try downgrading** Ultra → Base (if upgraded):
   - Select **Base** tier
   - Confirm downgrade
   - **Expected**: Takes effect at next renewal (not immediate)

4. **Try canceling**:
   - Tap **"Cancel Subscription"**
   - Confirm cancellation
   - **Expected**: Subscription remains active until expiration date

---

## Phase 3: Edge Case Testing

### Test 3.1: Network Interruption During Purchase

1. **Start a purchase**
2. **Turn on Airplane Mode** mid-purchase
3. Wait 10 seconds
4. **Turn off Airplane Mode**

**Expected**:
- ✅ Purchase either completes or shows error
- ✅ No duplicate charges
- ✅ If error, retry button works

### Test 3.2: App Killed During Purchase

1. **Start a purchase**
2. **Force quit app** immediately (swipe up in app switcher)
3. **Reopen app**

**Expected**:
- ✅ Purchase completes in background
- ✅ Subscription status updates on next check
- ✅ Transaction finished properly

### Test 3.3: Multiple Rapid Purchases

1. **Tap purchase button multiple times rapidly**

**Expected**:
- ✅ Button disables during purchase
- ✅ Only one purchase dialog appears
- ✅ No duplicate charges

### Test 3.4: Expired Subscription Restore

1. **In Sandbox**: Expire subscription using Transaction Manager
2. **Delete app** and reinstall
3. **Attempt to restore purchases**

**Expected**:
- ✅ Shows "No active subscription found"
- ✅ Prompts to subscribe again
- ✅ Free tier activated

---

## Phase 4: Verification Checklist

### Product Configuration ✓
- [ ] Base product ID: `albumscan_base_annual` (exact match)
- [ ] Ultra product ID: `albumscan_ultra_annual` (exact match)
- [ ] Both in same subscription group: "AlbumScan Subscriptions"
- [ ] Base Level: 1, Ultra Level: 2
- [ ] Prices: Base $4.99, Ultra $11.99

### Free Tier (No Subscription) ✓
- [ ] Shows 5 free scans on welcome
- [ ] Scan counter decrements: 5 → 4 → 3 → 2 → 1 → $
- [ ] $ symbol is WHITE (not green)
- [ ] $ button opens SettingsView
- [ ] Scan button blocked at 0 scans
- [ ] Scans have NO Wikipedia links
- [ ] Bottom-left button visible

### Base Tier ✓
- [ ] Purchase completes successfully
- [ ] No scan limit enforced
- [ ] Scans have NO Wikipedia links (base prompt)
- [ ] Bottom-left button HIDDEN
- [ ] SettingsView shows upgrade pitch for Ultra
- [ ] Persists across app restarts

### Ultra Tier ✓
- [ ] Purchase completes successfully
- [ ] Scans INCLUDE Wikipedia links
- [ ] Max 2 URLs per domain enforced
- [ ] At least 3 different sources in reviews
- [ ] Bottom-left button HIDDEN
- [ ] SettingsView shows success state
- [ ] Persists across app restarts

### Upgrade Flow ✓
- [ ] Base → Ultra upgrade works
- [ ] Proration shown correctly
- [ ] Features update immediately
- [ ] Wikipedia links appear after upgrade

### Error Handling ✓
- [ ] User cancel shows no error
- [ ] Network errors handled gracefully
- [ ] Product not available shows error
- [ ] Failed verification shows error

### UI/UX ✓
- [ ] Loading states show during purchase
- [ ] Success dismisses screen automatically
- [ ] Error shows alert dialog
- [ ] Buttons disable during purchase
- [ ] All prices display correctly

---

## Phase 5: Production Readiness

### Before Submitting to App Store

1. **Review App Store Connect Setup**:
   - [ ] Subscription group approved
   - [ ] Both products approved/ready
   - [ ] Subscription pricing confirmed
   - [ ] Subscription details/benefits filled
   - [ ] Promotional images uploaded (if desired)

2. **Code Review**:
   - [ ] Remove all debug buttons (`#if DEBUG` blocks only)
   - [ ] Remove debug print statements (optional - they're in `#if DEBUG`)
   - [ ] Verify product IDs match App Store Connect exactly
   - [ ] Test with Release configuration

3. **Legal/Compliance**:
   - [ ] Privacy policy mentions subscriptions
   - [ ] Terms of service updated
   - [ ] Auto-renewal disclosure in app
   - [ ] Links to App Store subscription management

4. **Final Sandbox Test**:
   - [ ] Complete all Phase 2 tests
   - [ ] Test on multiple iOS versions (17.0+)
   - [ ] Test on multiple devices (iPhone, iPad if supported)

5. **Archive and Submit**:
   - [ ] Set version and build number
   - [ ] Archive app (Product → Archive)
   - [ ] Distribute to App Store
   - [ ] Complete App Store metadata
   - [ ] Submit for review

---

## Troubleshooting

### "Product Not Available" Error

**Problem**: Purchase button disabled, products not loading

**Solutions**:
1. Verify product IDs match EXACTLY (case-sensitive)
2. Check App Store Connect products are "Ready to Submit"
3. Wait 2-4 hours after creating products
4. Sign out/in of sandbox account
5. Check console for `loadProducts()` errors

### "Cannot Connect to App Store"

**Problem**: Purchase fails with connection error

**Solutions**:
1. Verify internet connection
2. Check sandbox account is signed in (Settings → App Store)
3. Verify scheme is NOT using StoreKit Configuration file
4. Try different network (switch from WiFi to cellular)

### Subscription Not Detected After Purchase

**Problem**: Purchase completes but tier stays .none

**Solutions**:
1. Check console for "Transaction verification failed"
2. Verify `checkSubscriptionStatus()` is called after purchase
3. Force refresh: call `await subscriptionManager.checkSubscriptionStatus()`
4. Check Keychain has subscription tier saved
5. Verify transaction.productID matches your constants

### Wikipedia Links Showing for Free/Base Users

**Problem**: Free or Base scans include Wikipedia links

**Solutions**:
1. Verify CameraManager line 829 uses: `subscriptionManager?.subscriptionTier == .ultra`
2. Check debug controls aren't setting incorrect tier
3. Clear UserDefaults and Keychain: tap "Clear" debug button
4. Verify `searchEnabled` is NOT persisted independently

### Duplicate Purchases Occurring

**Problem**: User charged multiple times

**Solutions**:
1. Check button disabled state during purchase (line 139/145)
2. Verify `isPurchasing` flag prevents multiple calls
3. Check StoreKit Transaction Manager for duplicate transactions
4. Contact Apple if duplicate charges occurred

---

## Debug Console Messages

### Expected Success Messages

```
💳 [Subscription] Manager initialized
📦 [Subscription] Loaded 2 products
✅ [Subscription] Base loaded: AlbumScan Base - $4.99
✅ [Subscription] Ultra loaded: AlbumScan Ultra - $11.99
💳 [Subscription] Starting purchase for base...
✅ [Subscription] Purchase successful for base
✅ [Subscription] Active BASE subscription found
📝 [Subscription] Tier changed: none → base
```

### Expected Error Messages

```
❌ [Subscription] Product not available for tier: base
⚠️ [Subscription] User cancelled purchase
❌ [Subscription] Load error: [error details]
❌ [Subscription] Transaction verification failed
```

---

## Success Criteria

Your subscription system is ready for production when:

✅ All Phase 1 tests pass (local StoreKit)
✅ All Phase 2 tests pass (sandbox)
✅ All Phase 4 checklist items verified
✅ No critical errors in console
✅ Wikipedia links ONLY for Ultra tier
✅ Scan limits enforced correctly for free tier
✅ Subscriptions persist across app restarts
✅ Upgrade flow works smoothly
✅ All UI states display correctly

---

## Next Steps After Testing

1. **If all tests pass**: Proceed to Phase 5 (Production Readiness)
2. **If tests fail**: Review troubleshooting section, fix issues, re-test
3. **Before production**: Remove debug controls, test Release build
4. **Submit to App Store**: Follow Phase 5 checklist

**Questions or issues?** Document the exact steps to reproduce and check console logs.
