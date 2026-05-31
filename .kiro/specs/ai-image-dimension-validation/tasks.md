# Implementation Plan: AI Image Dimension Validation Bugfix

## Overview

This implementation plan follows the bugfix workflow using the bug condition methodology. The plan ensures systematic validation through exploratory testing (to understand the bug), preservation testing (to prevent regressions), implementation (to fix the bug), and verification (to confirm the fix works). The bug is that images smaller than 32x32 pixels pass validation and crash the Ollama qwen3vl model with a 500 error. The fix adds dimension validation to the Base64Image rule to reject small images with a clear 422 error message.

## Tasks

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Small Image Rejection
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test implementation details from Bug Condition in design
  - The test assertions should match the Expected Behavior Properties from design
  - Create property-based test in `backend/tests/Unit/Rules/Base64ImageDimensionTest.php`
  - Generate test images with dimensions in range [1, 31] x [1, 31] pixels
  - For each small image (width < 32 OR height < 32):
    - Encode image to base64
    - Create validator with Base64Image rule
    - Assert validation PASSES on unfixed code (bug: should fail but doesn't)
    - Document that these images would crash Ollama with "height:X or width:Y must be larger than factor:32"
  - Test specific failing cases:
    - 1x1 pixel PNG (passes validation on unfixed code)
    - 16x16 pixel PNG (passes validation on unfixed code)
    - 31x32 pixel PNG (width below threshold, passes on unfixed code)
    - 32x31 pixel PNG (height below threshold, passes on unfixed code)
    - 31x31 pixel PNG (both dimensions below threshold, passes on unfixed code)
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Valid Image Processing
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Create property-based test in `backend/tests/Unit/Rules/Base64ImagePreservationTest.php`
  - Test cases to observe on UNFIXED code:
    - **32x32 Pixel Image**: Observe that 32x32 pixel images pass validation
    - **Large Valid Image**: Observe that 400x400 pixel images pass validation
    - **Non-Square Valid Image**: Observe that 32x100 and 100x32 pixel images pass validation
    - **Oversized Image Rejection**: Observe that images exceeding max size (10MB) fail with size error
    - **Invalid Format Rejection**: Observe that non-image data fails with format error
    - **Invalid Base64 Rejection**: Observe that invalid base64 strings fail with base64 error
    - **Data URI Format**: Observe that images with "data:image/png;base64," prefix pass validation
  - Write property-based tests:
    - Generate random valid images with dimensions >= 32x32 and verify they pass validation
    - Generate random oversized images (> max file size) and verify they fail with size error
    - Generate random invalid base64 strings and verify they fail with base64 error
    - Generate random invalid formats and verify they fail with format error
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Fix for AI Image Dimension Validation

  - [x] 3.1 Implement the dimension validation fix
    - Open `backend/app/Rules/Base64Image.php`
    - Locate the `validate()` method (around line 40)
    - After the existing `getimagesizefromstring()` call (line 69), extract dimensions:
      ```php
      // Extract dimensions (already available from getimagesizefromstring)
      $width = $imageInfo[0];
      $height = $imageInfo[1];
      ```
    - After MIME type validation (after line 87), add dimension validation:
      ```php
      // Validate minimum dimensions (required by qwen3vl model: factor:32)
      if ($width < 32 || $height < 32) {
          $fail("The :attribute must be at least 32x32 pixels. Your image is {$width}x{$height} pixels.");
          return;
      }
      ```
    - Ensure no other validation logic is modified
    - _Bug_Condition: isBugCondition(input) where width < 32 OR height < 32_
    - _Expected_Behavior: Reject with 422 and message "The image must be at least 32x32 pixels. Your image is {width}x{height} pixels."_
    - _Preservation: All existing validations (format, size, MIME type, base64) continue to work unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Small Image Rejection
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1: `php artisan test --filter=Base64ImageDimensionTest`
    - Verify that small images (< 32x32) now FAIL validation with dimension error message
    - Verify error message format: "The image must be at least 32x32 pixels. Your image is {width}x{height} pixels."
    - Verify specific cases:
      - 1x1 pixel PNG fails with "Your image is 1x1 pixels"
      - 16x16 pixel PNG fails with "Your image is 16x16 pixels"
      - 31x32 pixel PNG fails with "Your image is 31x32 pixels"
      - 32x31 pixel PNG fails with "Your image is 32x31 pixels"
      - 31x31 pixel PNG fails with "Your image is 31x31 pixels"
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - _Requirements: 2.1, 2.2_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Valid Image Processing
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2: `php artisan test --filter=Base64ImagePreservationTest`
    - Verify that valid images (>= 32x32) still pass validation
    - Verify that oversized images still fail with size error (not dimension error)
    - Verify that invalid formats still fail with format error (not dimension error)
    - Verify that invalid base64 still fails with base64 error (not dimension error)
    - Verify that data URI format still works correctly
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Write fix verification unit tests
  - Create comprehensive unit test suite in `backend/tests/Unit/Rules/Base64ImageTest.php`
  - Test boundary cases around 32x32 pixel threshold:
    - Test 1x1 pixel image fails with dimension error
    - Test 16x16 pixel image fails with dimension error
    - Test 31x32 pixel image fails (width below threshold)
    - Test 32x31 pixel image fails (height below threshold)
    - Test 31x31 pixel image fails (both dimensions below threshold)
    - Test 32x32 pixel image passes (exact minimum)
    - Test 33x33 pixel image passes (above minimum)
    - Test 100x100 pixel image passes (well above minimum)
  - Test error message format:
    - Verify error message contains "must be at least 32x32 pixels"
    - Verify error message includes actual dimensions "{width}x{height}"
    - Verify error message uses `:attribute` placeholder
  - Test validation order:
    - Verify invalid format fails before dimension check (format error, not dimension error)
    - Verify invalid base64 fails before dimension check (base64 error, not dimension error)
    - Verify oversized image fails with size error (not dimension error)
  - Test different image formats:
    - Test small PNG fails with dimension error
    - Test small JPEG fails with dimension error
    - Test small HEIC fails with dimension error (if supported)
  - Run tests: `php artisan test --filter=Base64ImageTest`
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 5. Integration testing
  - Test full API flow with AI consultation endpoint
  - Create integration test in `backend/tests/Feature/AI/ConsultationCreationTest.php`
  - Test cases:
    - **Small Image Rejection**: POST to `/api/v1/customer/ai/consultations` with 16x16 pixel image
      - Verify response is 422 Unprocessable Entity (not 500)
      - Verify error message: "The image must be at least 32x32 pixels. Your image is 16x16 pixels."
      - Verify Ollama is NOT called (validation fails before reaching VisionAIService)
    - **Valid Image Processing**: POST to `/api/v1/customer/ai/consultations` with 400x400 pixel image
      - Verify response is 200 OK with AI analysis results
      - Verify VisionAIService is called successfully
      - Verify Ollama processes the image without crashing
    - **Boundary Case**: POST with exactly 32x32 pixel image
      - Verify response is 200 OK (minimum valid size)
      - Verify image is processed successfully
    - **Non-Square Valid Image**: POST with 32x100 pixel image
      - Verify response is 200 OK
      - Verify image is processed successfully
  - Test error message user-friendliness:
    - Verify error message is clear and actionable
    - Verify actual dimensions are included for debugging
    - Verify no technical jargon or internal error details
  - Test that fix prevents Ollama crashes:
    - Verify no 500 errors for small images
    - Verify no "model runner has unexpectedly stopped" errors
    - Verify no "height:X or width:Y must be larger than factor:32" errors reach the API response
  - Run integration tests: `php artisan test --filter=ConsultationCreationTest`
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.5_

- [ ] 6. Checkpoint - Ensure all tests pass
  - Run full test suite: `php artisan test`
  - Verify all unit tests pass
  - Verify all property-based tests pass
  - Verify all integration tests pass
  - Verify no regressions in existing functionality
  - Test manually with real images if needed:
    - Create a 16x16 pixel PNG and test via API (should return 422)
    - Create a 400x400 pixel PNG and test via API (should return 200)
  - Ask the user if questions arise or if manual testing is needed

## Notes

- This bugfix follows the bug condition methodology with four phases: Explore, Preserve, Implement, Validate
- Task 1 (exploration test) MUST be written and run on UNFIXED code BEFORE implementing the fix
- Task 2 (preservation tests) MUST be written and run on UNFIXED code BEFORE implementing the fix
- The exploration test is expected to FAIL on unfixed code (this confirms the bug exists)
- The preservation tests are expected to PASS on unfixed code (this establishes baseline behavior)
- After implementing the fix (task 3.1), the exploration test should PASS (confirming the fix works)
- After implementing the fix (task 3.1), the preservation tests should still PASS (confirming no regressions)
- Property-based testing is used for exploration and preservation to generate many test cases automatically
- All tasks reference specific requirements from bugfix.md for traceability
- The fix is minimal and targeted: add dimension validation after existing format/size checks
- No changes to other validation logic or VisionAIService are required
- The fix prevents Ollama crashes by rejecting small images during validation (422) instead of allowing them to reach Ollama (500)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1"] },
    { "id": 1, "tasks": ["2"] },
    { "id": 2, "tasks": ["3.1"] },
    { "id": 3, "tasks": ["3.2", "3.3"] },
    { "id": 4, "tasks": ["4"] },
    { "id": 5, "tasks": ["5"] },
    { "id": 6, "tasks": ["6"] }
  ]
}
```
