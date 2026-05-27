# AI Visual Assistant - Manual Testing & QA Guide

**Task ID:** Task 27  
**Date Created:** 2024  
**Status:** ✅ READY FOR EXECUTION  
**Estimated Testing Time:** 4-6 hours (comprehensive)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Testing Environment Setup](#testing-environment-setup)
4. [Platform-Specific Testing](#platform-specific-testing)
5. [Feature Testing Scenarios](#feature-testing-scenarios)
6. [Error Scenario Testing](#error-scenario-testing)
7. [Performance Testing](#performance-testing)
8. [Security Testing](#security-testing)
9. [Accessibility Testing](#accessibility-testing)
10. [Test Results Documentation](#test-results-documentation)
11. [Bug Reporting Template](#bug-reporting-template)
12. [Sign-Off Checklist](#sign-off-checklist)

---

## Overview

This guide provides comprehensive manual testing procedures for the AI Visual Assistant feature across Android and iOS platforms. The feature enables customers to diagnose home service issues using AI-powered image analysis.

### Feature Scope

**Implemented Components:**
- ✅ Backend API (108 tests passing)
- ✅ Flutter UI (6 screens + widgets)
- ✅ State management (Riverpod)
- ✅ Image capture & annotation
- ✅ AI analysis integration (Ollama qwen3-vl:2b)
- ✅ Provider recommendations
- ✅ Consultation history
- ✅ Booking integration

### Testing Objectives

1. Verify all features work correctly on Android and iOS
2. Validate image capture, annotation, and AI analysis workflows
3. Test error handling and edge cases
4. Verify performance meets requirements
5. Ensure security and privacy compliance
6. Identify and document any critical bugs

---

## Prerequisites

### Required Devices

**Android Testing:**
- Android 8.0+ (API 26+) device or emulator
- Recommended: Physical device for camera testing
- Multiple screen sizes (phone, tablet)

**iOS Testing:**
- iOS 12.0+ device or simulator
- Recommended: Physical device for camera testing
- Multiple screen sizes (iPhone, iPad)

**Network Conditions:**
- WiFi connection
- Mobile data (4G/5G)
- Slow network (throttled)
- Offline mode

### Backend Services

Ensure the following services are running:

```bash
# Check Docker containers
docker ps

# Expected services:
# - gharsewa_app (Laravel backend)
# - gharsewa_db (MySQL database)
# - gharsewa_ollama (Ollama AI service at http://gharsewa_ollama:11434)
```

### Test Account

Create a test customer account:
- Email: `testcustomer@gharsewa.com`
- Password: `Test@123`
- Role: Customer

### Test Data

Prepare test images:
- Small image (< 1MB): `test_small.jpg`
- Medium image (2-3MB): `test_medium.jpg`
- Large image (5-8MB): `test_large.jpg`
- Various formats: JPEG, PNG, HEIC (iOS)
- Various subjects: plumbing, electrical, carpentry issues

---

## Testing Environment Setup

### Step 1: Install Flutter App

**Android:**
```bash
# Build and install debug APK
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**iOS:**
```bash
# Build and install on simulator
flutter build ios --debug --simulator
open -a Simulator
flutter install
```

### Step 2: Verify Backend Connection

1. Open app and navigate to login screen
2. Login with test account
3. Verify successful authentication
4. Check that API calls are reaching backend (check logs)

### Step 3: Enable Debug Logging

Enable verbose logging to track issues:
- Check Flutter console for errors
- Monitor backend logs: `docker logs -f gharsewa_app`
- Monitor Ollama logs: `docker logs -f gharsewa_ollama`

---

## Platform-Specific Testing

### Android Testing

#### Test 1: Camera Capture on Android

**Steps:**
1. Navigate to AI Visual Assistant
2. Tap "New Consultation"
3. Tap "Take Photo"
4. Grant camera permission if prompted
5. Capture a photo of a test subject
6. Verify photo is captured and displayed

**Expected Results:**
- [ ] Camera opens within 2 seconds
- [ ] Camera preview displays correctly
- [ ] Capture button is visible and functional
- [ ] Photo is captured at minimum 1280x720 resolution
- [ ] Photo is displayed in annotation editor

**Test on:**
- [ ] Android 8.0 (API 26)
- [ ] Android 10.0 (API 29)
- [ ] Android 12.0 (API 31)
- [ ] Android 14.0 (API 34)

#### Test 2: Gallery Selection on Android

**Steps:**
1. Navigate to AI Visual Assistant
2. Tap "New Consultation"
3. Tap "Select from Gallery"
4. Grant storage permission if prompted
5. Select an image from gallery
6. Verify image is loaded

**Expected Results:**
- [ ] Gallery opens correctly
- [ ] All images are visible
- [ ] Selected image loads within 2 seconds
- [ ] Image validation occurs (size, format)
- [ ] Valid images proceed to annotation editor

**Test on:**
- [ ] Android 8.0 (API 26)
- [ ] Android 10.0 (API 29)
- [ ] Android 12.0 (API 31)
- [ ] Android 14.0 (API 34)

#### Test 3: Android Permissions

**Steps:**
1. Fresh install of app
2. Navigate to AI Visual Assistant
3. Attempt camera capture
4. Deny camera permission
5. Verify error handling
6. Tap "Open Settings" button
7. Grant permission in settings
8. Return to app and retry

**Expected Results:**
- [ ] Permission request dialog appears
- [ ] Denial shows clear error message
- [ ] "Open Settings" button opens app settings
- [ ] After granting permission, camera works
- [ ] No app crashes during permission flow

#### Test 4: Android Screen Sizes

**Test on:**
- [ ] Small phone (< 5.5")
- [ ] Medium phone (5.5" - 6.5")
- [ ] Large phone (> 6.5")
- [ ] Tablet (7"+)

**Verify:**
- [ ] UI elements are properly sized
- [ ] Text is readable
- [ ] Buttons are tappable
- [ ] Images scale correctly
- [ ] No UI overflow or clipping

### iOS Testing

#### Test 5: Camera Capture on iOS

**Steps:**
1. Navigate to AI Visual Assistant
2. Tap "New Consultation"
3. Tap "Take Photo"
4. Grant camera permission if prompted
5. Capture a photo
6. Verify photo is captured and displayed

**Expected Results:**
- [ ] Camera opens within 2 seconds
- [ ] Camera preview displays correctly
- [ ] Capture button is visible and functional
- [ ] Photo is captured at minimum 1280x720 resolution
- [ ] Photo is displayed in annotation editor

**Test on:**
- [ ] iOS 12.0
- [ ] iOS 14.0
- [ ] iOS 16.0
- [ ] iOS 17.0

#### Test 6: Gallery Selection on iOS

**Steps:**
1. Navigate to AI Visual Assistant
2. Tap "New Consultation"
3. Tap "Select from Gallery"
4. Grant photo library permission if prompted
5. Select an image
6. Verify image is loaded

**Expected Results:**
- [ ] Photo picker opens correctly
- [ ] All photos are visible
- [ ] Selected image loads within 2 seconds
- [ ] HEIC format is supported and converted
- [ ] Valid images proceed to annotation editor

**Test on:**
- [ ] iOS 12.0
- [ ] iOS 14.0
- [ ] iOS 16.0
- [ ] iOS 17.0

#### Test 7: iOS Permissions

**Steps:**
1. Fresh install of app
2. Navigate to AI Visual Assistant
3. Attempt camera capture
4. Deny camera permission
5. Verify error handling
6. Tap "Open Settings" button
7. Grant permission in settings
8. Return to app and retry

**Expected Results:**
- [ ] Permission request dialog appears
- [ ] Denial shows clear error message
- [ ] "Open Settings" button opens app settings
- [ ] After granting permission, camera works
- [ ] No app crashes during permission flow

#### Test 8: iOS Screen Sizes

**Test on:**
- [ ] iPhone SE (small)
- [ ] iPhone 13/14 (medium)
- [ ] iPhone 14 Pro Max (large)
- [ ] iPad (tablet)

**Verify:**
- [ ] UI elements are properly sized
- [ ] Text is readable
- [ ] Buttons are tappable
- [ ] Images scale correctly
- [ ] No UI overflow or clipping

---

## Feature Testing Scenarios

### Scenario 1: Complete Consultation Flow

**Objective:** Test the entire workflow from image capture to results

**Steps:**
1. Login as customer
2. Navigate to AI Visual Assistant home
3. Tap "New Consultation"
4. Select "Take Photo" or "Select from Gallery"
5. Capture/select an image of a plumbing issue
6. Wait for annotation editor to load
7. Tap on image to add first marker
8. Enter description: "Water leaking from pipe"
9. Add second marker at different location
10. Enter description: "Rust on metal surface"
11. Tap "Submit" button
12. Wait for AI analysis (up to 30 seconds)
13. Review results screen
14. Verify diagnosis is displayed
15. Verify service type is shown
16. Verify cost estimate is displayed (NPR range)
17. Verify 3 provider recommendations are shown
18. Tap "Book Now" on first provider
19. Verify booking screen opens with pre-filled data

**Expected Results:**
- [ ] All steps complete without errors
- [ ] Image displays correctly throughout
- [ ] Markers are placed accurately
- [ ] Descriptions are saved
- [ ] AI analysis completes within 30 seconds
- [ ] Diagnosis is relevant and clear (50-500 chars)
- [ ] Service type matches issue (e.g., "Plumbing Repair")
- [ ] Cost estimate is reasonable (NPR 500 - 50,000)
- [ ] Cost max is at least 1.5x cost min
- [ ] 3 providers shown with names, ratings, services
- [ ] Booking integration works correctly
- [ ] All data persists in consultation history

**Test on:**
- [ ] Android device
- [ ] iOS device

### Scenario 2: Image Validation

**Objective:** Test image size and format validation

**Test Cases:**

#### Test 2.1: Image Too Small
**Steps:**
1. Prepare image < 100KB
2. Attempt to select/capture
3. Verify error message

**Expected:**
- [ ] Error: "Image must be at least 100KB"
- [ ] User can retry with different image

#### Test 2.2: Image Too Large
**Steps:**
1. Prepare image > 10MB
2. Attempt to select/capture
3. Verify error message

**Expected:**
- [ ] Error: "Image must be less than 10MB"
- [ ] User can retry with different image

#### Test 2.3: Valid Image Sizes
**Test with:**
- [ ] 150KB image (valid)
- [ ] 1MB image (valid)
- [ ] 5MB image (valid, should compress)
- [ ] 9MB image (valid, should compress)

**Expected:**
- [ ] All valid images accepted
- [ ] Images > 5MB compressed to ≤ 5MB
- [ ] Aspect ratio maintained
- [ ] Image quality acceptable

#### Test 2.4: Image Formats
**Test with:**
- [ ] JPEG image (valid)
- [ ] PNG image (valid)
- [ ] HEIC image on iOS (valid, should convert)
- [ ] GIF image (invalid)
- [ ] BMP image (invalid)

**Expected:**
- [ ] JPEG, PNG, HEIC accepted
- [ ] HEIC converted to JPEG
- [ ] Invalid formats show error message
- [ ] Error message lists supported formats

### Scenario 3: Marker Placement and Annotation

**Objective:** Test marker placement, editing, and deletion

**Steps:**
1. Load image in annotation editor
2. Tap on image at position (30%, 40%)
3. Enter description: "Defect 1"
4. Verify marker appears at tap location
5. Add 9 more markers (total 10)
6. Attempt to add 11th marker
7. Verify max marker limit enforced
8. Tap on existing marker #3
9. Edit description to "Updated defect 3"
10. Verify description updates
11. Delete marker #5
12. Verify marker removed
13. Verify marker count decreases to 9
14. Add new marker (should work, now at 10 again)

**Expected Results:**
- [ ] Markers placed at exact tap coordinates
- [ ] Markers displayed as red circles
- [ ] Marker numbers visible (1-10)
- [ ] Description prompt appears on marker add
- [ ] Max 10 markers enforced with error message
- [ ] Tapping existing marker allows editing
- [ ] Marker deletion works correctly
- [ ] Marker list updates in real-time
- [ ] Coordinates normalized correctly (0.0-1.0)

**Test on:**
- [ ] Android device
- [ ] iOS device

### Scenario 4: AI Analysis with Different Image Types

**Objective:** Test AI analysis accuracy with various home service issues

**Test Cases:**

#### Test 4.1: Plumbing Issue
**Image:** Leaking pipe, water damage
**Expected Diagnosis:** Plumbing-related issue
**Expected Service Type:** "Plumbing Repair"
**Expected Cost Range:** NPR 1,500 - 5,000

#### Test 4.2: Electrical Issue
**Image:** Exposed wiring, damaged outlet
**Expected Diagnosis:** Electrical-related issue
**Expected Service Type:** "Electrical Work"
**Expected Cost Range:** NPR 1,000 - 4,000

#### Test 4.3: Carpentry Issue
**Image:** Broken door, damaged furniture
**Expected Diagnosis:** Carpentry-related issue
**Expected Service Type:** "Carpentry"
**Expected Cost Range:** NPR 2,000 - 8,000

#### Test 4.4: Painting Issue
**Image:** Peeling paint, wall damage
**Expected Diagnosis:** Painting-related issue
**Expected Service Type:** "Painting"
**Expected Cost Range:** NPR 1,500 - 6,000

**For each test:**
- [ ] AI completes analysis within 30 seconds
- [ ] Diagnosis is relevant to image content
- [ ] Service type matches issue category
- [ ] Cost estimate is reasonable
- [ ] Processing time logged correctly

### Scenario 5: Provider Recommendations

**Objective:** Test provider matching and recommendations

**Steps:**
1. Complete consultation with plumbing issue
2. Review provider recommendations
3. Verify 3 providers shown
4. Check provider details
5. Verify providers offer plumbing services
6. Check provider ratings
7. Tap "Book Now" on each provider
8. Verify booking screen opens correctly

**Expected Results:**
- [ ] Exactly 3 providers recommended (or fewer if < 3 available)
- [ ] All providers offer the recommended service type
- [ ] Providers sorted by rating (highest first)
- [ ] Each provider shows: name, rating, services
- [ ] Ratings displayed as stars (0.0 - 5.0)
- [ ] "Book Now" button functional for each
- [ ] Booking screen pre-fills service type
- [ ] Booking screen pre-fills selected provider
- [ ] Original image attached to booking
- [ ] AI diagnosis included in booking notes

**Test with:**
- [ ] Service type with many providers (> 3)
- [ ] Service type with few providers (< 3)
- [ ] Service type with no providers

### Scenario 6: Consultation History

**Objective:** Test history viewing, filtering, and management

**Steps:**
1. Create 5 consultations with different service types
2. Navigate to "View History"
3. Verify all 5 consultations displayed
4. Check consultation cards show:
   - Thumbnail image
   - Diagnosis summary
   - Service type badge
   - Date
   - Cost range
5. Tap on consultation #3
6. Verify detail view shows complete data
7. Return to history list
8. Apply filter: "Plumbing Repair"
9. Verify only plumbing consultations shown
10. Clear filter
11. Pull to refresh
12. Verify list updates
13. Scroll to bottom (if > 20 consultations)
14. Verify pagination loads more items
15. Tap delete on consultation #2
16. Confirm deletion
17. Verify consultation removed from list

**Expected Results:**
- [ ] History loads within 2 seconds
- [ ] Consultations sorted by date (newest first)
- [ ] Thumbnail images load correctly
- [ ] Diagnosis truncated if too long
- [ ] Service type badges color-coded
- [ ] Date formatted correctly
- [ ] Detail view shows all consultation data
- [ ] Filter works correctly
- [ ] Pull-to-refresh updates list
- [ ] Pagination loads 20 items at a time
- [ ] Delete requires confirmation
- [ ] Deleted consultation removed immediately
- [ ] Empty state shown when no consultations

**Test on:**
- [ ] Android device
- [ ] iOS device

### Scenario 7: Re-analyze Consultation

**Objective:** Test re-analyzing existing consultation

**Steps:**
1. Navigate to consultation history
2. Tap on an existing consultation
3. View consultation details
4. Tap "Re-analyze" button
5. Verify image loads in annotation editor
6. Verify existing markers are NOT pre-loaded
7. Add new markers
8. Submit for analysis
9. Verify new consultation created
10. Verify original consultation unchanged

**Expected Results:**
- [ ] Re-analyze button visible in detail view
- [ ] Image loads correctly
- [ ] Annotation editor starts fresh (no old markers)
- [ ] New analysis creates new consultation record
- [ ] Original consultation preserved in history
- [ ] Both consultations visible in history

---

## Error Scenario Testing

### Error Test 1: Network Errors

#### Test 1.1: No Internet Connection
**Steps:**
1. Disable WiFi and mobile data
2. Attempt to submit consultation
3. Verify error handling

**Expected:**
- [ ] Error dialog: "No internet connection"
- [ ] "Retry" button available
- [ ] Consultation data preserved locally
- [ ] After reconnecting, retry works

#### Test 1.2: Slow Network
**Steps:**
1. Enable network throttling (slow 3G)
2. Submit consultation
3. Monitor progress

**Expected:**
- [ ] Progress indicator shows
- [ ] Request completes (may take longer)
- [ ] Timeout after 60 seconds if too slow
- [ ] Timeout error shows "Retry" option

#### Test 1.3: Server Error (500)
**Steps:**
1. Simulate server error (stop backend)
2. Attempt to submit consultation
3. Verify error handling

**Expected:**
- [ ] Error dialog: "Server error, please try again"
- [ ] "Retry" button available
- [ ] "Contact Support" option available

### Error Test 2: AI Service Errors

#### Test 2.1: Ollama Service Unavailable
**Steps:**
1. Stop Ollama service: `docker stop gharsewa_ollama`
2. Submit consultation
3. Verify error handling
4. Restart Ollama: `docker start gharsewa_ollama`
5. Retry consultation

**Expected:**
- [ ] Error after retry attempts: "AI service temporarily unavailable"
- [ ] "Try Again Later" button shown
- [ ] After service restart, retry works
- [ ] No data loss

#### Test 2.2: AI Analysis Timeout
**Steps:**
1. Submit consultation with very large image
2. Wait for timeout (30 seconds)
3. Verify timeout handling

**Expected:**
- [ ] Progress indicator shows for 30 seconds
- [ ] Timeout dialog appears
- [ ] Options: "Keep Waiting" or "Cancel"
- [ ] "Keep Waiting" extends timeout
- [ ] "Cancel" returns to annotation editor

### Error Test 3: Permission Errors

#### Test 3.1: Camera Permission Denied
**Steps:**
1. Deny camera permission
2. Attempt to take photo
3. Verify error handling

**Expected:**
- [ ] Error dialog: "Camera permission required"
- [ ] "Open Settings" button shown
- [ ] Tapping button opens app settings
- [ ] After granting permission, camera works

#### Test 3.2: Storage Permission Denied (Android)
**Steps:**
1. Deny storage permission
2. Attempt to select from gallery
3. Verify error handling

**Expected:**
- [ ] Error dialog: "Storage permission required"
- [ ] "Open Settings" button shown
- [ ] Tapping button opens app settings
- [ ] After granting permission, gallery works

### Error Test 4: Validation Errors

#### Test 4.1: No Markers Added
**Steps:**
1. Load image in annotation editor
2. Attempt to submit without adding markers
3. Verify validation

**Expected:**
- [ ] Error message: "Please add at least one defect marker"
- [ ] Submit button disabled or shows error
- [ ] User can add markers and retry

#### Test 4.2: Empty Marker Description
**Steps:**
1. Add marker
2. Leave description empty
3. Attempt to save marker
4. Verify validation

**Expected:**
- [ ] Error: "Description is required"
- [ ] Marker not saved until description provided
- [ ] Description must be 2-500 characters

### Error Test 5: Authentication Errors

#### Test 5.1: Token Expired
**Steps:**
1. Wait for JWT token to expire (or manually expire)
2. Attempt to submit consultation
3. Verify error handling

**Expected:**
- [ ] Error: "Session expired, please login again"
- [ ] Redirect to login screen
- [ ] After login, user can retry

#### Test 5.2: Unauthorized Access
**Steps:**
1. Logout
2. Attempt to access AI Assistant
3. Verify redirect

**Expected:**
- [ ] Redirect to login screen
- [ ] Error message: "Please login to continue"
- [ ] After login, access granted

---

## Performance Testing

### Performance Test 1: Image Loading

**Metrics to measure:**
- [ ] Camera preview loads within 2 seconds
- [ ] Gallery opens within 2 seconds
- [ ] Selected image loads within 2 seconds
- [ ] Annotation editor renders within 1 second

**Test with:**
- [ ] Small images (< 1MB)
- [ ] Medium images (2-3MB)
- [ ] Large images (5-8MB)

### Performance Test 2: Marker Rendering

**Steps:**
1. Add 10 markers to image
2. Measure rendering performance
3. Test marker interactions

**Expected:**
- [ ] Markers render within 100ms of tap
- [ ] Canvas remains responsive with 10 markers
- [ ] No lag when scrolling marker list
- [ ] Smooth animations

### Performance Test 3: AI Analysis Time

**Measure:**
- [ ] Time from submit to results display
- [ ] Expected: 15-35 seconds (Ollama processing)
- [ ] Progress indicator updates smoothly
- [ ] No UI freezing during analysis

**Test with:**
- [ ] Small images (< 1MB): ~15-20 seconds
- [ ] Medium images (2-3MB): ~20-27 seconds
- [ ] Large images (5MB): ~27-35 seconds

### Performance Test 4: History Loading

**Steps:**
1. Create 50+ consultations
2. Navigate to history
3. Measure load time
4. Test pagination

**Expected:**
- [ ] Initial load within 2 seconds
- [ ] First 20 items displayed
- [ ] Pagination loads next 20 within 1 second
- [ ] Smooth scrolling
- [ ] Images lazy-loaded

### Performance Test 5: Memory Usage

**Monitor:**
- [ ] App memory usage during image capture
- [ ] Memory usage during AI analysis
- [ ] Memory usage with 10 markers
- [ ] Memory usage in history with many items

**Expected:**
- [ ] No memory leaks
- [ ] Memory usage < 200MB on average
- [ ] No out-of-memory crashes

---

## Security Testing

### Security Test 1: Authentication

**Verify:**
- [ ] All API calls include JWT token
- [ ] Expired tokens rejected
- [ ] Invalid tokens rejected
- [ ] User can only access own consultations

### Security Test 2: Data Privacy

**Verify:**
- [ ] Customer A cannot view Customer B's consultations
- [ ] Images stored securely
- [ ] Image URLs not guessable
- [ ] Deleted consultations not accessible

### Security Test 3: Input Validation

**Test:**
- [ ] SQL injection attempts blocked
- [ ] XSS attempts blocked
- [ ] File upload validation enforced
- [ ] Coordinate validation enforced

### Security Test 4: HTTPS

**Verify:**
- [ ] All API calls use HTTPS
- [ ] No sensitive data in logs
- [ ] No tokens in URLs

---

## Accessibility Testing

### Accessibility Test 1: Screen Reader Support

**Test on:**
- [ ] Android TalkBack
- [ ] iOS VoiceOver

**Verify:**
- [ ] All buttons have labels
- [ ] Images have descriptions
- [ ] Form fields have labels
- [ ] Navigation is logical
- [ ] Error messages are announced

### Accessibility Test 2: Color Contrast

**Verify:**
- [ ] Text readable on all backgrounds
- [ ] Buttons have sufficient contrast
- [ ] Error messages clearly visible
- [ ] Markers visible on all image types

### Accessibility Test 3: Touch Targets

**Verify:**
- [ ] All buttons at least 44x44 points
- [ ] Markers tappable (40x40 minimum)
- [ ] Sufficient spacing between elements
- [ ] No accidental taps

### Accessibility Test 4: Text Scaling

**Test with:**
- [ ] Small text size
- [ ] Default text size
- [ ] Large text size
- [ ] Extra large text size

**Verify:**
- [ ] All text scales correctly
- [ ] No text truncation
- [ ] No UI overflow
- [ ] Layouts adapt

---

## Test Results Documentation

### Test Execution Log

Use this template to document test results:

```markdown
## Test Session: [Date]

**Tester:** [Name]
**Platform:** [Android/iOS]
**Device:** [Device Model]
**OS Version:** [Version]
**App Version:** [Version]
**Duration:** [Time]

### Tests Executed

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| A1 | Camera Capture Android | ✅ Pass | - |
| A2 | Gallery Selection Android | ✅ Pass | - |
| A3 | Android Permissions | ❌ Fail | See Bug #001 |
| ... | ... | ... | ... |

### Bugs Found

See Bug Report section below.

### Summary

- **Total Tests:** 50
- **Passed:** 47
- **Failed:** 3
- **Blocked:** 0
- **Pass Rate:** 94%

### Recommendations

[Any recommendations for improvements]
```

---

## Bug Reporting Template

Use this template to report bugs:

```markdown
## Bug Report #[Number]

**Title:** [Brief description]

**Severity:** [Critical / High / Medium / Low]

**Priority:** [P0 / P1 / P2 / P3]

**Platform:** [Android / iOS / Both]

**Device:** [Device model and OS version]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots/Videos:**
[Attach evidence]

**Logs:**
```
[Paste relevant logs]
```

**Workaround:**
[If any workaround exists]

**Additional Notes:**
[Any other relevant information]
```

### Bug Severity Definitions

**Critical (P0):**
- App crashes
- Data loss
- Security vulnerabilities
- Feature completely broken

**High (P1):**
- Major feature not working
- Significant user impact
- No workaround available

**Medium (P2):**
- Minor feature issue
- Moderate user impact
- Workaround available

**Low (P3):**
- Cosmetic issues
- Minor inconvenience
- Enhancement requests

---

## Sign-Off Checklist

### Platform Testing
- [ ] Android 8.0+ tested
- [ ] iOS 12.0+ tested
- [ ] Multiple screen sizes tested
- [ ] Physical devices tested (not just emulators)

### Feature Testing
- [ ] Complete consultation flow works
- [ ] Image capture works (camera & gallery)
- [ ] Image validation works
- [ ] Marker placement accurate
- [ ] AI analysis produces good results
- [ ] Provider recommendations relevant
- [ ] Consultation history works
- [ ] Booking integration functional

### Error Handling
- [ ] Network errors handled
- [ ] Permission errors handled
- [ ] Validation errors handled
- [ ] AI service errors handled
- [ ] Authentication errors handled

### Performance
- [ ] Image loading < 2 seconds
- [ ] AI analysis < 35 seconds
- [ ] History loading < 2 seconds
- [ ] No memory leaks
- [ ] Smooth UI interactions

### Security
- [ ] Authentication required
- [ ] Data privacy enforced
- [ ] Input validation works
- [ ] HTTPS used

### Accessibility
- [ ] Screen reader compatible
- [ ] Color contrast sufficient
- [ ] Touch targets adequate
- [ ] Text scaling works

### Documentation
- [ ] Test results documented
- [ ] Bugs reported
- [ ] Screenshots captured
- [ ] Recommendations provided

### Final Sign-Off

**Tested By:** ___________________  
**Date:** ___________________  
**Signature:** ___________________

**QA Manager Approval:** ___________________  
**Date:** ___________________  
**Signature:** ___________________

**Product Owner Approval:** ___________________  
**Date:** ___________________  
**Signature:** ___________________

---

## Appendix

### A. Test Image Samples

Recommended test images for different scenarios:

1. **Plumbing Issues:**
   - Leaking pipe
   - Clogged drain
   - Water damage
   - Rusty fixtures

2. **Electrical Issues:**
   - Exposed wiring
   - Damaged outlets
   - Flickering lights
   - Circuit breaker issues

3. **Carpentry Issues:**
   - Broken door
   - Damaged furniture
   - Cracked wood
   - Loose hinges

4. **Painting Issues:**
   - Peeling paint
   - Wall cracks
   - Water stains
   - Mold growth

### B. Backend API Testing

For backend API testing, refer to:
- `backend/AI_VISUAL_ASSISTANT_TESTING_GUIDE.md`

### C. Automated Test Results

For automated test results, refer to:
- Widget tests: `test/widget/`
- Integration tests: `integration_test/`
- Backend tests: `backend/tests/`

**Current Status:**
- Backend: 108 tests, all passing ✅
- Widget tests: 103 tests ✅
- Integration tests: 19 tests, 16 passing ⚠️

### D. Known Issues

Document any known issues that are not blocking:

1. [Issue description]
   - **Workaround:** [If any]
   - **Planned Fix:** [Version]

### E. Future Enhancements

Potential improvements for future releases:

1. Offline mode with local storage
2. Multiple image upload per consultation
3. Video capture support
4. AR marker placement
5. Voice description input
6. Multi-language support
7. Export consultation as PDF
8. Share consultation with others

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Maintained By:** QA Team  
**Contact:** qa@gharsewa.com

---

## Quick Reference

### Critical Test Paths

**Path 1: Happy Path (15 min)**
1. Login → AI Assistant → New Consultation
2. Take Photo → Add 2 markers → Submit
3. View Results → Book Provider
4. View History → Verify consultation saved

**Path 2: Error Handling (10 min)**
1. Deny camera permission → Verify error
2. Submit without markers → Verify validation
3. Disconnect network → Verify error
4. Reconnect → Retry → Success

**Path 3: Cross-Platform (20 min)**
1. Test on Android device
2. Test on iOS device
3. Compare results
4. Document differences

### Test Priorities

**P0 (Must Test):**
- Complete consultation flow
- Image capture (camera & gallery)
- AI analysis
- Provider recommendations
- Booking integration

**P1 (Should Test):**
- History management
- Error handling
- Permissions
- Image validation

**P2 (Nice to Test):**
- Performance metrics
- Accessibility
- Multiple devices
- Edge cases

---

**END OF MANUAL TESTING & QA GUIDE**
