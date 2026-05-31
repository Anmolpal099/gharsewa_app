<?php

namespace Tests\Unit\Rules;

use App\Rules\Base64Image;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

/**
 * Property 2: Preservation - Valid Image Processing
 * 
 * **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
 * 
 * IMPORTANT: This test follows observation-first methodology.
 * These tests run on UNFIXED code to observe and document baseline behavior
 * that must be preserved after implementing the dimension validation fix.
 * 
 * EXPECTED OUTCOME: All tests PASS on unfixed code (confirms baseline behavior).
 * After fix: All tests must STILL PASS (confirms preservation).
 * 
 * Test Strategy:
 * - Observe behavior on UNFIXED code for non-buggy inputs
 * - Document observed behavior patterns from Preservation Requirements
 * - Verify fix doesn't break existing functionality
 */
class Base64ImagePreservationTest extends TestCase
{
    /**
     * Create a test image with specific dimensions.
     * 
     * @param int $width Image width in pixels
     * @param int $height Image height in pixels
     * @return string Base64 encoded PNG image
     */
    private function createTestImage(int $width, int $height): string
    {
        $image = imagecreatetruecolor($width, $height);
        
        // Fill with a simple color
        $color = imagecolorallocate($image, 100, 150, 200);
        imagefill($image, 0, 0, $color);
        
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        return base64_encode($imageData);
    }

    /**
     * Create a large test image with specific size in KB.
     * 
     * @param int $sizeKb Target size in kilobytes
     * @return string Base64 encoded PNG image
     */
    private function createLargeTestImage(int $sizeKb): string
    {
        // Calculate dimensions to achieve target size
        // PNG images are roughly 4 bytes per pixel (RGBA)
        $targetBytes = $sizeKb * 1024;
        $pixelsNeeded = $targetBytes / 4;
        $dimension = (int) sqrt($pixelsNeeded);
        
        // Ensure minimum size for visibility
        $width = max($dimension, 400);
        $height = max($dimension, 400);
        
        $image = imagecreatetruecolor($width, $height);
        
        // Fill with random colors to prevent compression
        for ($x = 0; $x < $width; $x += 10) {
            for ($y = 0; $y < $height; $y += 10) {
                $color = imagecolorallocate($image, rand(0, 255), rand(0, 255), rand(0, 255));
                imagefilledrectangle($image, $x, $y, $x + 10, $y + 10, $color);
            }
        }
        
        ob_start();
        imagepng($image, null, 0); // No compression to maintain size
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        return base64_encode($imageData);
    }

    /**
     * Test Case 1: 32x32 Pixel Image Preservation
     * 
     * **Validates: Requirement 3.1**
     * 
     * Observe: 32x32 pixel images pass validation on unfixed code.
     * Preserve: After fix, 32x32 pixel images must still pass validation.
     */
    public function test_32x32_pixel_image_passes_validation(): void
    {
        $image32x32 = $this->createTestImage(32, 32);
        $validator = Validator::make(
            ['image' => $image32x32],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: 32x32 pixel image passes validation (minimum valid size)
        // PRESERVATION: This behavior must continue after fix
        $this->assertFalse(
            $validator->fails(),
            'Preservation failed: 32x32 pixel image should pass validation (minimum valid size)'
        );
    }

    /**
     * Test Case 2: Large Valid Image Preservation
     * 
     * **Validates: Requirement 3.1**
     * 
     * Observe: 400x400 pixel images pass validation on unfixed code.
     * Preserve: After fix, large valid images must still pass validation.
     */
    public function test_large_valid_image_passes_validation(): void
    {
        $image400x400 = $this->createTestImage(400, 400);
        $validator = Validator::make(
            ['image' => $image400x400],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: 400x400 pixel image passes validation
        // PRESERVATION: This behavior must continue after fix
        $this->assertFalse(
            $validator->fails(),
            'Preservation failed: 400x400 pixel image should pass validation'
        );
    }

    /**
     * Test Case 3: Non-Square Valid Image Preservation (32x100)
     * 
     * **Validates: Requirement 3.1**
     * 
     * Observe: 32x100 pixel images pass validation on unfixed code.
     * Preserve: After fix, non-square images with valid dimensions must still pass.
     */
    public function test_non_square_32x100_image_passes_validation(): void
    {
        $image32x100 = $this->createTestImage(32, 100);
        $validator = Validator::make(
            ['image' => $image32x100],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: 32x100 pixel image passes validation (width at minimum, height above)
        // PRESERVATION: This behavior must continue after fix
        $this->assertFalse(
            $validator->fails(),
            'Preservation failed: 32x100 pixel image should pass validation'
        );
    }

    /**
     * Test Case 4: Non-Square Valid Image Preservation (100x32)
     * 
     * **Validates: Requirement 3.1**
     * 
     * Observe: 100x32 pixel images pass validation on unfixed code.
     * Preserve: After fix, non-square images with valid dimensions must still pass.
     */
    public function test_non_square_100x32_image_passes_validation(): void
    {
        $image100x32 = $this->createTestImage(100, 32);
        $validator = Validator::make(
            ['image' => $image100x32],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: 100x32 pixel image passes validation (height at minimum, width above)
        // PRESERVATION: This behavior must continue after fix
        $this->assertFalse(
            $validator->fails(),
            'Preservation failed: 100x32 pixel image should pass validation'
        );
    }

    /**
     * Test Case 5: Oversized Image Rejection Preservation
     * 
     * **Validates: Requirement 3.2**
     * 
     * Observe: Images exceeding max size (10MB) fail with size error on unfixed code.
     * Preserve: After fix, oversized images must still fail with the same error.
     */
    public function test_oversized_image_fails_with_size_error(): void
    {
        // Create a large image (500KB) and test with a small limit (200KB)
        $largeImage = $this->createLargeTestImage(500);
        
        $validator = Validator::make(
            ['image' => $largeImage],
            ['image' => new Base64Image(200)] // 200KB limit
        );
        
        // OBSERVATION: Oversized images fail validation with size error
        // PRESERVATION: This behavior must continue after fix
        $this->assertTrue(
            $validator->fails(),
            'Preservation failed: Oversized image should fail validation'
        );
        
        $error = $validator->errors()->first('image');
        $this->assertStringContainsString(
            'must not exceed 200KB',
            $error,
            'Preservation failed: Error message should mention size limit'
        );
    }

    /**
     * Test Case 6: Invalid Format Rejection Preservation
     * 
     * **Validates: Requirement 3.3**
     * 
     * Observe: Non-image data fails with format error on unfixed code.
     * Preserve: After fix, invalid formats must still fail with the same error.
     */
    public function test_invalid_format_fails_with_format_error(): void
    {
        // Create non-image data (text)
        $textData = str_repeat('This is not an image. ', 10000);
        $base64Text = base64_encode($textData);
        
        $validator = Validator::make(
            ['image' => $base64Text],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: Non-image data fails validation with format error
        // PRESERVATION: This behavior must continue after fix
        $this->assertTrue(
            $validator->fails(),
            'Preservation failed: Non-image data should fail validation'
        );
        
        $error = $validator->errors()->first('image');
        $this->assertStringContainsString(
            'valid image file',
            $error,
            'Preservation failed: Error message should mention invalid image format'
        );
    }

    /**
     * Test Case 7: Invalid Base64 Rejection Preservation
     * 
     * **Validates: Requirement 3.4**
     * 
     * Observe: Invalid base64 strings fail with base64 error on unfixed code.
     * Preserve: After fix, invalid base64 must still fail with the same error.
     */
    public function test_invalid_base64_fails_with_base64_error(): void
    {
        // Create invalid base64 string
        $invalidBase64 = 'not-a-valid-base64-string!!!';
        
        $validator = Validator::make(
            ['image' => $invalidBase64],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: Invalid base64 fails validation with base64 error
        // PRESERVATION: This behavior must continue after fix
        $this->assertTrue(
            $validator->fails(),
            'Preservation failed: Invalid base64 should fail validation'
        );
        
        $error = $validator->errors()->first('image');
        $this->assertStringContainsString(
            'valid base64 encoded',
            $error,
            'Preservation failed: Error message should mention base64 encoding'
        );
    }

    /**
     * Test Case 8: Data URI Format Preservation
     * 
     * **Validates: Requirement 3.1**
     * 
     * Observe: Images with "data:image/png;base64," prefix pass validation on unfixed code.
     * Preserve: After fix, data URI format must still be supported.
     */
    public function test_data_uri_format_passes_validation(): void
    {
        $image32x32 = $this->createTestImage(32, 32);
        $dataUri = 'data:image/png;base64,' . $image32x32;
        
        $validator = Validator::make(
            ['image' => $dataUri],
            ['image' => new Base64Image(10240)]
        );
        
        // OBSERVATION: Images with data URI prefix pass validation
        // PRESERVATION: This behavior must continue after fix
        $this->assertFalse(
            $validator->fails(),
            'Preservation failed: Image with data URI prefix should pass validation'
        );
    }

    /**
     * Property-Based Test: Multiple Valid Dimensions
     * 
     * **Validates: Requirement 3.1**
     * 
     * Test multiple valid dimension combinations to ensure preservation
     * across a range of inputs (property-based testing approach).
     */
    public function test_multiple_valid_dimensions_pass_validation(): void
    {
        // Test various valid dimension combinations
        $validDimensions = [
            [32, 32],   // Minimum valid
            [33, 33],   // Just above minimum
            [50, 50],   // Small valid
            [100, 100], // Medium valid
            [200, 200], // Large valid
            [32, 64],   // Non-square (min width)
            [64, 32],   // Non-square (min height)
            [100, 200], // Non-square medium
            [500, 100], // Very non-square
        ];

        foreach ($validDimensions as [$width, $height]) {
            $image = $this->createTestImage($width, $height);
            $validator = Validator::make(
                ['image' => $image],
                ['image' => new Base64Image(10240)]
            );
            
            // OBSERVATION: All images with dimensions >= 32x32 pass validation
            // PRESERVATION: This behavior must continue after fix
            $this->assertFalse(
                $validator->fails(),
                "Preservation failed: {$width}x{$height} pixel image should pass validation"
            );
        }
    }

    /**
     * Property-Based Test: Validation Order Preservation
     * 
     * **Validates: Requirement 3.5**
     * 
     * Observe: Validation failures return 422 responses (not 500) on unfixed code.
     * Preserve: After fix, validation failures must still return 422 responses.
     * 
     * Note: This test verifies the validation rule behavior. The actual HTTP
     * response code is handled by Laravel's validation system.
     */
    public function test_validation_failures_return_proper_errors(): void
    {
        // Test that validation failures produce error messages (not exceptions)
        $testCases = [
            'invalid_base64' => 'not-valid-base64!!!',
            'non_image_data' => base64_encode('This is text, not an image'),
        ];

        foreach ($testCases as $testName => $input) {
            $validator = Validator::make(
                ['image' => $input],
                ['image' => new Base64Image(10240)]
            );
            
            // OBSERVATION: Validation failures produce error messages (not exceptions)
            // PRESERVATION: This behavior must continue after fix
            $this->assertTrue(
                $validator->fails(),
                "Preservation failed: {$testName} should fail validation"
            );
            
            $this->assertNotEmpty(
                $validator->errors()->first('image'),
                "Preservation failed: {$testName} should have error message"
            );
        }
    }
}
