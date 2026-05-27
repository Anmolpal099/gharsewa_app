<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Intervention\Image\Facades\Image;
use Exception;

/**
 * Service for handling AI consultation image storage and management
 * 
 * Responsibilities:
 * - Store images securely in customer-specific directories
 * - Compress images larger than 5MB
 * - Validate image formats (JPEG, PNG, HEIC)
 * - Generate unique filenames using UUID
 * - Delete images when consultations are removed
 * - Generate public URLs for image access
 */
class ConsultationImageService
{
    /**
     * Maximum file size before compression (5MB in bytes)
     */
    const MAX_SIZE_BEFORE_COMPRESSION = 5 * 1024 * 1024;

    /**
     * Compression quality (0-100)
     */
    const COMPRESSION_QUALITY = 85;

    /**
     * Maximum image dimensions
     */
    const MAX_WIDTH = 1920;
    const MAX_HEIGHT = 1920;

    /**
     * Allowed image formats
     */
    const ALLOWED_FORMATS = ['jpg', 'jpeg', 'png', 'heic'];

    /**
     * Storage disk to use
     */
    const STORAGE_DISK = 'public';

    /**
     * Base directory for consultation images
     */
    const BASE_DIRECTORY = 'consultations';

    /**
     * Store an image with automatic compression if needed
     * 
     * @param string $imageData Base64 encoded image data
     * @param string $customerId Customer ID for directory organization
     * @return array ['path' => string, 'size' => int, 'compressed' => bool]
     * @throws Exception
     */
    public function storeImage(string $imageData, string $customerId): array
    {
        try {
            // Decode base64 image
            $decodedImage = base64_decode($imageData);
            
            if ($decodedImage === false) {
                throw new Exception('Invalid base64 image data');
            }

            // Get original size
            $originalSize = strlen($decodedImage);

            // Validate image format
            $imageInfo = getimagesizefromstring($decodedImage);
            if ($imageInfo === false) {
                throw new Exception('Invalid image data');
            }

            $mimeType = $imageInfo['mime'];
            $extension = $this->getExtensionFromMimeType($mimeType);

            if (!in_array($extension, self::ALLOWED_FORMATS)) {
                throw new Exception("Unsupported image format: {$extension}");
            }

            // Generate unique filename
            $filename = $this->generateUniqueFilename($extension);

            // Create customer-specific directory path
            $directory = $this->getCustomerDirectory($customerId);

            // Full path for storage
            $path = "{$directory}/{$filename}";

            // Check if compression is needed
            $compressed = false;
            if ($originalSize > self::MAX_SIZE_BEFORE_COMPRESSION) {
                // Compress image
                $processedImage = $this->compressImage($decodedImage);
                $compressed = true;
            } else {
                $processedImage = $decodedImage;
            }

            // Store image
            Storage::disk(self::STORAGE_DISK)->put($path, $processedImage);

            // Get final size
            $finalSize = Storage::disk(self::STORAGE_DISK)->size($path);

            return [
                'path' => $path,
                'size' => $finalSize,
                'compressed' => $compressed,
                'original_size' => $originalSize,
            ];
        } catch (Exception $e) {
            throw new Exception("Failed to store image: {$e->getMessage()}");
        }
    }

    /**
     * Compress an image to reduce file size
     * 
     * @param string $imageData Raw image data
     * @return string Compressed image data
     * @throws Exception
     */
    protected function compressImage(string $imageData): string
    {
        try {
            // Create image from string
            $image = Image::make($imageData);

            // Resize if dimensions exceed maximum
            if ($image->width() > self::MAX_WIDTH || $image->height() > self::MAX_HEIGHT) {
                $image->resize(self::MAX_WIDTH, self::MAX_HEIGHT, function ($constraint) {
                    $constraint->aspectRatio();
                    $constraint->upsize();
                });
            }

            // Encode with compression
            $compressed = $image->encode('jpg', self::COMPRESSION_QUALITY);

            return (string) $compressed;
        } catch (Exception $e) {
            throw new Exception("Failed to compress image: {$e->getMessage()}");
        }
    }

    /**
     * Delete an image from storage
     * 
     * @param string $path Image path
     * @return bool Success status
     */
    public function deleteImage(string $path): bool
    {
        try {
            if (Storage::disk(self::STORAGE_DISK)->exists($path)) {
                return Storage::disk(self::STORAGE_DISK)->delete($path);
            }
            return true; // Already deleted
        } catch (Exception $e) {
            // Log error but don't throw - deletion failures shouldn't block operations
            logger()->error("Failed to delete image: {$path}", [
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Get public URL for an image
     * 
     * @param string $path Image path
     * @return string Public URL
     */
    public function getImageUrl(string $path): string
    {
        return Storage::disk(self::STORAGE_DISK)->url($path);
    }

    /**
     * Check if an image exists
     * 
     * @param string $path Image path
     * @return bool
     */
    public function imageExists(string $path): bool
    {
        return Storage::disk(self::STORAGE_DISK)->exists($path);
    }

    /**
     * Get image size in bytes
     * 
     * @param string $path Image path
     * @return int Size in bytes
     */
    public function getImageSize(string $path): int
    {
        if (!$this->imageExists($path)) {
            return 0;
        }

        return Storage::disk(self::STORAGE_DISK)->size($path);
    }

    /**
     * Generate a unique filename using UUID
     * 
     * @param string $extension File extension
     * @return string Unique filename
     */
    protected function generateUniqueFilename(string $extension): string
    {
        return Str::uuid()->toString() . '.' . $extension;
    }

    /**
     * Get customer-specific directory path
     * 
     * @param string $customerId Customer ID
     * @return string Directory path
     */
    protected function getCustomerDirectory(string $customerId): string
    {
        return self::BASE_DIRECTORY . '/customer-' . $customerId;
    }

    /**
     * Get file extension from MIME type
     * 
     * @param string $mimeType MIME type
     * @return string File extension
     */
    protected function getExtensionFromMimeType(string $mimeType): string
    {
        $mimeMap = [
            'image/jpeg' => 'jpg',
            'image/jpg' => 'jpg',
            'image/png' => 'png',
            'image/heic' => 'heic',
            'image/heif' => 'heic',
        ];

        return $mimeMap[$mimeType] ?? 'jpg';
    }

    /**
     * Validate image format
     * 
     * @param string $imageData Base64 or raw image data
     * @return bool
     */
    public function validateImageFormat(string $imageData): bool
    {
        try {
            // Try to decode if base64
            $decoded = base64_decode($imageData, true);
            if ($decoded !== false) {
                $imageData = $decoded;
            }

            $imageInfo = getimagesizefromstring($imageData);
            if ($imageInfo === false) {
                return false;
            }

            $mimeType = $imageInfo['mime'];
            $extension = $this->getExtensionFromMimeType($mimeType);

            return in_array($extension, self::ALLOWED_FORMATS);
        } catch (Exception $e) {
            return false;
        }
    }

    /**
     * Get image dimensions
     * 
     * @param string $path Image path
     * @return array|null ['width' => int, 'height' => int] or null if not found
     */
    public function getImageDimensions(string $path): ?array
    {
        try {
            if (!$this->imageExists($path)) {
                return null;
            }

            $fullPath = Storage::disk(self::STORAGE_DISK)->path($path);
            $imageInfo = getimagesize($fullPath);

            if ($imageInfo === false) {
                return null;
            }

            return [
                'width' => $imageInfo[0],
                'height' => $imageInfo[1],
            ];
        } catch (Exception $e) {
            return null;
        }
    }

    /**
     * Clean up old customer directory if empty
     * 
     * @param string $customerId Customer ID
     * @return bool Success status
     */
    public function cleanupCustomerDirectory(string $customerId): bool
    {
        try {
            $directory = $this->getCustomerDirectory($customerId);
            
            // Check if directory exists
            if (!Storage::disk(self::STORAGE_DISK)->exists($directory)) {
                return true;
            }

            // Get all files in directory
            $files = Storage::disk(self::STORAGE_DISK)->files($directory);

            // If directory is empty, delete it
            if (empty($files)) {
                return Storage::disk(self::STORAGE_DISK)->deleteDirectory($directory);
            }

            return true;
        } catch (Exception $e) {
            logger()->error("Failed to cleanup customer directory: {$customerId}", [
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
