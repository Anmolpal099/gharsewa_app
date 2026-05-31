<?php

namespace Tests\Unit\Rules;

use App\Rules\Base64Image;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

/**
 * Bug Condition Exploration Test for AI Image Dimension Validation
 * 
 * CRITICAL: This test is designed to run on UNFIXED code and MUST FAIL.
 * The test failure proves the bug exists (small images pass validation when they shouldn't).
 * 
 * Expected behavior on UNFIXED code:
 * - Small images (< 32x32 pixels) PASS validation (BUG)
 * - These images would crash Ollama with "height:X or width:Y must be larger than factor:32"
 * 
 * Expected behavior on FIXED code:
 * - Small images (< 32x32 pixels) FAIL validation with clear error message
 * - Error message includes actual dimensions for debugging
 */
class Base64ImageDimensionTest extends TestCase
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
     * Property 1: Bug Condition - Small Image Rejection
     * 
     * **Validates: Requirements 1.1, 1.2, 2.1, 2.2**
     * 
     * CRITICAL: This test MUST FAIL on unfixed code - failure confirms the bug exists.
     * DO NOT attempt to fix the test or the code when it fails.
     * 
     * Test Strategy: Generate images with dimensions in range [1, 31] x [1, 31] pixels
     * and verify they are REJECTED by the validation rule (expected behavior).
     * 
     * On UNFIXED code: These assertions will FAIL because small images pass validation.
     * On FIXED code: These assertions will PASS because small images are rejected.
     */
    public function test_bug_condition_small_images_must_be_rejected(): void
    {
        // Test Case 1: 1x1 pixel image (smallest possible)
        $image1x1 = $this->createTestImage(1, 1);
        $validator1 = Validator::make(
            ['image' => $image1x1],
            ['image' => new Base64Image(10240)]
        );
        
        // EXPECTED: Should FAIL validation (image too small)
        // UNFIXED CODE: Will PASS validation (BUG - this assertion will fail)
        $this->assertTrue(
            $validator1->fails(),
            'Bug detected: 1x1 pixel image passed validation but should be rejected'
        );
        
        if ($validator1->fails()) {
            $error = $validator1->errors()->first('image');
            $this->assertStringContainsString('must be at least 32x32 pixels', $error);
            $this->assertStringContainsString('1x1', $error);
        }

        // Test Case 2: 16x16 pixel image (common small icon size)
        $image16x16 = $this->createTestImage(16, 16);
        $validator2 = Validator::make(
            ['image' => $image16x16],
            ['image' => new Base64Image(10240)]
        );
        
        // EXPECTED: Should FAIL validation (image too small)
        // UNFIXED CODE: Will PASS validation (BUG - this assertion will fail)
        $this->assertTrue(
            $validator2->fails(),
            'Bug detected: 16x16 pixel image passed validation but should be rejected'
        );
        
        if ($validator2->fails()) {
            $error = $validator2->errors()->first('image');
            $this->assertStringContainsString('must be at least 32x32 pixels', $error);
            $this->assertStringContainsString('16x16', $error);
        }

        // Test Case 3: 31x32 pixel image (width below threshold)
        $image31x32 = $this->createTestImage(31, 32);
        $validator3 = Validator::make(
            ['image' => $image31x32],
            ['image' => new Base64Image(10240)]
        );
        
        // EXPECTED: Should FAIL validation (width < 32)
        // UNFIXED CODE: Will PASS validation (BUG - this assertion will fail)
        $this->assertTrue(
            $validator3->fails(),
            'Bug detected: 31x32 pixel image passed validation but should be rejected (width < 32)'
        );
        
        if ($validator3->fails()) {
            $error = $validator3->errors()->first('image');
            $this->assertStringContainsString('must be at least 32x32 pixels', $error);
            $this->assertStringContainsString('31x32', $error);
        }

        // Test Case 4: 32x31 pixel image (height below threshold)
        $image32x31 = $this->createTestImage(32, 31);
        $validator4 = Validator::make(
            ['image' => $image32x31],
            ['image' => new Base64Image(10240)]
        );
        
        // EXPECTED: Should FAIL validation (height < 32)
        // UNFIXED CODE: Will PASS validation (BUG - this assertion will fail)
        $this->assertTrue(
            $validator4->fails(),
            'Bug detected: 32x31 pixel image passed validation but should be rejected (height < 32)'
        );
        
        if ($validator4->fails()) {
            $error = $validator4->errors()->first('image');
            $this->assertStringContainsString('must be at least 32x32 pixels', $error);
            $this->assertStringContainsString('32x31', $error);
        }

        // Test Case 5: 31x31 pixel image (both dimensions below threshold)
        $image31x31 = $this->createTestImage(31, 31);
        $validator5 = Validator::make(
            ['image' => $image31x31],
            ['image' => new Base64Image(10240)]
        );
        
        // EXPECTED: Should FAIL validation (both dimensions < 32)
        // UNFIXED CODE: Will PASS validation (BUG - this assertion will fail)
        $this->assertTrue(
            $validator5->fails(),
            'Bug detected: 31x31 pixel image passed validation but should be rejected (both dimensions < 32)'
        );
        
        if ($validator5->fails()) {
            $error = $validator5->errors()->first('image');
            $this->assertStringContainsString('must be at least 32x32 pixels', $error);
            $this->assertStringContainsString('31x31', $error);
        }
    }

    /**
     * Boundary Test: 32x32 pixel image should PASS validation (minimum valid size)
     * 
     * This test verifies the boundary condition - exactly 32x32 pixels should be accepted.
     * This should PASS on both unfixed and fixed code (no bug at this boundary).
     */
    public function test_32x32_pixel_image_passes_validation(): void
    {
        $image32x32 = $this->createTestImage(32, 32);
        $validator = Validator::make(
            ['image' => $image32x32],
            ['image' => new Base64Image(10240)]
        );
        
        // This should PASS on both unfixed and fixed code
        $this->assertFalse(
            $validator->fails(),
            '32x32 pixel image should pass validation (minimum valid size)'
        );
    }

    /**
     * Boundary Test: 33x33 pixel image should PASS validation (above minimum)
     * 
     * This test verifies images above the minimum threshold are accepted.
     * This should PASS on both unfixed and fixed code (no bug for valid sizes).
     */
    public function test_33x33_pixel_image_passes_validation(): void
    {
        $image33x33 = $this->createTestImage(33, 33);
        $validator = Validator::make(
            ['image' => $image33x33],
            ['image' => new Base64Image(10240)]
        );
        
        // This should PASS on both unfixed and fixed code
        $this->assertFalse(
            $validator->fails(),
            '33x33 pixel image should pass validation (above minimum)'
        );
    }

    /**
     * Preservation Test: Large valid images should continue to pass validation
     * 
     * **Validates: Requirements 3.1**
     * 
     * This test ensures the fix doesn't break existing functionality for valid images.
     */
    public function test_large_valid_image_passes_validation(): void
    {
        $image100x100 = $this->createTestImage(100, 100);
        $validator = Validator::make(
            ['image' => $image100x100],
            ['image' => new Base64Image(10240)]
        );
        
        // This should PASS on both unfixed and fixed code
        $this->assertFalse(
            $validator->fails(),
            '100x100 pixel image should pass validation'
        );
    }
}
