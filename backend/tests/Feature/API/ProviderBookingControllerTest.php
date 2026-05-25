<?php

namespace Tests\Feature\API;

use Tests\TestCase;
use App\Models\User;
use App\Models\Booking;
use App\Models\Service;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tymon\JWTAuth\Facades\JWTAuth;

class ProviderBookingControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $provider;
    protected $customer;
    protected $service;
    protected $token;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a service provider user
        $this->provider = User::factory()->create([
            'role' => 'serviceProvider',
            'email_verified_at' => now(),
        ]);

        // Create a customer user
        $this->customer = User::factory()->create([
            'role' => 'customer',
            'email_verified_at' => now(),
        ]);

        // Create a service
        $this->service = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'status' => 'active',
        ]);

        // Generate JWT token for provider
        $this->token = JWTAuth::fromUser($this->provider);
    }

    /**
     * Test provider can list their bookings
     */
    public function test_provider_can_list_their_bookings()
    {
        // Create bookings for this provider
        Booking::factory()->count(3)->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
        ]);

        // Create bookings for another provider (should not be returned)
        $otherProvider = User::factory()->create(['role' => 'serviceProvider']);
        Booking::factory()->count(2)->create([
            'provider_id' => $otherProvider->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson('/api/v1/provider/bookings');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Bookings retrieved successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);

        // Should only return 3 bookings (not 5)
        $this->assertEquals(3, $response->json('meta.total'));
    }

    /**
     * Test provider can filter bookings by status
     */
    public function test_provider_can_filter_bookings_by_status()
    {
        // Create bookings with different statuses
        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'confirmed',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson('/api/v1/provider/bookings?status=pending');

        $response->assertStatus(200);
        $this->assertEquals(1, $response->json('meta.total'));
    }

    /**
     * Test provider can filter bookings by date range
     */
    public function test_provider_can_filter_bookings_by_date_range()
    {
        // Create bookings with different dates
        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'scheduled_at' => now()->addDays(5),
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'scheduled_at' => now()->addDays(15),
        ]);

        $dateFrom = now()->addDays(1)->toDateString();
        $dateTo = now()->addDays(10)->toDateString();

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson("/api/v1/provider/bookings?date_from={$dateFrom}&date_to={$dateTo}");

        $response->assertStatus(200);
        $this->assertEquals(1, $response->json('meta.total'));
    }

    /**
     * Test provider can view booking details
     */
    public function test_provider_can_view_booking_details()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson("/api/v1/provider/bookings/{$booking->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking retrieved successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'customer_id',
                    'service_id',
                    'provider_id',
                    'status',
                    'total_price',
                    'customer',
                    'service',
                    'provider',
                ],
            ]);
    }

    /**
     * Test provider cannot view another provider's booking
     */
    public function test_provider_cannot_view_another_providers_booking()
    {
        $otherProvider = User::factory()->create(['role' => 'serviceProvider']);
        $booking = Booking::factory()->create([
            'provider_id' => $otherProvider->id,
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson("/api/v1/provider/bookings/{$booking->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized access to booking',
            ]);
    }

    /**
     * Test provider can accept pending booking
     */
    public function test_provider_can_accept_pending_booking()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/accept");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking accepted successfully',
                'data' => [
                    'id' => $booking->id,
                    'status' => 'confirmed',
                ],
            ]);

        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'confirmed',
        ]);
    }

    /**
     * Test provider cannot accept non-pending booking
     */
    public function test_provider_cannot_accept_non_pending_booking()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'confirmed',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/accept");

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    /**
     * Test provider can reject pending booking with reason
     */
    public function test_provider_can_reject_pending_booking()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/reject", [
            'rejection_reason' => 'Not available at that time',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking rejected successfully',
                'data' => [
                    'id' => $booking->id,
                    'status' => 'rejected',
                ],
            ]);

        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'rejected',
            'cancellation_reason' => 'Not available at that time',
        ]);
    }

    /**
     * Test provider cannot reject booking without reason
     */
    public function test_provider_cannot_reject_booking_without_reason()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/reject", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['rejection_reason']);
    }

    /**
     * Test provider can complete confirmed booking
     */
    public function test_provider_can_complete_confirmed_booking()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'confirmed',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/complete");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking marked as completed successfully',
                'data' => [
                    'id' => $booking->id,
                    'status' => 'completed',
                ],
            ]);

        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'completed',
        ]);
    }

    /**
     * Test provider cannot complete non-confirmed booking
     */
    public function test_provider_cannot_complete_non_confirmed_booking()
    {
        $booking = Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/complete");

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    /**
     * Test provider can get list of pending bookings
     */
    public function test_provider_can_get_pending_bookings()
    {
        // Create bookings with different statuses
        Booking::factory()->count(2)->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'confirmed',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson('/api/v1/provider/bookings/pending');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Pending bookings retrieved successfully',
            ]);

        // Should only return 2 pending bookings
        $this->assertEquals(2, $response->json('meta.total'));
    }

    /**
     * Test provider can get booking statistics
     */
    public function test_provider_can_get_booking_statistics()
    {
        // Create bookings with different statuses
        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
            'scheduled_at' => now()->addDays(5),
            'total_price' => 100,
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'confirmed',
            'scheduled_at' => now()->addDays(10),
            'total_price' => 150,
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'completed',
            'scheduled_at' => now()->addDays(3),
            'total_price' => 200,
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson('/api/v1/provider/bookings/stats');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking statistics retrieved successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'total_bookings',
                    'pending_count',
                    'confirmed_count',
                    'completed_count',
                    'cancelled_count',
                    'rejected_count',
                    'total_revenue',
                    'date_from',
                    'date_to',
                ],
            ]);

        $data = $response->json('data');
        $this->assertEquals(3, $data['total_bookings']);
        $this->assertEquals(1, $data['pending_count']);
        $this->assertEquals(1, $data['confirmed_count']);
        $this->assertEquals(1, $data['completed_count']);
        $this->assertEquals(200, $data['total_revenue']);
    }

    /**
     * Test provider can get statistics with custom date range
     */
    public function test_provider_can_get_statistics_with_custom_date_range()
    {
        // Create booking within date range
        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'completed',
            'scheduled_at' => now()->addDays(5),
            'total_price' => 100,
        ]);

        // Create booking outside date range
        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'completed',
            'scheduled_at' => now()->addDays(20),
            'total_price' => 200,
        ]);

        $dateFrom = now()->addDays(1)->toDateString();
        $dateTo = now()->addDays(10)->toDateString();

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson("/api/v1/provider/bookings/stats?date_from={$dateFrom}&date_to={$dateTo}");

        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertEquals(1, $data['total_bookings']);
        $this->assertEquals(100, $data['total_revenue']);
    }

    /**
     * Test unauthenticated user cannot access provider endpoints
     */
    public function test_unauthenticated_user_cannot_access_provider_endpoints()
    {
        $response = $this->getJson('/api/v1/provider/bookings');
        $response->assertStatus(401);
    }
}
