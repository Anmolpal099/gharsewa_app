<?php

namespace Tests\Unit\Rules;

use App\Rules\Base64Image;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class Base64ImageTest extends TestCase
{
    /**
     * Create a valid base64 encoded image for testing.
     */
    private function createValidBase64Image(int $sizeKb = 500): string
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
     * Test that valid base64 image passes validation.
     */
    public function test_valid_base64_image_passes_validation(): void
    {
        $base64Image = $this->createValidBase64Image(500);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that base64 image with data URI scheme passes validation.
     */
    public function test_base64_image_with_data_uri_passes_validation(): void
    {
        $base64Image = $this->createValidBase64Image(500);
        $dataUri = 'data:image/png;base64,' . $base64Image;
        
        $validator = Validator::make(
            ['image' => $dataUri],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that non-string value fails validation.
     */
    public function test_non_string_value_fails_validation(): void
    {
        $validator = Validator::make(
            ['image' => 12345],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('valid base64 encoded image string', $validator->errors()->first('image'));
    }

    /**
     * Test that invalid base64 string fails validation.
     */
    public function test_invalid_base64_string_fails_validation(): void
    {
        $validator = Validator::make(
            ['image' => 'not-a-valid-base64-string!!!'],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('valid base64 encoded', $validator->errors()->first('image'));
    }

    /**
     * Test that 1x1 pixel image fails validation.
     */
    public function test_1x1_pixel_image_fails_validation(): void
    {
        $image = imagecreatetruecolor(1, 1);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 32x32 pixels', $validator->errors()->first('image'));
        $this->assertStringContainsString('1x1 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that 16x16 pixel image fails validation.
     */
    public function test_16x16_pixel_image_fails_validation(): void
    {
        $image = imagecreatetruecolor(16, 16);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 32x32 pixels', $validator->errors()->first('image'));
        $this->assertStringContainsString('16x16 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that 31x32 pixel image fails validation (width below threshold).
     */
    public function test_31x32_pixel_image_fails_validation(): void
    {
        $image = imagecreatetruecolor(31, 32);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 32x32 pixels', $validator->errors()->first('image'));
        $this->assertStringContainsString('31x32 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that 32x31 pixel image fails validation (height below threshold).
     */
    public function test_32x31_pixel_image_fails_validation(): void
    {
        $image = imagecreatetruecolor(32, 31);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 32x32 pixels', $validator->errors()->first('image'));
        $this->assertStringContainsString('32x31 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that 31x31 pixel image fails validation (both dimensions below threshold).
     */
    public function test_31x31_pixel_image_fails_validation(): void
    {
        $image = imagecreatetruecolor(31, 31);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 32x32 pixels', $validator->errors()->first('image'));
        $this->assertStringContainsString('31x31 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that 32x32 pixel image passes validation (exact minimum).
     */
    public function test_32x32_pixel_image_passes_validation(): void
    {
        $image = imagecreatetruecolor(32, 32);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that 33x33 pixel image passes validation (above minimum).
     */
    public function test_33x33_pixel_image_passes_validation(): void
    {
        $image = imagecreatetruecolor(33, 33);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that 100x100 pixel image passes validation (well above minimum).
     */
    public function test_100x100_pixel_image_passes_validation(): void
    {
        $image = imagecreatetruecolor(100, 100);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that image larger than max size fails validation.
     */
    public function test_image_larger_than_max_size_fails_validation(): void
    {
        // Create a moderately sized image and test with a small limit
        $base64Image = $this->createValidBase64Image(300); // 300KB image
        
        // Test with 200KB limit - should fail
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(200)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('must not exceed 200KB', $validator->errors()->first('image'));
    }

    /**
     * Test that non-image data fails validation.
     */
    public function test_non_image_data_fails_validation(): void
    {
        $textData = str_repeat('This is not an image. ', 10000); // Make it large enough
        $base64Text = base64_encode($textData);
        
        $validator = Validator::make(
            ['image' => $base64Text],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('valid image file', $validator->errors()->first('image'));
    }

    /**
     * Test that PNG image passes validation.
     */
    public function test_png_image_passes_validation(): void
    {
        $base64Image = $this->createValidBase64Image(500);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test custom max size parameter.
     */
    public function test_custom_max_size_parameter_works(): void
    {
        // Create a 200KB image
        $base64Image = $this->createValidBase64Image(200);
        
        // Should pass with 1MB limit
        $validator1 = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(1024)]
        );
        $this->assertFalse($validator1->fails());
        
        // Should fail with 150KB limit
        $validator2 = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(150)]
        );
        $this->assertTrue($validator2->fails());
    }

    /**
     * Test that empty string fails validation with required rule.
     */
    public function test_empty_string_fails_validation(): void
    {
        $validator = Validator::make(
            ['image' => ''],
            ['image' => ['required', new Base64Image(10240)]]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('required', strtolower($validator->errors()->first('image')));
    }

    /**
     * Test that null value fails validation.
     */
    public function test_null_value_fails_validation(): void
    {
        $validator = Validator::make(
            ['image' => null],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
    }

    /**
     * Test that invalid format fails before dimension check.
     */
    public function test_invalid_format_fails_before_dimension_check(): void
    {
        // Create non-image data that would be small if it were an image
        $textData = 'This is not an image';
        $base64Text = base64_encode($textData);
        
        $validator = Validator::make(
            ['image' => $base64Text],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        // Should get format error, not dimension error
        $this->assertStringContainsString('valid image file', $validator->errors()->first('image'));
        $this->assertStringNotContainsString('32x32 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that invalid base64 fails before dimension check.
     */
    public function test_invalid_base64_fails_before_dimension_check(): void
    {
        $validator = Validator::make(
            ['image' => 'not-valid-base64!!!'],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        // Should get base64 error, not dimension error
        $this->assertStringContainsString('valid base64', $validator->errors()->first('image'));
        $this->assertStringNotContainsString('32x32 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that oversized image fails with size error, not dimension error.
     */
    public function test_oversized_image_fails_with_size_error(): void
    {
        // Create a large image (dimensions are fine, but size exceeds limit)
        $base64Image = $this->createValidBase64Image(300); // 300KB image
        
        // Test with 200KB limit - should fail with size error
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(200)]
        );
        
        $this->assertTrue($validator->fails());
        // Should get size error, not dimension error
        $this->assertStringContainsString('must not exceed 200KB', $validator->errors()->first('image'));
        $this->assertStringNotContainsString('32x32 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that small PNG image fails with dimension error.
     */
    public function test_small_png_image_fails_with_dimension_error(): void
    {
        $image = imagecreatetruecolor(20, 20);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertTrue($validator->fails());
        $this->assertStringContainsString('at least 32x32 pixels', $validator->errors()->first('image'));
        $this->assertStringContainsString('20x20 pixels', $validator->errors()->first('image'));
    }

    /**
     * Test that non-square valid image passes validation (32x100).
     */
    public function test_non_square_valid_image_32x100_passes_validation(): void
    {
        $image = imagecreatetruecolor(32, 100);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }

    /**
     * Test that non-square valid image passes validation (100x32).
     */
    public function test_non_square_valid_image_100x32_passes_validation(): void
    {
        $image = imagecreatetruecolor(100, 32);
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);
        
        $base64Image = base64_encode($imageData);
        
        $validator = Validator::make(
            ['image' => $base64Image],
            ['image' => new Base64Image(10240)]
        );
        
        $this->assertFalse($validator->fails());
    }
}
