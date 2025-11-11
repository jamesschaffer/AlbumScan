# TestFlight Pre-Submission Checklist

Quick checklist to ensure TestFlight build is ready before App Store submission.

## Build Preparation

### Version & Build Number
- [ ] Version incremented to **1.0.1** (or higher)
- [ ] Build number incremented from previous submission
- [ ] Build number in Info.plist matches Xcode

### Code Quality
- [ ] All subscription bug fixes applied (infinite loading, error handling, timeout)
- [ ] No compiler warnings (or all acceptable)
- [ ] No force unwraps in critical paths
- [ ] All debug logging properly gated with `#if DEBUG`

### Archive & Upload
- [ ] Archived successfully in Xcode
- [ ] Archive uploaded to App Store Connect
- [ ] Upload processed without errors
- [ ] Build appears in TestFlight section

---

## App Store Connect Configuration

### App Information
- [ ] Version 1.0.1 created in App Store Connect
- [ ] Release notes mention bug fixes:
  - Fixed infinite loading spinner
  - Improved error handling for subscription loading
  - Added retry functionality when products fail to load

### In-App Purchases (CRITICAL)
- [ ] **Base product** (`albumscan_base_annual`) submitted for review
- [ ] **Ultra product** (`albumscan_ultra_annual`) submitted for review
- [ ] App Review screenshots uploaded for **BOTH** products
- [ ] Both products show status: "Waiting for Review" or "In Review"
- [ ] Product IDs match code exactly (case-sensitive)

### Screenshots & Marketing
- [ ] Screenshots show latest UI (if changed)
- [ ] No references to removed features
- [ ] Privacy policy link working

---

## TestFlight Internal Testing

### Initial Setup
- [ ] Add internal testers (yourself and team)
- [ ] Set "What to Test" notes:
```
Focus testing on subscription flow:
1. Products should load within 15 seconds
2. If products fail to load, error screen appears with "Try Again" button
3. No infinite loading spinners
4. Purchases complete successfully
5. Subscription persists after app restart

Test on iPhone 13 mini and iPad Air (5th gen) if possible.
```

### Critical Tests (Run by You)
- [ ] **CRITICAL:** Clean install → subscription screen → products load OR error appears
- [ ] **CRITICAL:** Airplane mode → subscription screen → error with retry button
- [ ] **CRITICAL:** Purchase Base subscription → completes successfully
- [ ] **CRITICAL:** Purchase Ultra subscription → completes successfully
- [ ] Subscription persists after force-quit and relaunch
- [ ] Test on both iPhone and iPad
- [ ] No crashes during 5 minutes of use

### Acceptance Criteria
- [ ] Zero crashes in subscription flow
- [ ] No infinite loading spinners observed
- [ ] Error handling works (retry button appears and works)
- [ ] All purchases complete successfully in sandbox
- [ ] UI looks correct on iPhone and iPad

---

## Sandbox Testing Requirements

### Test Account
- [ ] Sandbox tester account created in App Store Connect
- [ ] Signed in with sandbox account on test device
- [ ] Can complete test purchases
- [ ] Purchases are recognized by app

### Test Scenarios Completed
- [ ] Purchase Base plan in sandbox
- [ ] Purchase Ultra plan in sandbox
- [ ] Products load with good network
- [ ] Error state with airplane mode
- [ ] Retry after network restored
- [ ] No infinite spinners in any scenario

---

## Device Testing Matrix

Test on devices matching Apple Review environment:

| Device | OS | Test Date | Tester | Status |
|--------|-----|-----------|--------|--------|
| iPhone 13 mini | iOS 18.1 | _____ | _____ | ⬜ Pass ⬜ Fail |
| iPad Air (5th gen) | iPadOS 18.1 | _____ | _____ | ⬜ Pass ⬜ Fail |

**Minimum requirement:** Test on at least one iPhone and one iPad (simulators acceptable for initial check).

---

## External Testing (Optional)

If you want additional validation:

- [ ] Invite 2-3 external beta testers
- [ ] Provide clear testing instructions
- [ ] Ask them to focus on subscription flow
- [ ] Monitor feedback and crash reports
- [ ] Address any critical issues before App Store submission

---

## Pre-Submission Validation

### Final Checks
- [ ] TestFlight build installed and tested
- [ ] No crashes reported in TestFlight
- [ ] All critical test cases passed (see TESTING_CHECKLIST.md)
- [ ] IAP products submitted with screenshots
- [ ] Product IDs verified to match code
- [ ] Ready to submit to App Store Review

### Known Issues (document any)
None expected - all critical bugs fixed.

If any issues found:
1. _____________________________________
2. _____________________________________
3. _____________________________________

### Decision
- [ ] **Ready for App Store submission** - All tests passed, no critical issues
- [ ] **Not ready** - Issues found (document above)

---

## App Store Submission Steps

Once TestFlight testing is complete and all checks pass:

1. **Submit IAPs First:**
   - Go to Features > In-App Purchases
   - Ensure both products submitted with screenshots
   - Wait for status: "Waiting for Review"

2. **Submit App Binary:**
   - Go to App Store > Prepare for Submission
   - Select build 1.0.1
   - Add IAP products to submission
   - Update release notes
   - Add notes for reviewer (see APP_STORE_SUBMISSION_GUIDE.md)
   - Submit for Review

3. **Monitor Submission:**
   - Check status daily
   - Respond quickly to any App Review questions
   - Have device ready for testing in case they ask questions

---

## Rollback Plan

If critical issues found after TestFlight submission:

- [ ] Document the issue
- [ ] Fix in code
- [ ] Increment build number
- [ ] Create new archive
- [ ] Upload to TestFlight
- [ ] Re-run all tests
- [ ] Do NOT submit to App Store until validated

---

## Sign-Off

**Build Version:** _________________

**TestFlight Build Number:** _________________

**Date Uploaded:** _________________

**Internal Testing Complete:** ⬜ Yes ⬜ No

**Critical Issues:** ⬜ None ⬜ Found (see above)

**Approved for App Store Submission:** ⬜ Yes ⬜ No

**Approver:** _________________

**Date:** _________________

---

## Notes

Use this space for any additional notes or observations:

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
