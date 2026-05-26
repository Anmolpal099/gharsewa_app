<?php

namespace Tests\Feature\API\V1\AI;

use Tests\TestCase;
use App\Models\User;
use App\Models\Service;
use App\Models\AIRecommendation;
use App\Services\AI\RecommendationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;
use Mockery;

class RecommendationControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $customer;
    protected User $provider;
    protected User $admin;
    protected string $token;

    protected function setUp(): void
    {
        parent::setUp();

        // Create test users
        $this->customer = User::factory()->create([
            'role' => 'customer',
            'email' => 'customer@test.com',
        ]);

        $this->provider = User::factory()->create([
            'role' => 'provider',
            'email' => 'provider@test.com',
        ]);

        $this->admin = User::factory()->create([
            'role' => 'admin',
            'email' => 'admin@test.com',
        ]);

        // Generate token for customer
        $this->token = auth('api')->login($this->customer);

        // Clear rate limiter
        RateLimiter::clear('recommendations:' . $this->customer->id);
    }

    protected function tearDown(): void
    {
        RateLimiter::clear('recommendations:' . $this->customer->id);
        Mockery::close();
        parent::tearDown();
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations - successful retrieval
     * Validates: Requirement 8.6 - Authentication required
     */
    public function test_get_recommendations_requires_authentication(): void
    {
        $response = $this->getJson('/api/v1/customer/ai/recommendations');

        $response->assertStatus(401);
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations - successful retrieval with cached data
     * Validates: Requirement 8.6 - Successful response
     */
    public function test_get_recommendations_returns_cached_recommendations(): void
    {
        // Create test service
        $service = Service::factory()->create([
            'name' => 'House Cleaning',
            'category' => 'cleaning',
            'price' => 1500,
        ]);

        // Create cached recommendation
        AIRecommendation::create([
            'id' => \Illuminate\Support\Str::uuid(),
            'user_id' => $this->customer->id,
            'service_id' => $service->id,
            'confidence_score' => 85.5,
            'reasoning' => 'Based on your previous bookings',
            'expires_at' => now()->addHours(2),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/customer/ai/recommendations');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Recommendations retrieved from cache',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'recommendations' => [
                        '*' => [
                            'id',
                            'service' => [
                                'id',
                                'name',
                                'category',
                                'price',
                                'description',
                            ],
                            'confidence_score',
                            'reasoning',
                            'expires_at',
                        ],
                    ],
                    'cached',
                ],
            ]);

        $this->assertTrue($response->json('data.cached'));
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations - generate new recommendations
     * Validates: Requirement 8.6 - Successful response
     */
    public function test_get_recommendations_generates_new_recommendations(): void
    {
        // Mock RecommendationService
        $serviceMock = Mockery::mock(RecommendationService::class);
        $serviceMock->shouldReceive('generateRecommendations')
            ->once()
            ->andReturn([]);
        
        $this->app->instance(RecommendationService::class, $serviceMock);

        // Create test service
        $service = Service::factory()->create();

        // Create fresh recommendation
        AIRecommendation::create([
            'id' => \Illuminate\Support\Str::uuid(),
            'user_id' => $this->customer->id,
            'service_id' => $service->id,
            'confidence_score' => 90.0,
            'reasoning' => 'Highly recommended',
            'expires_at' => now()->addHours(2),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/customer/ai/recommendations?refresh=true');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Recommendations generated successfully',
            ]);

        $this->assertFalse($response->json('data.cached'));
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations - limit validation
     * Validates: Requirement 8.8 - Input validation (400 error)
     */
    public function test_get_recommendations_validates_limit_parameter(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/customer/ai/recommendations?limit=25');

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Limit must be between 1 and 20',
            ]);
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations - rate limiting
     * Validates: Requirement 8.10 - Rate limiting (429 response)
     */
    public function test_get_recommendations_enforces_rate_limiting(): void
    {
        // Hit rate limit (10 requests)
        for ($i = 0; $i < 10; $i++) {
            RateLimiter::hit('recommendations:' . $this->customer->id, 60);
        }

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/customer/ai/recommendations?refresh=true');

        $response->assertStatus(429)
            ->assertJson([
                'success' => false,
            ])
            ->assertJsonStructure([
                'success',
                'message',
            ]);
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations - error handling
     * Validates: Requirement 8.8 - Error response (500)
     */
    public function test_get_recommendations_handles_service_errors(): void
    {
        // Mock RecommendationService to throw exception
        $serviceMock = Mockery::mock(RecommendationService::class);
        $serviceMock->shouldReceive('generateRecommendations')
            ->once()
            ->andThrow(new \Exception('AI service unavailable'));
        
        $this->app->instance(RecommendationService::class, $serviceMock);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/customer/ai/recommendations?refresh=true');

        $response->assertStatus(500)
            ->assertJson([
                'success' => false,
                'message' => 'Failed to generate recommendations',
            ]);
    }

    /**
     * Test POST /api/v1/customer/ai/recommendations/feedback - successful feedback
     * Validates: Requirement 8.6 - Authentication and successful response
     */
    public function test_record_feedback_successfully(): void
    {
        // Create test service and recommendation
        $service = Service::factory()->create();
        $recommendation = AIRecommendation::create([
            'id' => \Illuminate\Support\Str::uuid(),
            'user_id' => $this->customer->id,
            'service_id' => $service->id,
            'confidence_score' => 85.0,
            'reasoning' => 'Test recommendation',
            'expires_at' => now()->addHours(2),
        ]);

        // Mock RecommendationService
        $serviceMock = Mockery::mock(RecommendationService::class);
        $serviceMock->shouldReceive('recordFeedback')
            ->once()
            ->with($recommendation->id, 'clicked')
            ->andReturn(true);
        
        $this->app->instance(RecommendationService::class, $serviceMock);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/customer/ai/recommendations/feedback', [
                'recommendation_id' => $recommendation->id,
                'action' => 'clicked',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Feedback recorded successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'recommendation_id',
                    'action',
                    'recorded_at',
                ],
            ]);
    }

    /**
     * Test POST /api/v1/customer/ai/recommendations/feedback - validation errors
     * Validates: Requirement 8.8 - Validation error (422)
     */
    public function test_record_feedback_validates_input(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/customer/ai/recommendations/feedback', [
                'recommendation_id' => 'invalid-uuid',
                'action' => 'invalid-action',
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed',
            ])
            ->assertJsonValidationErrors(['recommendation_id', 'action']);
    }

    /**
     * Test POST /api/v1/customer/ai/recommendations/feedback - unauthorized access
     * Validates: Requirement 8.7 - Authorization (403)
     */
    public function test_record_feedback_prevents_unauthorized_access(): void
    {
        // Create recommendation for another user
        $otherUser = User::factory()->create(['role' => 'customer']);
        $service = Service::factory()->create();
        $recommendation = AIRecommendation::create([
            'id' => \Illuminate\Support\Str::uuid(),
            'user_id' => $otherUser->id,
            'service_id' => $service->id,
            'confidence_score' => 85.0,
            'reasoning' => 'Test recommendation',
            'expires_at' => now()->addHours(2),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/customer/ai/recommendations/feedback', [
                'recommendation_id' => $recommendation->id,
                'action' => 'clicked',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized access to recommendation',
            ]);
    }

    /**
     * Test POST /api/v1/customer/ai/recommendations/feedback - not found
     * Validates: Requirement 8.8 - Not found error (422)
     */
    public function test_record_feedback_handles_not_found(): void
    {
        $fakeUuid = \Illuminate\Support\Str::uuid();

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/customer/ai/recommendations/feedback', [
                'recommendation_id' => $fakeUuid,
                'action' => 'clicked',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recommendation_id']);
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations/stats - successful retrieval
     * Validates: Requirement 8.6 - Authentication and successful response
     */
    public function test_get_stats_returns_recommendation_statistics(): void
    {
        // Create test recommendations
        $service = Service::factory()->create();
        
        AIRecommendation::create([
            'id' => \Illuminate\Support\Str::uuid(),
            'user_id' => $this->customer->id,
            'service_id' => $service->id,
            'confidence_score' => 85.0,
            'reasoning' => 'Test',
            'expires_at' => now()->addHours(2),
            'clicked_at' => now(),
        ]);

        AIRecommendation::create([
            'id' => \Illuminate\Support\Str::uuid(),
            'user_id' => $this->customer->id,
            'service_id' => $service->id,
            'confidence_score' => 90.0,
            'reasoning' => 'Test',
            'expires_at' => now()->addHours(2),
            'booked_at' => now(),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/customer/ai/recommendations/stats');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'total_recommendations',
                    'active_recommendations',
                    'clicked_recommendations',
                    'booked_recommendations',
                    'click_rate',
                    'conversion_rate',
                ],
            ]);
    }

    /**
     * Test GET /api/v1/customer/ai/recommendations/stats - requires authentication
     * Validates: Requirement 8.6 - Authentication required
     */
    public function test_get_stats_requires_authentication(): void
    {
        $response = $this->getJson('/api/v1/customer/ai/recommendations/stats');

        $response->assertStatus(401);
    }
}
