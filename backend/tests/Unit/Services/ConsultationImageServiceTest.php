<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\ConsultationImageService;
use Illuminate\Support\Facades\Storage;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ConsultationImageServiceTest extends TestCase
{
    use RefreshDatabase;

    protected ConsultationImageService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        $this->service = new ConsultationImageService();
    }

    /** @test */
    public function it_stores_image_successfully()
    {
        // Create a small test image (1x1 pixel PNG)
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer-123';

        $result = $this->service->storeImage($imageData, $customerId);

        $this->assertArrayHasKey('path', $result);
        $this->assertArrayHasKey('size', $result);
        $this->assertArrayHasKey('compressed', $result);
        $this->assertFalse($result['compressed']); // Small image, no compression
        
        Storage::disk('public')->assertExists($result['path']);
    }

    /** @test */
    public function it_creates_customer_specific_directory()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'customer-456';

        $result = $this->service->storeImage($imageData, $customerId);

        $this->assertStringContainsString('customer-456', $result['path']);
        $this->assertStringStartsWith('consultations/customer-456/', $result['path']);
    }

    /** @test */
    public function it_generates_unique_filenames()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        $result1 = $this->service->storeImage($imageData, $customerId);
        $result2 = $this->service->storeImage($imageData, $customerId);

        $this->assertNotEquals($result1['path'], $result2['path']);
    }

    /** @test */
    public function it_validates_image_format()
    {
        $validImage = base64_encode(file_get_contents($this->createTestImage()));
        $invalidData = base64_encode('not an image');

        $this->assertTrue($this->service->validateImageFormat($validImage));
        $this->assertFalse($this->service->validateImageFormat($invalidData));
    }

    /** @test */
    public function it_rejects_invalid_base64()
    {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid base64 image data');

        $this->service->storeImage('not-valid-base64!!!', 'customer-123');
    }

    /** @test */
    public function it_deletes_image_successfully()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        $result = $this->service->storeImage($imageData, $customerId);
        $path = $result['path'];

        Storage::disk('public')->assertExists($path);

        $deleted = $this->service->deleteImage($path);

        $this->assertTrue($deleted);
        Storage::disk('public')->assertMissing($path);
    }

    /** @test */
    public function it_handles_deleting_non_existent_image()
    {
        $result = $this->service->deleteImage('non-existent-path.jpg');
        
        $this->assertTrue($result); // Should return true for already deleted
    }

    /** @test */
    public function it_generates_image_url()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        $result = $this->service->storeImage($imageData, $customerId);
        $url = $this->service->getImageUrl($result['path']);

        $this->assertStringContainsString($result['path'], $url);
        $this->assertStringContainsString('storage', $url);
    }

    /** @test */
    public function it_checks_if_image_exists()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        $result = $this->service->storeImage($imageData, $customerId);

        $this->assertTrue($this->service->imageExists($result['path']));
        $this->assertFalse($this->service->imageExists('non-existent.jpg'));
    }

    /** @test */
    public function it_gets_image_size()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        $result = $this->service->storeImage($imageData, $customerId);
        $size = $this->service->getImageSize($result['path']);

        $this->assertGreaterThan(0, $size);
        $this->assertEquals($result['size'], $size);
    }

    /** @test */
    public function it_returns_zero_size_for_non_existent_image()
    {
        $size = $this->service->getImageSize('non-existent.jpg');
        $this->assertEquals(0, $size);
    }

    /** @test */
    public function it_gets_image_dimensions()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        $result = $this->service->storeImage($imageData, $customerId);
        $dimensions = $this->service->getImageDimensions($result['path']);

        $this->assertIsArray($dimensions);
        $this->assertArrayHasKey('width', $dimensions);
        $this->assertArrayHasKey('height', $dimensions);
        $this->assertGreaterThan(0, $dimensions['width']);
        $this->assertGreaterThan(0, $dimensions['height']);
    }

    /** @test */
    public function it_returns_null_dimensions_for_non_existent_image()
    {
        $dimensions = $this->service->getImageDimensions('non-existent.jpg');
        $this->assertNull($dimensions);
    }

    /** @test */
    public function it_cleans_up_empty_customer_directory()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        // Store and then delete image
        $result = $this->service->storeImage($imageData, $customerId);
        $this->service->deleteImage($result['path']);

        // Cleanup directory
        $cleaned = $this->service->cleanupCustomerDirectory($customerId);

        $this->assertTrue($cleaned);
        Storage::disk('public')->assertMissing('consultations/customer-' . $customerId);
    }

    /** @test */
    public function it_does_not_delete_non_empty_customer_directory()
    {
        $imageData = base64_encode(file_get_contents($this->createTestImage()));
        $customerId = 'test-customer';

        // Store two images
        $result1 = $this->service->storeImage($imageData, $customerId);
        $result2 = $this->service->storeImage($imageData, $customerId);

        // Delete only one
        $this->service->deleteImage($result1['path']);

        // Try to cleanup directory
        $cleaned = $this->service->cleanupCustomerDirectory($customerId);

        $this->assertTrue($cleaned);
        // Directory should still exist because result2 is still there
        Storage::disk('public')->assertExists('consultations/customer-' . $customerId);
        Storage::disk('public')->assertExists($result2['path']);
    }

    /**
     * Create a minimal test image (1x1 pixel PNG)
     * 
     * @return string Path to temporary image file
     */
    protected function createTestImage(): string
    {
        $tempFile = tempnam(sys_get_temp_dir(), 'test_image_');
        
        // Create a 1x1 pixel PNG image
        $image = imagecreatetruecolor(1, 1);
        imagecolorallocate($image, 255, 0, 0); // Red pixel
        imagepng($image, $tempFile);
        imagedestroy($image);

        return $tempFile;
    }
}
