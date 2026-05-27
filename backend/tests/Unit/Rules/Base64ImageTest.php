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
     * Test that image smaller than 100KB fails validation.
     */
    public function test_image_smaller_than_100kb_fails_validation(): void
    {
        // Create a very small image (less than 100KB)
        $image = imagecreatetruecolor(10, 10);
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
        $this->assertStringContainsString('at least 100KB', $validator->errors()->first('image'));
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
}
