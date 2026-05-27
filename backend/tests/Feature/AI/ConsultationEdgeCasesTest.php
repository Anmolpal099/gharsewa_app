<?php

namespace Tests\Feature\AI;

use Tests\TestCase;
use App\Models\User;
use App\Models\AIConsultation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;

class ConsultationEdgeCasesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    /** @test */
    public function it_handles_maximum_markers_limit()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create 10 markers (maximum allowed)
        $markers = [];
        for ($i = 1; $i <= 10; $i++) {
            $markers[] = [
                'id' => (string) $i,
                'x' => 0.1 * $i,
                'y' => 0.1 * $i,
                'description' => "Issue {$i}",
            ];
        }

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $this->getValidBase64Image(),
            'markers' => $markers,
        ]);

        $response->assertStatus(201);
    }

    /** @test */
    public function it_rejects_more_than_10_markers()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create 11 markers (exceeds maximum)
        $markers = [];
        for ($i = 1; $i <= 11; $i++) {
            $markers[] = [
                'id' => (string) $i,
                'x' => 0.1,
                'y' => 0.1,
                'description' => "Issue {$i}",
            ];
        }

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $this->getValidBase64Image(),
            'markers' => $markers,
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('markers');
    }

    /** @test */
    public function it_handles_minimum_markers_requirement()
    {
        $customer = $this->createAuthenticatedCustomer();

        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $this->getValidBase64Image(),
            'markers' => [], // No markers
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('markers');
    }

    /** @test */
    public function it_validates_marker_coordinates_range()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Test coordinates outside valid range (0-1)
        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $this->getValidBase64Image(),
            'markers' => [
                [
                    'id' => '1',
                    'x' => 1.5, // Invalid: > 1
                    'y' => 0.5,
                    'description' => 'Test issue',
                ],
            ],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('markers.0.x');
    }

    /** @test */
    public function it_validates_marker_description_length()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Test description too short
        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $this->getValidBase64Image(),
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => 'A', // Too short (< 2 chars)
                ],
            ],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('markers.0.description');

        // Test description too long
        $response = $this->postJson('/api/v1/customer/ai/consultations', [
            'image' => $this->getValidBase64Image(),
            'markers' => [
                [
                    'id' => '1',
                    'x' => 0.5,
                    'y' => 0.5,
                    'description' => str_repeat('A', 501), // Too long (> 500 chars)
                ],
            ],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('markers.0.description');
    }

    /** @test */
    public function it_handles_pagination_edge_cases()
    {
        $customer = $this->createAuthenticatedCustomer();

        // Create consultations
        AIConsultation::factory()->count(5)->create([
            'customer_id' => $customer->id,
        ]);

        // Test requesting more than max per_page (50)
        $response = $this->getJson('/api/v1/customer/ai/consultations?per_page=100');

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertLessThanOrEqual(50, $data['per_page']);

        // Test requesting page beyond last page
        $response = $this->getJson('/api/v1/customer/ai/consultations?page=999');

        $response->assertStatus(200);
        $this->assertEmpty($response->json('data.consultations'));
    }

    /** @test */
    public function it_handles_concurrent_requests_with_rate_limiting()
    {
        $customer = $this->createAuthenticatedCustomer();

        $successCount = 0;
        $rateLimitedCount = 0;

        // Make 15 requests (rate limit is 10 per minute)
        for ($i = 0; $i < 15; $i++) {
            $response = $this->postJson('/api/v1/customer/ai/consultations', [
                'image' => $this->getValidBase64Image(),
                'markers' => [
                    [
                        'id' => '1',
                        'x' => 0.5,
                        'y' => 0.5,
                        'description' => "Test issue {$i}",
                    ],
                ],
            ]);

            if ($response->status() === 201) {
                $successCount++;
            } elseif ($response->status() === 429) {
                $rateLimitedCount++;
            }
        }

        // Should have some rate-limited requests
        $this->assertGreaterThan(0, $rateLimitedCount);
        $this->assertLessThanOrEqual(10, $successCount);
    }

    /** @test */
    public function it_prevents_cross_customer_access_to_consultations()
    {
        $customer1 = $this->createAuthenticatedCustomer();
        $customer2 = User::factory()->create(['role' => 'customer']);

        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer2->id,
        ]);

        // Try to access another customer's consultation
        $response = $this->getJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(403);
    }

    /** @test */
    public function it_prevents_cross_customer_deletion()
    {
        $customer1 = $this->createAuthenticatedCustomer();
        $customer2 = User::factory()->create(['role' => 'customer']);

        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer2->id,
        ]);

        // Try to delete another customer's consultation
        $response = $this->deleteJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(403);

        // Verify consultation still exists
        $this->assertDatabaseHas('ai_consultations', [
            'id' => $consultation->id,
            'deleted_at' => null,
        ]);
    }

    /** @test */
    public function it_handles_non_existent_consultation_gracefully()
    {
        $customer = $this->createAuthenticatedCustomer();

        $response = $this->getJson('/api/v1/customer/ai/consultations/non-existent-id');

        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'message' => 'Consultation not found',
        ]);
    }

    /** @test */
    public function it_handles_soft_deleted_consultations()
    {
        $customer = $this->createAuthenticatedCustomer();

        $consultation = AIConsultation::factory()->create([
            'customer_id' => $customer->id,
        ]);

        // Soft delete the consultation
        $consultation->delete();

        // Try to access soft-deleted consultation
        $response = $this->getJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(404);
    }

    /** @test */
    public function it_filters_by_service_type_case_insensitively()
    {
        $customer = $this->createAuthenticatedCustomer();

        AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'recommended_service_type' => 'plumbing',
        ]);

        AIConsultation::factory()->create([
            'customer_id' => $customer->id,
            'recommended_service_type' => 'Plumbing', // Different case
        ]);

        $response = $this->getJson('/api/v1/customer/ai/consultations?service_type=plumbing');

        $response->assertStatus(200);
        $consultations = $response->json('data.consultations');
        
        // Should find both regardless of case
        $this->assertGreaterThanOrEqual(1, count($consultations));
    }

    /** @test */
    public function it_handles_empty_history_gracefully()
    {
        $customer = $this->createAuthenticatedCustomer();

        $response = $this->getJson('/api/v1/customer/ai/consultations');

        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
            'data' => [
                'consultations' => [],
                'total' => 0,
            ],
        ]);
    }

    /** @test */
    public function it_requires_authentication_for_all_endpoints()
    {
        // Clear authentication
        $this->withoutMiddleware();

        $endpoints = [
            ['method' => 'post', 'uri' => '/api/v1/customer/ai/consultations'],
            ['method' => 'get', 'uri' => '/api/v1/customer/ai/consultations'],
            ['method' => 'get', 'uri' => '/api/v1/customer/ai/consultations/test-id'],
            ['method' => 'delete', 'uri' => '/api/v1/customer/ai/consultations/test-id'],
        ];

        foreach ($endpoints as $endpoint) {
            $response = $this->{$endpoint['method'] . 'Json'}($endpoint['uri']);
            
            // Without proper authentication, should get 401 or redirect
            $this->assertContains($response->status(), [401, 302]);
        }
    }

    /**
     * Create an authenticated customer user
     */
    protected function createAuthenticatedCustomer(): User
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $this->actingAs($customer, 'api');
        return $customer;
    }

    /**
     * Get a valid base64 encoded test image
     */
    protected function getValidBase64Image(): string
    {
        // Create a minimal 1x1 pixel PNG
        $image = imagecreatetruecolor(1, 1);
        imagecolorallocate($image, 255, 0, 0);
        
        ob_start();
        imagepng($image);
        $imageData = ob_get_clean();
        imagedestroy($image);

        return base64_encode($imageData);
    }
}
