<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class Base64Image implements ValidationRule
{
    private int $maxSizeKb;

    /**
     * Create a new rule instance.
     *
     * @param int $maxSizeKb Maximum allowed image size in kilobytes
     */
    public function __construct(int $maxSizeKb = 10240)
    {
        $this->maxSizeKb = $maxSizeKb;
    }

    /**
     * Run the validation rule.
     *
     * @param string $attribute
     * @param mixed $value
     * @param Closure $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        // Check if value is a string
        if (!is_string($value)) {
            $fail('The :attribute must be a valid base64 encoded image string.');
            return;
        }

        // Check if empty string
        if (empty($value)) {
            $fail('The :attribute must be a valid base64 encoded image string.');
            return;
        }

        // Remove data URI scheme if present (e.g., "data:image/jpeg;base64,")
        $base64String = $value;
        if (preg_match('/^data:image\/(\w+);base64,/', $value, $matches)) {
            $base64String = substr($value, strpos($value, ',') + 1);
        }

        // Validate base64 format
        if (!preg_match('/^[a-zA-Z0-9\/\r\n+]*={0,2}$/', $base64String)) {
            $fail('The :attribute must be a valid base64 encoded string.');
            return;
        }

        // Decode base64 string
        $decodedImage = base64_decode($base64String, true);
        
        if ($decodedImage === false || empty($decodedImage)) {
            $fail('The :attribute must be a valid base64 encoded image.');
            return;
        }

        // Check decoded size
        $sizeKb = strlen($decodedImage) / 1024;
        
        // No minimum size requirement - accept any size
        
        if ($sizeKb > $this->maxSizeKb) {
            $fail("The :attribute must not exceed {$this->maxSizeKb}KB in size.");
            return;
        }

        // Validate image format using getimagesizefromstring
        $imageInfo = @getimagesizefromstring($decodedImage);
        
        if ($imageInfo === false) {
            $fail('The :attribute must be a valid image file.');
            return;
        }

        // Extract dimensions (already available from getimagesizefromstring)
        $width = $imageInfo[0];
        $height = $imageInfo[1];

        // Check if it's a supported image format (JPEG, PNG, HEIC/HEIF)
        $allowedMimeTypes = [
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/heic',
            'image/heif',
        ];

        if (!in_array($imageInfo['mime'], $allowedMimeTypes)) {
            $fail('The :attribute must be a JPEG, PNG, or HEIC image.');
            return;
        }

        // Validate minimum dimensions (required by qwen3vl model: factor:32)
        if ($width < 32 || $height < 32) {
            $fail("The :attribute must be at least 32x32 pixels. Your image is {$width}x{$height} pixels.");
            return;
        }
    }
}
