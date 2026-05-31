# AI Image Dimension Validation Bugfix Design

## Overview

This bugfix addresses a critical validation gap in the `Base64Image` validation rule that allows images smaller than 32x32 pixels to pass validation and reach the Ollama qwen3vl model, causing it to crash with a 500 Internal Server Error. The fix adds dimension validation after existing format and size checks, rejecting images that don't meet the minimum 32x32 pixel requirement with a clear, actionable error message.

The solution is minimal and targeted: extract width and height from the existing `getimagesizefromstring()` result (which is already called for format validation), check both dimensions are >= 32 pixels, and fail with a descriptive error message if not. This prevents the bug without modifying any other validation logic or behavior.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when images with width < 32 OR height < 32 pixels pass validation and reach Ollama
- **Property (P)**: The desired behavior when small images are submitted - they should be rejected during validation with a 422 error and clear message
- **Preservation**: Existing validation behavior for valid images (>= 32x32), oversized images, invalid formats, and invalid base64 that must remain unchanged
- **Base64Image**: The validation rule class in `backend/app/Rules/Base64Image.php` that validates base64-encoded images
- **getimagesizefromstring()**: PHP function that returns image metadata including width (index 0) and height (index 1) from binary image data
- **qwen3vl**: The Ollama vision model with a `factor:32` constraint requiring images to be at least 32x32 pixels
- **VisionAIService**: The service in `backend/app/Services/AI/VisionAIService.php` that processes images and calls Ollama

## Bug Details

### Bug Condition

The bug manifests when an image with dimensions smaller than 32x32 pixels is submitted to the AI consultation endpoint. The `Base64Image` validation rule successfully validates the base64 format, file size, and MIME type, but does not check image dimensions. This allows the small image to pass validation and reach the `VisionAIService`, which encodes it and sends it to Ollama's qwen3vl model. The model has a `factor:32` constraint in its image processor that requires both width and height to be at least 32 pixels, causing it to crash with the error "height:1 or width:1 must be larger than factor:32".

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type Base64ImageString
  OUTPUT: boolean
  
  imageData := base64_decode(input)
  imageInfo := getimagesizefromstring(imageData)
  width := imageInfo[0]
  height := imageInfo[1]
  
  RETURN (width < 32 OR height < 32)
         AND validBase64Format(input)
         AND validFileSize(input)
         AND validMimeType(input)
         AND NOT dimensionValidationPerformed(input)
END FUNCTION
```

### Examples

- **1x1 pixel image**: A tiny transparent PNG (1x1) passes all current validations but crashes Ollama with "height:1 or width:1 must be larger than factor:32"
- **16x16 pixel icon**: A small icon (16x16) passes validation but crashes Ollama
- **31x32 pixel image**: An image with width=31 and height=32 passes validation but crashes Ollama (both dimensions must be >= 32)
- **32x32 pixel image**: Should pass validation and process successfully (minimum valid size)
- **100x100 pixel image**: Should pass validation and process successfully (well above minimum)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Images with valid dimensions (width >= 32 AND height >= 32) and valid format (JPEG, PNG, HEIC) must continue to be accepted and processed successfully
- Images exceeding the maximum file size (10MB) must continue to be rejected with the existing file size error message
- Images with invalid formats (not JPEG, PNG, or HEIC) must continue to be rejected with the existing format error message
- Images with invalid base64 encoding must continue to be rejected with the existing base64 validation error
- All validation failures must continue to return 422 Unprocessable Entity responses (not 500)

**Scope:**
All inputs that do NOT have dimensions smaller than 32x32 pixels should be completely unaffected by this fix. This includes:
- Valid images with dimensions >= 32x32 pixels
- Images that fail other validations (format, size, base64 encoding)
- The order and behavior of existing validation checks

## Hypothesized Root Cause

Based on the bug description and code analysis, the root cause is clear:

1. **Missing Dimension Validation**: The `Base64Image` validation rule calls `getimagesizefromstring()` to validate the image format and extract MIME type information, but does not extract or validate the width and height dimensions that are also returned by this function.

2. **Incomplete Validation Chain**: The validation rule checks:
   - Base64 format (lines 44-48)
   - Decoded data validity (lines 51-55)
   - File size (lines 58-66)
   - Image format validity (lines 69-73)
   - MIME type (lines 76-87)
   
   But it never checks the dimensions available in `$imageInfo[0]` (width) and `$imageInfo[1]` (height).

3. **Ollama Model Constraint**: The qwen3vl model has a hard requirement (`factor:32`) that both image dimensions must be at least 32 pixels. When this constraint is violated, the model crashes with an internal error rather than returning a validation error.

4. **Error Propagation**: The crash in Ollama propagates back through the VisionAIService as a generic exception, which the API returns as a 500 Internal Server Error with an unhelpful message about the model runner stopping unexpectedly.

## Correctness Properties

Property 1: Bug Condition - Small Image Rejection

_For any_ base64-encoded image input where the decoded image has width < 32 pixels OR height < 32 pixels, the fixed Base64Image validation rule SHALL reject the image with a 422 Unprocessable Entity response containing the error message "The image must be at least 32x32 pixels. Your image is {width}x{height} pixels."

**Validates: Requirements 2.1, 2.2**

Property 2: Preservation - Valid Image Processing

_For any_ base64-encoded image input where the decoded image has width >= 32 pixels AND height >= 32 pixels AND passes all other existing validations (format, size, MIME type), the fixed validation rule SHALL produce exactly the same result as the original rule (acceptance), preserving all existing functionality for valid images.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Fix Implementation

### Changes Required

**File**: `backend/app/Rules/Base64Image.php`

**Function**: `validate(string $attribute, mixed $value, Closure $fail): void`

**Specific Changes**:

1. **Extract Dimensions from Existing Data**: After the existing `getimagesizefromstring()` call (line 69), extract width and height from the `$imageInfo` array:
   ```php
   // Extract dimensions (already available from getimagesizefromstring)
   $width = $imageInfo[0];
   $height = $imageInfo[1];
   ```

2. **Add Dimension Validation**: After MIME type validation (after line 87), add dimension check:
   ```php
   // Validate minimum dimensions (required by qwen3vl model: factor:32)
   if ($width < 32 || $height < 32) {
       $fail("The :attribute must be at least 32x32 pixels. Your image is {$width}x{$height} pixels.");
       return;
   }
   ```

3. **Placement Rationale**: The dimension check is placed AFTER format/MIME validation because:
   - We need `$imageInfo` to exist (from `getimagesizefromstring()`)
   - We want to validate format first (more fundamental validation)
   - We want to provide the most specific error message possible
   - This matches the existing validation order: format → size → MIME → dimensions

4. **No Changes to Other Validations**: All existing validation logic remains unchanged:
   - Base64 format validation (lines 44-48)
   - Decoded data validation (lines 51-55)
   - File size validation (lines 58-66)
   - Image format validation (lines 69-73)
   - MIME type validation (lines 76-87)

5. **Error Message Format**: The error message follows Laravel's validation message conventions:
   - Uses `:attribute` placeholder for field name
   - Provides clear requirement ("must be at least 32x32 pixels")
   - Shows actual dimensions for debugging ("{width}x{height} pixels")
   - Actionable (user knows exactly what to fix)

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code (small images pass validation and crash Ollama), then verify the fix works correctly (small images are rejected during validation) and preserves existing behavior (valid images still pass, other validations still work).

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that small images (< 32x32 pixels) currently pass the Base64Image validation rule and would reach the Ollama service.

**Test Plan**: Write property-based tests that generate images with various dimensions, focusing on the boundary around 32x32 pixels. Run these tests on the UNFIXED code to observe that small images pass validation when they should fail.

**Test Cases**:
1. **1x1 Pixel Image Test**: Create a 1x1 pixel PNG, encode to base64, validate with Base64Image rule (will pass on unfixed code, should fail after fix)
2. **16x16 Pixel Image Test**: Create a 16x16 pixel PNG, encode to base64, validate with Base64Image rule (will pass on unfixed code, should fail after fix)
3. **31x32 Pixel Image Test**: Create a 31x32 pixel PNG (width below threshold), validate (will pass on unfixed code, should fail after fix)
4. **32x31 Pixel Image Test**: Create a 32x31 pixel PNG (height below threshold), validate (will pass on unfixed code, should fail after fix)
5. **31x31 Pixel Image Test**: Create a 31x31 pixel PNG (both dimensions below threshold), validate (will pass on unfixed code, should fail after fix)

**Expected Counterexamples**:
- Small images (< 32x32) pass the Base64Image validation rule on unfixed code
- These images would reach VisionAIService and crash Ollama with "height:X or width:Y must be larger than factor:32"
- Possible causes: dimension validation is missing from the validation rule

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (images with width < 32 OR height < 32), the fixed function produces the expected behavior (validation failure with clear error message).

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  validator := Validator::make(['image' => input], ['image' => new Base64Image()])
  ASSERT validator.fails() = true
  ASSERT validator.errors().first('image') CONTAINS "must be at least 32x32 pixels"
  ASSERT validator.errors().first('image') CONTAINS actual dimensions
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (images with width >= 32 AND height >= 32, or images that fail other validations), the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT Base64Image_original.validate(input) = Base64Image_fixed.validate(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss (e.g., exactly 32x32, very large dimensions, non-square images)
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for valid images (>= 32x32), oversized images, invalid formats, and invalid base64, then write property-based tests capturing that behavior.

**Test Cases**:
1. **32x32 Pixel Image Preservation**: Observe that 32x32 pixel images pass validation on unfixed code, write test to verify this continues after fix
2. **Large Valid Image Preservation**: Observe that 400x400 pixel images pass validation on unfixed code, write test to verify this continues after fix
3. **Non-Square Valid Image Preservation**: Observe that 32x100 and 100x32 pixel images pass validation on unfixed code, write test to verify this continues after fix
4. **Oversized Image Rejection Preservation**: Observe that images exceeding max size fail with size error on unfixed code, write test to verify this continues after fix
5. **Invalid Format Rejection Preservation**: Observe that non-image data fails with format error on unfixed code, write test to verify this continues after fix
6. **Invalid Base64 Rejection Preservation**: Observe that invalid base64 strings fail with base64 error on unfixed code, write test to verify this continues after fix
7. **Data URI Format Preservation**: Observe that images with "data:image/png;base64," prefix pass validation on unfixed code, write test to verify this continues after fix

### Unit Tests

- Test that 1x1 pixel image fails validation with dimension error message
- Test that 16x16 pixel image fails validation with dimension error message
- Test that 31x32 pixel image fails validation (width below threshold)
- Test that 32x31 pixel image fails validation (height below threshold)
- Test that 31x31 pixel image fails validation (both dimensions below threshold)
- Test that 32x32 pixel image passes validation (exact minimum)
- Test that 33x33 pixel image passes validation (above minimum)
- Test that 100x100 pixel image passes validation (well above minimum)
- Test that error message includes actual dimensions
- Test that dimension validation occurs after format validation (invalid format fails before dimension check)

### Property-Based Tests

- Generate random images with dimensions in range [1, 100] x [1, 100] and verify:
  - Images with width < 32 OR height < 32 fail with dimension error
  - Images with width >= 32 AND height >= 32 pass validation (if other validations pass)
- Generate random valid images with dimensions >= 32x32 and verify they continue to pass validation
- Generate random oversized images (> max file size) and verify they continue to fail with size error
- Generate random invalid base64 strings and verify they continue to fail with base64 error

### Integration Tests

- Test full AI consultation creation flow with small image (< 32x32) - should return 422 with dimension error, not 500
- Test full AI consultation creation flow with valid image (>= 32x32) - should return 200 with AI analysis results
- Test that dimension validation error message is user-friendly and actionable
- Test that the fix prevents Ollama crashes (no 500 errors for small images)
