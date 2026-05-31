<?php

namespace Tests\Feature\AI;

use Tests\TestCase;
use App\Models\User;
use App\Models\AIConsultation;
use App\Services\AI\VisionAIService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Mockery;

/**
 * Integration tests for AI consultation creation endpoint
 * 
 * Tests the full API flow including:
 * - Image dimension validation (bugfix for small images)
 * - Valid image processing
 * - Error message user-friendliness
 * - Prevention of Ollama crashes
 * 
 * Requirements: 2.1, 2.2, 2.3, 3.1, 3.5
 */
class ConsultationCreationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    /**
     * Test: Small Image Rejection (16x16 pixels)
     * 
     * Requirement 2.1: Images with width < 32 OR height < 32 must be rejected with 422
     * Requirement 2.2: Error message must be clear and include actual dimensions
     * Requirement 3.5: Validation failures must return 422 (not 500)
     * 
     * @test
     */
    public function it_rejects_small_images_with_422_error()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create a 16x16 pixel image (below minimum 32x32)
        $imageBase64 = $this->createTestImage(16, 16);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        // Assert 422 Unprocessable Entity (not 500)
        $response->assertStatus(422);

        // Assert error message is clear and includes dimensions
        $response->assertJsonValidationErrors('image');
        $errors = $response->json('errors.image');
        
        $this->assertIsArray($errors);
        $errorMessage = $errors[0];
        
        $this->assertStringContainsString('must be at least 32x32 pixels', $errorMessage);
        $this->assertStringContainsString('16x16', $errorMessage);
    }

    /**
     * Test: Valid Image Processing (400x400 pixels)
     * 
     * Requirement 2.3: Images >= 32x32 must be accepted and processed
     * Requirement 3.1: Valid images must continue to process successfully
     * 
     * @test
     */
    public function it_processes_valid_images_successfully()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Mock VisionAIService to avoid actual Ollama calls
        $mockVisionService = Mockery::mock(VisionAIService::class);
        $mockVisionService->shouldReceive('analyzeImage')
            ->once()
            ->andReturn([
                'diagnosis' => 'Test diagnosis',
                'service_type' => 'plumbing',
                'cost_min' => 100,
                'cost_max' => 200,
                'recommended_providers' => [],
                'processing_time_ms' => 1000,
            ]);
        
        $this->app->instance(VisionAIService::class, $mockVisionService);

        // Create a 400x400 pixel image (well above minimum)
        $imageBase64 = $this->createTestImage(400, 400);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        // Assert 200 OK with consultation data
        $response->assertStatus(201);
        $response->assertJsonStructure([
            'success',
            'message',
            'data' => [
                'consultation' => [
                    'id',
                    'image_url',
                    'markers',
                    'diagnosis',
                    'recommended_service_type',
                    'cost_min',
                    'cost_max',
                    'recommended_providers',
                    'processing_time_ms',
                    'created_at',
                ],
            ],
        ]);

        // Verify consultation was created in database
        $this->assertDatabaseHas('ai_consultations', [
            'customer_id' => $customer->id,
            'ai_diagnosis' => 'Test diagnosis',
            'recommended_service_type' => 'plumbing',
        ]);
    }

    /**
     * Test: Boundary Case (32x32 pixels - exact minimum)
     * 
     * Requirement 2.3: Images of exactly 32x32 must be accepted
     * 
     * @test
     */
    public function it_accepts_minimum_valid_dimensions()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Mock VisionAIService
        $mockVisionService = Mockery::mock(VisionAIService::class);
        $mockVisionService->shouldReceive('analyzeImage')
            ->once()
            ->andReturn([
                'diagnosis' => 'Test diagnosis',
                'service_type' => 'electrical',
                'cost_min' => 50,
                'cost_max' => 150,
                'recommended_providers' => [],
                'processing_time_ms' => 800,
            ]);
        
        $this->app->instance(VisionAIService::class, $mockVisionService);

        // Create a 32x32 pixel image (exact minimum)
        $imageBase64 = $this->createTestImage(32, 32);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        // Assert 200 OK - minimum valid size should be accepted
        $response->assertStatus(201);
        $response->assertJson([
            'success' => true,
        ]);
    }

    /**
     * Test: Non-Square Valid Image (32x100 pixels)
     * 
     * Requirement 2.3: Non-square images >= 32x32 must be accepted
     * 
     * @test
     */
    public function it_accepts_non_square_valid_images()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Mock VisionAIService
        $mockVisionService = Mockery::mock(VisionAIService::class);
        $mockVisionService->shouldReceive('analyzeImage')
            ->once()
            ->andReturn([
                'diagnosis' => 'Test diagnosis',
                'service_type' => 'carpentry',
                'cost_min' => 75,
                'cost_max' => 175,
                'recommended_providers' => [],
                'processing_time_ms' => 900,
            ]);
        
        $this->app->instance(VisionAIService::class, $mockVisionService);

        // Create a 32x100 pixel image (non-square, but both dimensions >= 32)
        $imageBase64 = $this->createTestImage(32, 100);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        // Assert 200 OK - non-square valid images should be accepted
        $response->assertStatus(201);
        $response->assertJson([
            'success' => true,
        ]);
    }

    /**
     * Test: Error Message User-Friendliness
     * 
     * Requirement 2.2: Error messages must be clear, actionable, and include actual dimensions
     * 
     * @test
     */
    public function it_provides_user_friendly_error_messages()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Test with 1x1 pixel image
        $imageBase64 = $this->createTestImage(1, 1);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        $response->assertStatus(422);
        
        $errors = $response->json('errors.image');
        $errorMessage = $errors[0];

        // Verify error message is user-friendly
        $this->assertStringContainsString('must be at least 32x32 pixels', $errorMessage);
        $this->assertStringContainsString('1x1', $errorMessage);
        
        // Verify no technical jargon or internal error details
        $this->assertStringNotContainsString('factor:32', $errorMessage);
        $this->assertStringNotContainsString('model runner', $errorMessage);
        $this->assertStringNotContainsString('Ollama', $errorMessage);
    }

    /**
     * Test: Prevention of Ollama Crashes
     * 
     * Requirement 2.1: Small images must be rejected during validation (before reaching Ollama)
     * Requirement 3.5: No 500 errors for small images
     * 
     * @test
     */
    public function it_prevents_ollama_crashes_by_early_validation()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create a 16x16 pixel image that would crash Ollama
        $imageBase64 = $this->createTestImage(16, 16);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        // Assert 422 (validation error), not 500 (server error)
        $response->assertStatus(422);
        
        // Verify no "model runner" or Ollama-related error messages
        $responseBody = $response->json();
        $this->assertStringNotContainsString('model runner has unexpectedly stopped', json_encode($responseBody));
        $this->assertStringNotContainsString('resource limitations', json_encode($responseBody));
        $this->assertStringNotContainsString('internal error', json_encode($responseBody));
    }

    /**
     * Test: Width Below Threshold (31x32 pixels)
     * 
     * Requirement 2.1: Images with width < 32 must be rejected
     * 
     * @test
     */
    public function it_rejects_images_with_width_below_threshold()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create a 31x32 pixel image (width below threshold)
        $imageBase64 = $this->createTestImage(31, 32);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('image');
        
        $errors = $response->json('errors.image');
        $errorMessage = $errors[0];
        
        $this->assertStringContainsString('31x32', $errorMessage);
    }

    /**
     * Test: Height Below Threshold (32x31 pixels)
     * 
     * Requirement 2.1: Images with height < 32 must be rejected
     * 
     * @test
     */
    public function it_rejects_images_with_height_below_threshold()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create a 32x31 pixel image (height below threshold)
        $imageBase64 = $this->createTestImage(32, 31);

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $imageBase64,
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('image');
        
        $errors = $response->json('errors.image');
        $errorMessage = $errors[0];
        
        $this->assertStringContainsString('32x31', $errorMessage);
    }

    /**
     * Create an authenticated customer user
     */
    protected function createAuthenticatedCustomer(): User
    {
        $customer = User::factory()->create([
            'role' => 'customer',
            'roles' => ['customer'], // Set roles array to avoid database error
        ]);
        $this->actingAs($customer, 'api');
        return $customer;
    }

    /**
     * Create a test image with specific dimensions
     * 
     * @param int $width Image width in pixels
     * @param int $height Image height in pixels
     * @return string Base64 encoded PNG image
     */
    protected function createTestImage(int $width, int $height): string
    {
        // Create image with specified dimensions
        $image = imagecreatetruecolor($width, $height);
        
        // Fill with a color (red)
        $red = imagecolorallocate($image, 255, 0, 0);
        imagefill($image, 0, 0, $red);
        
        // Output to buffer
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);

        return base64_encode($imageData);
    }
}
