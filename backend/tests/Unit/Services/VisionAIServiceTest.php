<?php

namespace Tests\Unit\Services;

use App\Services\AI\VisionAIService;
use App\Models\User;
use App\Models\Service;
use App\Models\Review;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class VisionAIServiceTest extends TestCase
{
    use RefreshDatabase;

    private VisionAIService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new VisionAIService();
    }

    /**
     * Test analyzeImage method with successful response
     */
    public function test_analyze_image_success(): void
    {
        // Create test image
        Storage::fake('local');
        $imagePath = storage_path('app/test_image.jpg');
        file_put_contents($imagePath, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

        // Create test providers
        $provider1 = User::factory()->create([
            'name' => 'Expert Plumber',
            'is_active' => true,
            'roles' => ['serviceProvider'],
        ]);

        $service1 = Service::factory()->create([
            'provider_id' => $provider1->id,
            'category' => 'Plumbing Repair',
            'status' => 'active',
        ]);

        Review::factory()->create([
            'provider_id' => $provider1->id,
            'rating' => 5,
        ]);

        // Mock Ollama API response
        Http::fake([
            '*/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => json_encode([
                    'diagnosis' => 'Water leak detected in pipe joint',
                    'service_type' => 'Plumbing Repair',
                    'cost_estimate' => [
                        'min' => 2000,
                        'max' => 5000,
                    ],
                    'confidence' => 0.85,
                ]),
                'total_duration' => 27000000000,
            ], 200),
        ]);

        // Test markers
        $markers = [
            ['x' => 0.45, 'y' => 0.32, 'description' => 'Water leaking from pipe joint'],
            ['x' => 0.67, 'y' => 0.58, 'description' => 'Rust visible on metal surface'],
        ];

        // Execute
        $result = $this->service->analyzeImage($imagePath, $markers);

        // Assert
        $this->assertIsArray($result);
        $this->assertArrayHasKey('diagnosis', $result);
        $this->assertArrayHasKey('service_type', $result);
        $this->assertArrayHasKey('cost_min', $result);
        $this->assertArrayHasKey('cost_max', $result);
        $this->assertArrayHasKey('confidence', $result);
        $this->assertArrayHasKey('recommended_providers', $result);
        $this->assertArrayHasKey('processing_time_ms', $result);

        $this->assertEquals('Water leak detected in pipe joint', $result['diagnosis']);
        $this->assertEquals('Plumbing Repair', $result['service_type']);
        $this->assertEquals(2000, $result['cost_min']);
        $this->assertEquals(5000, $result['cost_max']);
        $this->assertEquals(0.85, $result['confidence']);
        $this->assertIsArray($result['recommended_providers']);

        // Cleanup
        unlink($imagePath);
    }

    /**
     * Test buildVisionPrompt method
     */
    public function test_build_vision_prompt(): void
    {
        $markers = [
            ['x' => 0.45, 'y' => 0.32, 'description' => 'Water leak'],
            ['x' => 0.67, 'y' => 0.58, 'description' => 'Rust damage'],
        ];

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('buildVisionPrompt');
        $method->setAccessible(true);

        $prompt = $method->invoke($this->service, $markers);

        $this->assertStringContainsString('Marker 1 at position (45%, 32%): Water leak', $prompt);
        $this->assertStringContainsString('Marker 2 at position (67%, 58%): Rust damage', $prompt);
        $this->assertStringContainsString('expert home service diagnostic assistant', $prompt);
        $this->assertStringContainsString('JSON format', $prompt);
    }

    /**
     * Test parseVisionResponse with valid JSON
     */
    public function test_parse_vision_response_valid_json(): void
    {
        $rawResponse = json_encode([
            'diagnosis' => 'Electrical wiring issue',
            'service_type' => 'Electrical Work',
            'cost_estimate' => [
                'min' => 3000,
                'max' => 8000,
            ],
            'confidence' => 0.9,
        ]);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('parseVisionResponse');
        $method->setAccessible(true);

        $result = $method->invoke($this->service, $rawResponse);

        $this->assertEquals('Electrical wiring issue', $result['diagnosis']);
        $this->assertEquals('Electrical Work', $result['service_type']);
        $this->assertEquals(3000, $result['cost_min']);
        $this->assertEquals(8000, $result['cost_max']);
        $this->assertEquals(0.9, $result['confidence']);
    }

    /**
     * Test parseVisionResponse with markdown code blocks
     */
    public function test_parse_vision_response_with_markdown(): void
    {
        $rawResponse = "```json\n" . json_encode([
            'diagnosis' => 'Paint peeling',
            'service_type' => 'Painting',
            'cost_estimate' => [
                'min' => 1500,
                'max' => 4000,
            ],
            'confidence' => 0.75,
        ]) . "\n```";

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('parseVisionResponse');
        $method->setAccessible(true);

        $result = $method->invoke($this->service, $rawResponse);

        $this->assertEquals('Paint peeling', $result['diagnosis']);
        $this->assertEquals('Painting', $result['service_type']);
    }

    /**
     * Test parseVisionResponse with invalid service type
     */
    public function test_parse_vision_response_invalid_service_type(): void
    {
        $rawResponse = json_encode([
            'diagnosis' => 'Some issue',
            'service_type' => 'Invalid Service Type',
            'cost_estimate' => [
                'min' => 1000,
                'max' => 3000,
            ],
            'confidence' => 0.5,
        ]);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('parseVisionResponse');
        $method->setAccessible(true);

        $result = $method->invoke($this->service, $rawResponse);

        // Should fallback to General Maintenance
        $this->assertEquals('General Maintenance', $result['service_type']);
    }

    /**
     * Test parseVisionResponse with invalid cost estimates
     */
    public function test_parse_vision_response_invalid_costs(): void
    {
        $rawResponse = json_encode([
            'diagnosis' => 'Some issue',
            'service_type' => 'Plumbing Repair',
            'cost_estimate' => [
                'min' => -100,
                'max' => 100,
            ],
            'confidence' => 0.5,
        ]);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('parseVisionResponse');
        $method->setAccessible(true);

        $result = $method->invoke($this->service, $rawResponse);

        // Should use fallback values
        $this->assertEquals(1000, $result['cost_min']);
        $this->assertEquals(5000, $result['cost_max']);
    }

    /**
     * Test parseVisionResponse with malformed JSON
     */
    public function test_parse_vision_response_malformed_json(): void
    {
        $rawResponse = 'This is not valid JSON';

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('parseVisionResponse');
        $method->setAccessible(true);

        $result = $method->invoke($this->service, $rawResponse);

        // Should return fallback values
        $this->assertStringContainsString('Unable to determine', $result['diagnosis']);
        $this->assertEquals('General Maintenance', $result['service_type']);
        $this->assertEquals(1000, $result['cost_min']);
        $this->assertEquals(5000, $result['cost_max']);
        $this->assertEquals(0.3, $result['confidence']);
    }

    /**
     * Test findMatchingProviders method
     */
    public function test_find_matching_providers(): void
    {
        // Create providers with different ratings
        $provider1 = User::factory()->create([
            'name' => 'Top Plumber',
            'is_active' => true,
            'roles' => ['serviceProvider'],
        ]);

        $provider2 = User::factory()->create([
            'name' => 'Good Plumber',
            'is_active' => true,
            'roles' => ['serviceProvider'],
        ]);

        $provider3 = User::factory()->create([
            'name' => 'Average Plumber',
            'is_active' => true,
            'roles' => ['serviceProvider'],
        ]);

        // Create services
        Service::factory()->create([
            'provider_id' => $provider1->id,
            'category' => 'Plumbing Repair',
            'status' => 'active',
            'name' => 'Expert Plumbing',
        ]);

        Service::factory()->create([
            'provider_id' => $provider2->id,
            'category' => 'Plumbing Repair',
            'status' => 'active',
            'name' => 'Quality Plumbing',
        ]);

        Service::factory()->create([
            'provider_id' => $provider3->id,
            'category' => 'Plumbing Repair',
            'status' => 'active',
            'name' => 'Basic Plumbing',
        ]);

        // Create reviews
        Review::factory()->create(['provider_id' => $provider1->id, 'rating' => 5]);
        Review::factory()->create(['provider_id' => $provider1->id, 'rating' => 5]);
        Review::factory()->create(['provider_id' => $provider2->id, 'rating' => 4]);
        Review::factory()->create(['provider_id' => $provider3->id, 'rating' => 3]);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('findMatchingProviders');
        $method->setAccessible(true);

        $providers = $method->invoke($this->service, 'Plumbing Repair', 3);

        $this->assertIsArray($providers);
        $this->assertCount(3, $providers);

        // Check first provider has highest rating
        $this->assertEquals('Top Plumber', $providers[0]['name']);
        $this->assertEquals(5.0, $providers[0]['rating']);

        // Check structure
        $this->assertArrayHasKey('id', $providers[0]);
        $this->assertArrayHasKey('name', $providers[0]);
        $this->assertArrayHasKey('rating', $providers[0]);
        $this->assertArrayHasKey('reviews_count', $providers[0]);
        $this->assertArrayHasKey('services', $providers[0]);
        $this->assertArrayHasKey('match_score', $providers[0]);
    }

    /**
     * Test findMatchingProviders with no matching providers
     */
    public function test_find_matching_providers_no_matches(): void
    {
        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('findMatchingProviders');
        $method->setAccessible(true);

        $providers = $method->invoke($this->service, 'Plumbing Repair', 3);

        $this->assertIsArray($providers);
        $this->assertEmpty($providers);
    }

    /**
     * Test findMatchingProviders filters inactive providers
     */
    public function test_find_matching_providers_filters_inactive(): void
    {
        // Create inactive provider
        $provider = User::factory()->create([
            'name' => 'Inactive Plumber',
            'is_active' => false,
            'roles' => ['serviceProvider'],
        ]);

        Service::factory()->create([
            'provider_id' => $provider->id,
            'category' => 'Plumbing Repair',
            'status' => 'active',
        ]);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('findMatchingProviders');
        $method->setAccessible(true);

        $providers = $method->invoke($this->service, 'Plumbing Repair', 3);

        $this->assertEmpty($providers);
    }

    /**
     * Test encodeImageToBase64 method
     */
    public function test_encode_image_to_base64(): void
    {
        // Create test image
        $imagePath = storage_path('app/test_encode.jpg');
        $imageData = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
        file_put_contents($imagePath, $imageData);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('encodeImageToBase64');
        $method->setAccessible(true);

        $base64 = $method->invoke($this->service, $imagePath);

        $this->assertIsString($base64);
        $this->assertNotEmpty($base64);
        $this->assertEquals($imageData, base64_decode($base64));

        // Cleanup
        unlink($imagePath);
    }

    /**
     * Test encodeImageToBase64 with non-existent file
     */
    public function test_encode_image_to_base64_file_not_found(): void
    {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Image file not found');

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('encodeImageToBase64');
        $method->setAccessible(true);

        $method->invoke($this->service, '/non/existent/path.jpg');
    }

    /**
     * Test retry logic on API failure
     */
    public function test_analyze_image_with_retry(): void
    {
        // Create test image
        $imagePath = storage_path('app/test_retry.jpg');
        file_put_contents($imagePath, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

        // Mock API to fail twice then succeed
        $callCount = 0;
        Http::fake(function () use (&$callCount) {
            $callCount++;
            if ($callCount < 3) {
                return Http::response('Server error', 500);
            }
            return Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => json_encode([
                    'diagnosis' => 'Test diagnosis',
                    'service_type' => 'General Maintenance',
                    'cost_estimate' => ['min' => 1000, 'max' => 3000],
                    'confidence' => 0.7,
                ]),
            ], 200);
        });

        $markers = [['x' => 0.5, 'y' => 0.5, 'description' => 'Test']];

        $result = $this->service->analyzeImage($imagePath, $markers);

        $this->assertIsArray($result);
        $this->assertEquals('Test diagnosis', $result['diagnosis']);
        $this->assertEquals(3, $callCount); // Should have retried twice

        // Cleanup
        unlink($imagePath);
    }

    /**
     * Test cost estimate validation ensures max is at least 1.5x min
     */
    public function test_parse_vision_response_ensures_cost_ratio(): void
    {
        $rawResponse = json_encode([
            'diagnosis' => 'Test issue',
            'service_type' => 'Plumbing Repair',
            'cost_estimate' => [
                'min' => 2000,
                'max' => 2500, // Less than 1.5x min
            ],
            'confidence' => 0.8,
        ]);

        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('parseVisionResponse');
        $method->setAccessible(true);

        $result = $method->invoke($this->service, $rawResponse);

        // Max should be adjusted to at least 1.5x min
        $this->assertEquals(2000, $result['cost_min']);
        $this->assertGreaterThanOrEqual(3000, $result['cost_max']); // 2000 * 1.5
    }
}

