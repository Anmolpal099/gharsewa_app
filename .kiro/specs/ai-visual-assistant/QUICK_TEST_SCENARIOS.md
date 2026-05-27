# AI Visual Assistant - Quick Test Scenarios

**Purpose:** Rapid smoke testing for quick validation  
**Time Required:** 30-45 minutes  
**Use Case:** Pre-release verification, regression testing, demo preparation

---

## Prerequisites (5 minutes)

1. **Backend Services Running**
   ```bash
   docker ps | grep -E "gharsewa_app|gharsewa_db|gharsewa_ollama"
   ```
   ✅ All 3 services should be running

2. **Test Account Ready**
   - Email: testcustomer@gharsewa.com
   - Password: Test@123
   - ✅ Can login successfully

3. **Test Images Ready**
   - Have 2-3 test images on device (plumbing, electrical issues)
   - ✅ Images are 1-5MB, JPEG/PNG format

---

## Scenario 1: Happy Path (10 minutes)

**Goal:** Verify complete consultation flow works end-to-end

### Steps:

1. **Login** (30 seconds)
   - Open app
   - Login with test account
   - ✅ Dashboard loads

2. **Navigate to AI Assistant** (15 seconds)
   - Tap AI Assistant icon/menu
   - ✅ AI Assistant home screen displays
   - ✅ "New Consultation" and "View History" buttons visible

3. **Capture Image** (1 minute)
   - Tap "New Consultation"
   - Tap "Take Photo" OR "Select from Gallery"
   - Grant permissions if prompted
   - Capture/select image of plumbing issue
   - ✅ Image loads in annotation editor

4. **Add Markers** (2 minutes)
   - Tap on image at leak location
   - Enter description: "Water leaking from pipe"
   - Tap on image at rust location
   - Enter description: "Rust on metal surface"
   - ✅ 2 markers visible on image
   - ✅ Marker list shows both descriptions

5. **Submit for Analysis** (30 seconds)
   - Tap "Submit" button
   - ✅ Progress indicator appears
   - ✅ Message: "Analyzing your image..."

6. **Wait for Results** (15-35 seconds)
   - Wait for AI analysis to complete
   - ✅ Results screen appears within 35 seconds

7. **Review Results** (2 minutes)
   - ✅ Diagnosis displayed (e.g., "Plumbing leak with corrosion")
   - ✅ Service type shown (e.g., "Plumbing Repair")
   - ✅ Cost estimate shown (e.g., "NPR 2,000 - 5,000")
   - ✅ 3 providers recommended (or fewer if < 3 available)
   - ✅ Each provider shows: name, rating, services

8. **Test Booking** (1 minute)
   - Tap "Book Now" on first provider
   - ✅ Booking screen opens
   - ✅ Service type pre-filled
   - ✅ Provider pre-filled
   - ✅ Image attached
   - Go back to results

9. **Verify History** (2 minutes)
   - Go back to AI Assistant home
   - Tap "View History"
   - ✅ New consultation appears in list
   - Tap on consultation
   - ✅ Detail view shows all data correctly

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** ___________

---

## Scenario 2: Error Handling (8 minutes)

**Goal:** Verify app handles errors gracefully

### Test 2.1: Permission Denial (2 minutes)

1. Uninstall and reinstall app (or clear app data)
2. Login
3. Navigate to AI Assistant → New Consultation
4. Tap "Take Photo"
5. **Deny camera permission**
6. ✅ Error dialog appears: "Camera permission required"
7. ✅ "Open Settings" button visible
8. Tap "Open Settings"
9. ✅ App settings open
10. Grant camera permission
11. Return to app
12. Retry "Take Photo"
13. ✅ Camera opens successfully

**Result:** ✅ PASS / ❌ FAIL

### Test 2.2: No Markers Validation (1 minute)

1. Start new consultation
2. Select/capture image
3. **Do NOT add any markers**
4. Tap "Submit"
5. ✅ Error message: "Please add at least one defect marker"
6. ✅ Submit blocked or shows error
7. Add 1 marker
8. ✅ Submit now works

**Result:** ✅ PASS / ❌ FAIL

### Test 2.3: Network Error (3 minutes)

1. Start new consultation
2. Select image and add 2 markers
3. **Turn off WiFi and mobile data**
4. Tap "Submit"
5. ✅ Error dialog: "No internet connection"
6. ✅ "Retry" button visible
7. **Turn on WiFi/data**
8. Tap "Retry"
9. ✅ Submission succeeds
10. ✅ Results displayed

**Result:** ✅ PASS / ❌ FAIL

### Test 2.4: Invalid Image Size (2 minutes)

1. Prepare very small image (< 100KB) or very large (> 10MB)
2. Start new consultation
3. Select the invalid image
4. ✅ Error message appears
5. ✅ Error specifies size requirement
6. ✅ Can retry with different image

**Result:** ✅ PASS / ❌ FAIL

---

## Scenario 3: Marker Functionality (5 minutes)

**Goal:** Verify marker placement, editing, and deletion

### Steps:

1. **Add Multiple Markers** (2 minutes)
   - Start new consultation with image
   - Add 5 markers at different locations
   - ✅ Each marker appears at tap location
   - ✅ Markers numbered 1-5
   - ✅ All descriptions saved

2. **Edit Marker** (1 minute)
   - Tap on marker #3
   - Change description to "Updated description"
   - ✅ Description updates in list

3. **Delete Marker** (1 minute)
   - Delete marker #2
   - ✅ Marker removed from image
   - ✅ Marker removed from list
   - ✅ Remaining markers renumbered

4. **Max Markers** (1 minute)
   - Add markers until you have 10 total
   - Attempt to add 11th marker
   - ✅ Error: "Maximum 10 markers allowed"
   - ✅ 11th marker not added

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** ___________

---

## Scenario 4: History Management (5 minutes)

**Goal:** Verify consultation history features

### Steps:

1. **Create Multiple Consultations** (3 minutes)
   - Create 3 consultations with different images
   - Use different service types if possible
   - ✅ All 3 complete successfully

2. **View History** (1 minute)
   - Navigate to "View History"
   - ✅ All 3 consultations displayed
   - ✅ Sorted by date (newest first)
   - ✅ Thumbnails load
   - ✅ Service type badges visible

3. **View Details** (30 seconds)
   - Tap on middle consultation
   - ✅ Detail view shows complete data
   - ✅ Image, markers, diagnosis, providers all visible

4. **Delete Consultation** (30 seconds)
   - Tap delete button
   - ✅ Confirmation dialog appears
   - Confirm deletion
   - ✅ Consultation removed from list
   - ✅ List updates immediately

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** ___________

---

## Scenario 5: Cross-Platform (10 minutes)

**Goal:** Verify feature works on both Android and iOS

### Test on Android (5 minutes)

1. Run Scenario 1 (Happy Path) on Android device
2. ✅ All steps pass
3. Note any Android-specific issues

**Android Device:** ___________  
**Android Version:** ___________  
**Result:** ✅ PASS / ❌ FAIL

### Test on iOS (5 minutes)

1. Run Scenario 1 (Happy Path) on iOS device
2. ✅ All steps pass
3. Note any iOS-specific issues
4. Test HEIC image format (iOS only)
5. ✅ HEIC images work correctly

**iOS Device:** ___________  
**iOS Version:** ___________  
**Result:** ✅ PASS / ❌ FAIL

### Platform Comparison

**Differences Found:**
- [ ] None - identical behavior
- [ ] Minor UI differences (expected)
- [ ] Functional differences (document below)

**Notes:** ___________

---

## Scenario 6: Performance Check (5 minutes)

**Goal:** Verify performance meets requirements

### Measurements:

1. **Image Loading Time**
   - Select image from gallery
   - Time from selection to annotation editor
   - ⏱️ Actual: _____ seconds
   - ✅ Target: < 2 seconds

2. **AI Analysis Time**
   - Submit consultation
   - Time from submit to results
   - ⏱️ Actual: _____ seconds
   - ✅ Target: 15-35 seconds

3. **History Loading Time**
   - Open history with 5+ consultations
   - Time to display list
   - ⏱️ Actual: _____ seconds
   - ✅ Target: < 2 seconds

4. **Marker Responsiveness**
   - Add 10 markers rapidly
   - ✅ No lag or freezing
   - ✅ Smooth animations

5. **Memory Usage**
   - Monitor app memory during use
   - ✅ No crashes
   - ✅ No excessive memory usage

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** ___________

---

## Quick Smoke Test (15 minutes)

**Use this for rapid verification before demos or releases**

### Checklist:

- [ ] **Login works** (30 sec)
- [ ] **AI Assistant accessible** (15 sec)
- [ ] **Camera capture works** (1 min)
- [ ] **Gallery selection works** (1 min)
- [ ] **Can add 2 markers** (1 min)
- [ ] **Can submit consultation** (30 sec)
- [ ] **AI analysis completes** (30 sec)
- [ ] **Results display correctly** (1 min)
- [ ] **Providers shown** (30 sec)
- [ ] **Book Now works** (1 min)
- [ ] **History shows consultation** (1 min)
- [ ] **Can view details** (30 sec)
- [ ] **Can delete consultation** (30 sec)
- [ ] **No crashes or errors** (throughout)

**Total Time:** ~15 minutes  
**Result:** ✅ ALL PASS / ⚠️ SOME ISSUES / ❌ CRITICAL ISSUES

---

## Test Results Summary

### Session Information

**Date:** ___________  
**Tester:** ___________  
**Duration:** _____ minutes  
**Platform:** [ ] Android  [ ] iOS  [ ] Both

### Results

| Scenario | Status | Time | Notes |
|----------|--------|------|-------|
| 1. Happy Path | ⬜ | | |
| 2. Error Handling | ⬜ | | |
| 3. Marker Functionality | ⬜ | | |
| 4. History Management | ⬜ | | |
| 5. Cross-Platform | ⬜ | | |
| 6. Performance Check | ⬜ | | |

**Overall Status:**
- [ ] ✅ All scenarios passed
- [ ] ⚠️ Minor issues found (document below)
- [ ] ❌ Critical issues found (document below)

### Issues Found

| Issue | Severity | Description |
|-------|----------|-------------|
| 1. | | |
| 2. | | |
| 3. | | |

### Recommendations

```
[Add recommendations here]
```

---

## Quick Reference

### Expected AI Response Times

- Small image (< 1MB): 15-20 seconds
- Medium image (2-3MB): 20-27 seconds
- Large image (5MB): 27-35 seconds

### Expected Service Types

- Plumbing Repair
- Electrical Work
- Carpentry
- Painting
- Cleaning
- Appliance Repair
- HVAC
- Pest Control
- Landscaping
- General Maintenance

### Expected Cost Ranges

- Minimum: NPR 500+
- Maximum: NPR 50,000 or less
- Max should be ≥ 1.5x Min

### Common Issues & Solutions

**Issue:** Camera won't open  
**Solution:** Check permissions in app settings

**Issue:** AI analysis timeout  
**Solution:** Check Ollama service is running

**Issue:** No providers shown  
**Solution:** Check database has providers for service type

**Issue:** Image won't load  
**Solution:** Check image size (100KB - 10MB) and format (JPEG/PNG/HEIC)

---

## Next Steps

After completing quick tests:

1. **If all pass:** ✅ Feature ready for release
2. **If minor issues:** Document and create tickets
3. **If critical issues:** Run full test suite (MANUAL_TESTING_QA_GUIDE.md)

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Related Documents:**
- MANUAL_TESTING_QA_GUIDE.md (Comprehensive testing)
- TEST_EXECUTION_CHECKLIST.md (Detailed checklist)
- AI_VISUAL_ASSISTANT_TESTING_GUIDE.md (Backend API testing)
