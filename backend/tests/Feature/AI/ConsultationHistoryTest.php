<?php

namespace Tests\Feature\AI;

use App\Models\AIConsultation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

class ConsultationHistoryTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    private User $customer;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a customer user
        $this->customer = User::factory()->create([
            'role' => 'customer',
            'email_verified_at' => now(),
        ]);

        // Generate JWT token
        $this->token = JWTAuth::fromUser($this->customer);
    }

    /**
     * Test GET /api/v1/customer/ai/consultations - index endpoint
     */
    public function test_index_returns_paginated_consultations()
    {
        // Create 25 consultations for the customer
        AIConsultation::factory()->count(25)->create([
            'customer_id' => $this->customer->id,
        ]);

        // Create 5 consultations for another customer (should not be returned)
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        AIConsultation::factory()->count(5)->create([
            'customer_id' => $otherCustomer->id,
        ]);

        // Make request
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations');

        // Assert response
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'consultations' => [
                        '*' => [
                            'id',
                            'image_url',
                            'diagnosis',
                            'recommended_service_type',
                            'cost_min',
                            'cost_max',
                            'created_at',
                        ],
                    ],
                    'pagination' => [
                        'current_page',
                        'per_page',
                        'total',
                        'last_page',
                    ],
                ],
            ]);

        $data = $response->json('data');
        
        // Assert pagination
        $this->assertEquals(1, $data['pagination']['current_page']);
        $this->assertEquals(20, $data['pagination']['per_page']);
        $this->assertEquals(25, $data['pagination']['total']);
        $this->assertEquals(2, $data['pagination']['last_page']);
        
        // Assert only customer's consultations returned
        $this->assertCount(20, $data['consultations']);
    }

    /**
     * Test pagination with custom per_page parameter
     */
    public function test_index_respects_per_page_parameter()
    {
        AIConsultation::factory()->count(15)->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations?per_page=5');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertEquals(5, $data['pagination']['per_page']);
        $this->assertCount(5, $data['consultations']);
    }

    /**
     * Test pagination max limit (50 per page)
     */
    public function test_index_enforces_max_per_page_limit()
    {
        AIConsultation::factory()->count(60)->create([
            'customer_id' => $this->customer->id,
        ]);

        // Request 100 per page, should be capped at 50
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations?per_page=100');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertEquals(50, $data['pagination']['per_page']);
        $this->assertCount(50, $data['consultations']);
    }

    /**
     * Test filtering by service_type
     */
    public function test_index_filters_by_service_type()
    {
        // Create consultations with different service types
        AIConsultation::factory()->count(5)->create([
            'customer_id' => $this->customer->id,
            'recommended_service_type' => 'Plumbing Repair',
        ]);

        AIConsultation::factory()->count(3)->create([
            'customer_id' => $this->customer->id,
            'recommended_service_type' => 'Electrical Work',
        ]);

        // Filter by Plumbing Repair
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations?service_type=Plumbing Repair');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertEquals(5, $data['pagination']['total']);
        
        // Verify all returned consultations have the correct service type
        foreach ($data['consultations'] as $consultation) {
            $this->assertEquals('Plumbing Repair', $consultation['recommended_service_type']);
        }
    }

    /**
     * Test GET /api/v1/customer/ai/consultations/{id} - show endpoint
     */
    public function test_show_returns_consultation_details()
    {
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $this->customer->id,
            'markers' => [
                ['x' => 0.5, 'y' => 0.5, 'description' => 'Test marker'],
            ],
            'recommended_providers' => [
                ['id' => 'uuid-1', 'name' => 'Test Provider', 'rating' => 4.5, 'services' => ['Plumbing']],
            ],
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
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

        $data = $response->json('data.consultation');
        $this->assertEquals($consultation->id, $data['id']);
        $this->assertIsArray($data['markers']);
        $this->assertIsArray($data['recommended_providers']);
    }

    /**
     * Test show endpoint returns 404 for non-existent consultation
     */
    public function test_show_returns_404_for_non_existent_consultation()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations/non-existent-id');

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Consultation not found',
            ]);
    }

    /**
     * Test show endpoint returns 403 for unauthorized access
     */
    public function test_show_prevents_cross_customer_access()
    {
        // Create consultation for another customer
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $otherCustomer->id,
        ]);

        // Try to access with current customer's token
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized access to this consultation',
            ]);
    }

    /**
     * Test DELETE /api/v1/customer/ai/consultations/{id} - destroy endpoint
     */
    public function test_destroy_soft_deletes_consultation()
    {
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->deleteJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Consultation deleted successfully',
            ]);

        // Verify soft delete
        $this->assertSoftDeleted('ai_consultations', [
            'id' => $consultation->id,
        ]);

        // Verify consultation is not returned in index
        $indexResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations');

        $consultations = $indexResponse->json('data.consultations');
        $ids = array_column($consultations, 'id');
        $this->assertNotContains($consultation->id, $ids);
    }

    /**
     * Test destroy endpoint returns 404 for non-existent consultation
     */
    public function test_destroy_returns_404_for_non_existent_consultation()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->deleteJson('/api/v1/customer/ai/consultations/non-existent-id');

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Consultation not found',
            ]);
    }

    /**
     * Test destroy endpoint returns 403 for unauthorized access
     */
    public function test_destroy_prevents_cross_customer_access()
    {
        // Create consultation for another customer
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $consultation = AIConsultation::factory()->create([
            'customer_id' => $otherCustomer->id,
        ]);

        // Try to delete with current customer's token
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->deleteJson("/api/v1/customer/ai/consultations/{$consultation->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized access to this consultation',
            ]);

        // Verify consultation was not deleted
        $this->assertDatabaseHas('ai_consultations', [
            'id' => $consultation->id,
            'deleted_at' => null,
        ]);
    }

    /**
     * Test endpoints require authentication
     */
    public function test_endpoints_require_authentication()
    {
        // Test index without token
        $response = $this->getJson('/api/v1/customer/ai/consultations');
        $response->assertStatus(401);

        // Test show without token
        $response = $this->getJson('/api/v1/customer/ai/consultations/some-id');
        $response->assertStatus(401);

        // Test destroy without token
        $response = $this->deleteJson('/api/v1/customer/ai/consultations/some-id');
        $response->assertStatus(401);
    }

    /**
     * Test consultations are ordered by created_at descending
     */
    public function test_index_returns_consultations_in_reverse_chronological_order()
    {
        // Create consultations with different timestamps
        $older = AIConsultation::factory()->create([
            'customer_id' => $this->customer->id,
            'created_at' => now()->subDays(2),
        ]);

        $newer = AIConsultation::factory()->create([
            'customer_id' => $this->customer->id,
            'created_at' => now()->subDay(),
        ]);

        $newest = AIConsultation::factory()->create([
            'customer_id' => $this->customer->id,
            'created_at' => now(),
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/customer/ai/consultations');

        $consultations = $response->json('data.consultations');
        
        // Verify order (newest first)
        $this->assertEquals($newest->id, $consultations[0]['id']);
        $this->assertEquals($newer->id, $consultations[1]['id']);
        $this->assertEquals($older->id, $consultations[2]['id']);
    }
}
