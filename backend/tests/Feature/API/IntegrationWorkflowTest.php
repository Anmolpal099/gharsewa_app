<?php

namespace Tests\Feature\API;

use Tests\TestCase;
use App\Models\User;
use App\Models\Booking;
use App\Models\Service;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tymon\JWTAuth\Facades\JWTAuth;

/**
 * Integration tests for complete user workflows
 * Tests end-to-end scenarios across multiple endpoints
 * 
 * Requirements:
 * - FR1: Service Management (Provider)
 * - FR2: Service Browsing (Customer/Public)
 * - FR3: Booking Management (Customer)
 * - FR4: Booking Management (Provider)
 * - NFR1: Security (Authentication & Authorization)
 */
class IntegrationWorkflowTest extends TestCase
{
    use RefreshDatabase;

    protected $provider;
    protected $customer;
    protected $providerToken;
    protected $customerToken;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a service provider user
        $this->provider = User::factory()->create([
            'role' => 'serviceProvider',
            'email_verified_at' => now(),
            'name' => 'Test Provider',
            'email' => 'provider@test.com',
        ]);

        // Create a customer user
        $this->customer = User::factory()->create([
            'role' => 'customer',
            'email_verified_at' => now(),
            'name' => 'Test Customer',
            'email' => 'customer@test.com',
        ]);

        // Generate JWT tokens
        $this->providerToken = JWTAuth::fromUser($this->provider);
        $this->customerToken = JWTAuth::fromUser($this->customer);
    }

    /**
     * Test complete provider workflow:
     * 1. Create service
     * 2. Receive booking request
     * 3. Accept booking
     * 4. Complete booking
     * 
     * @test
     */
    public function test_complete_provider_workflow()
    {
        // Step 1: Provider creates a service
        $serviceData = [
            'name' => 'House Cleaning Service',
            'description' => 'Professional house cleaning service',
            'category' => 'Cleaning',
            'price' => 1500,
            'duration_minutes' => 120,
            'currency' => 'NPR',
        ];

        $createServiceResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson('/api/v1/provider/services', $serviceData);

        $createServiceResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Service created successfully',
            ])
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'description',
                    'category',
                    'price',
                    'duration_minutes',
                    'currency',
                    'status',
                    'provider_id',
                ],
            ]);

        $serviceId = $createServiceResponse->json('data.id');
        $this->assertNotNull($serviceId);

        // Verify service is in database
        $this->assertDatabaseHas('services', [
            'id' => $serviceId,
            'name' => 'House Cleaning Service',
            'provider_id' => $this->provider->id,
            'status' => 'active',
        ]);

        // Step 2: Customer creates a booking for this service
        $bookingData = [
            'service_id' => $serviceId,
            'scheduled_at' => now()->addDays(3)->toDateTimeString(),
            'notes' => 'Please bring cleaning supplies',
        ];

        $createBookingResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->postJson('/api/v1/customer/bookings', $bookingData);

        $createBookingResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Booking created successfully',
            ])
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'customer_id',
                    'service_id',
                    'provider_id',
                    'status',
                    'total_price',
                    'scheduled_at',
                    'notes',
                ],
            ]);

        $bookingId = $createBookingResponse->json('data.id');
        $this->assertEquals('pending', $createBookingResponse->json('data.status'));
        $this->assertEquals(1500, $createBookingResponse->json('data.total_price'));
        $this->assertEquals($this->provider->id, $createBookingResponse->json('data.provider_id'));

        // Verify booking is in database
        $this->assertDatabaseHas('bookings', [
            'id' => $bookingId,
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $serviceId,
            'status' => 'pending',
            'total_price' => 1500,
        ]);

        // Step 3: Provider receives and views the booking
        $viewBookingResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->getJson("/api/v1/provider/bookings/{$bookingId}");

        $viewBookingResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $bookingId,
                    'status' => 'pending',
                ],
            ]);

        // Step 4: Provider accepts the booking
        $acceptBookingResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$bookingId}/accept");

        $acceptBookingResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking accepted successfully',
                'data' => [
                    'id' => $bookingId,
                    'status' => 'confirmed',
                ],
            ]);

        // Verify booking status updated
        $this->assertDatabaseHas('bookings', [
            'id' => $bookingId,
            'status' => 'confirmed',
        ]);

        // Step 5: Provider completes the booking
        $completeBookingResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$bookingId}/complete");

        $completeBookingResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking marked as completed successfully',
                'data' => [
                    'id' => $bookingId,
                    'status' => 'completed',
                ],
            ]);

        // Verify final booking status
        $this->assertDatabaseHas('bookings', [
            'id' => $bookingId,
            'status' => 'completed',
        ]);

        // Step 6: Verify provider dashboard shows updated statistics
        $dashboardResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->getJson('/api/v1/provider/dashboard');

        $dashboardResponse->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'total_services',
                    'active_services',
                    'total_bookings',
                    'pending_bookings',
                    'this_month_earnings',
                    'this_month_bookings',
                ],
            ]);

        $dashboardData = $dashboardResponse->json('data');
        $this->assertEquals(1, $dashboardData['total_services']);
        $this->assertEquals(1, $dashboardData['active_services']);
        $this->assertEquals(1, $dashboardData['total_bookings']);
        $this->assertEquals(0, $dashboardData['pending_bookings']); // No pending, it's completed
    }

    /**
     * Test complete customer workflow:
     * 1. Browse services
     * 2. View service details
     * 3. Create booking
     * 4. Cancel booking
     * 
     * @test
     */
    public function test_complete_customer_workflow()
    {
        // Setup: Create multiple services
        $service1 = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'name' => 'Plumbing Service',
            'category' => 'Plumbing',
            'price' => 2000,
            'status' => 'active',
        ]);

        $service2 = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'name' => 'Electrical Service',
            'category' => 'Electrical',
            'price' => 2500,
            'status' => 'active',
        ]);

        $service3 = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'name' => 'Carpentry Service',
            'category' => 'Carpentry',
            'price' => 3000,
            'status' => 'inactive', // This should not appear in public listing
        ]);

        // Step 1: Customer browses services (no authentication required)
        $browseResponse = $this->getJson('/api/v1/services');

        $browseResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Services retrieved successfully',
            ])
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'category',
                        'price',
                        'status',
                        'provider',
                    ],
                ],
                'meta',
            ]);

        // Should only show 2 active services
        $this->assertEquals(2, $browseResponse->json('meta.total'));

        // Step 2: Customer views specific service details
        $serviceDetailsResponse = $this->getJson("/api/v1/services/{$service1->id}");

        $serviceDetailsResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $service1->id,
                    'name' => 'Plumbing Service',
                    'category' => 'Plumbing',
                    'price' => 2000,
                ],
            ])
            ->assertJsonStructure([
                'data' => [
                    'provider' => [
                        'id',
                        'name',
                        'email',
                    ],
                ],
            ]);

        // Step 3: Customer creates a booking
        $bookingData = [
            'service_id' => $service1->id,
            'scheduled_at' => now()->addDays(5)->toDateTimeString(),
            'notes' => 'Kitchen sink is leaking',
        ];

        $createBookingResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->postJson('/api/v1/customer/bookings', $bookingData);

        $createBookingResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Booking created successfully',
            ]);

        $bookingId = $createBookingResponse->json('data.id');
        $this->assertEquals('pending', $createBookingResponse->json('data.status'));
        $this->assertEquals(2000, $createBookingResponse->json('data.total_price'));

        // Step 4: Customer views their bookings
        $myBookingsResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->getJson('/api/v1/customer/bookings');

        $myBookingsResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertEquals(1, $myBookingsResponse->json('meta.total'));

        // Step 5: Customer cancels the booking
        $cancelData = [
            'cancellation_reason' => 'Found another service provider',
        ];

        $cancelBookingResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->putJson("/api/v1/customer/bookings/{$bookingId}/cancel", $cancelData);

        $cancelBookingResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking cancelled successfully',
                'data' => [
                    'id' => $bookingId,
                    'status' => 'cancelled',
                ],
            ]);

        // Verify booking is cancelled in database
        $this->assertDatabaseHas('bookings', [
            'id' => $bookingId,
            'status' => 'cancelled',
            'cancellation_reason' => 'Found another service provider',
        ]);
    }

    /**
     * Test service search and filtering workflow
     * 
     * @test
     */
    public function test_service_search_and_filtering_workflow()
    {
        // Setup: Create services with different categories and prices
        Service::factory()->create([
            'provider_id' => $this->provider->id,
            'name' => 'Basic Cleaning',
            'category' => 'Cleaning',
            'price' => 1000,
            'status' => 'active',
        ]);

        Service::factory()->create([
            'provider_id' => $this->provider->id,
            'name' => 'Deep Cleaning',
            'category' => 'Cleaning',
            'price' => 2500,
            'status' => 'active',
        ]);

        Service::factory()->create([
            'provider_id' => $this->provider->id,
            'name' => 'Plumbing Repair',
            'category' => 'Plumbing',
            'price' => 1500,
            'status' => 'active',
        ]);

        // Test 1: Filter by category
        $categoryFilterResponse = $this->getJson('/api/v1/services?category=Cleaning');

        $categoryFilterResponse->assertStatus(200);
        $this->assertEquals(2, $categoryFilterResponse->json('meta.total'));

        // Test 2: Filter by price range
        $priceFilterResponse = $this->getJson('/api/v1/services?min_price=1000&max_price=2000');

        $priceFilterResponse->assertStatus(200);
        $this->assertEquals(2, $priceFilterResponse->json('meta.total'));

        // Test 3: Search by name
        $searchResponse = $this->getJson('/api/v1/services?search=cleaning');

        $searchResponse->assertStatus(200);
        $this->assertEquals(2, $searchResponse->json('meta.total'));

        // Test 4: Get categories list
        $categoriesResponse = $this->getJson('/api/v1/services/categories');

        $categoriesResponse->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'category',
                        'count',
                    ],
                ],
            ]);

        $categories = $categoriesResponse->json('data');
        $this->assertCount(2, $categories); // Cleaning and Plumbing
    }

    /**
     * Test authentication and authorization across workflows
     * 
     * @test
     */
    public function test_authentication_and_authorization_workflow()
    {
        // Setup: Create a service and booking
        $service = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'status' => 'active',
        ]);

        $booking = Booking::factory()->create([
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $service->id,
            'status' => 'pending',
        ]);

        // Test 1: Unauthenticated user cannot access protected endpoints
        $this->getJson('/api/v1/customer/bookings')
            ->assertStatus(401);

        $this->getJson('/api/v1/provider/services')
            ->assertStatus(401);

        $this->getJson('/api/v1/user/profile')
            ->assertStatus(401);

        // Test 2: Customer cannot access provider endpoints
        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->getJson('/api/v1/provider/services')
            ->assertStatus(403);

        // Test 3: Provider cannot access customer booking endpoints
        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->getJson('/api/v1/customer/bookings')
            ->assertStatus(403);

        // Test 4: Customer cannot access another customer's booking
        $otherCustomer = User::factory()->create([
            'role' => 'customer',
            'email_verified_at' => now(),
        ]);
        $otherCustomerToken = JWTAuth::fromUser($otherCustomer);

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $otherCustomerToken,
        ])->getJson("/api/v1/customer/bookings/{$booking->id}")
            ->assertStatus(403);

        // Test 5: Provider cannot access another provider's service
        $otherProvider = User::factory()->create([
            'role' => 'serviceProvider',
            'email_verified_at' => now(),
        ]);
        $otherProviderToken = JWTAuth::fromUser($otherProvider);

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $otherProviderToken,
        ])->getJson("/api/v1/provider/services/{$service->id}")
            ->assertStatus(403);

        // Test 6: Both roles can access their own profile
        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->getJson('/api/v1/user/profile')
            ->assertStatus(200);

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->getJson('/api/v1/user/profile')
            ->assertStatus(200);
    }

    /**
     * Test error handling and validation across workflows
     * 
     * @test
     */
    public function test_error_handling_and_validation_workflow()
    {
        // Test 1: Create service with invalid data
        $invalidServiceData = [
            'name' => '', // Required field empty
            'price' => -100, // Negative price
            'duration_minutes' => 5, // Below minimum
        ];

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson('/api/v1/provider/services', $invalidServiceData)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'description', 'category', 'price', 'duration_minutes']);

        // Test 2: Create booking with invalid service_id
        $invalidBookingData = [
            'service_id' => 'non-existent-id',
            'scheduled_at' => now()->addDays(1)->toDateTimeString(),
        ];

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->postJson('/api/v1/customer/bookings', $invalidBookingData)
            ->assertStatus(422);

        // Test 3: Create booking with past date
        $service = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'status' => 'active',
        ]);

        $pastDateBooking = [
            'service_id' => $service->id,
            'scheduled_at' => now()->subDays(1)->toDateTimeString(),
        ];

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->postJson('/api/v1/customer/bookings', $pastDateBooking)
            ->assertStatus(422);

        // Test 4: Try to book inactive service
        $inactiveService = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'status' => 'inactive',
        ]);

        $inactiveServiceBooking = [
            'service_id' => $inactiveService->id,
            'scheduled_at' => now()->addDays(1)->toDateTimeString(),
        ];

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->postJson('/api/v1/customer/bookings', $inactiveServiceBooking)
            ->assertStatus(400);

        // Test 5: Try to cancel already completed booking
        $completedBooking = Booking::factory()->create([
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $service->id,
            'status' => 'completed',
        ]);

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->putJson("/api/v1/customer/bookings/{$completedBooking->id}/cancel")
            ->assertStatus(400);

        // Test 6: Try to accept already confirmed booking
        $confirmedBooking = Booking::factory()->create([
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $service->id,
            'status' => 'confirmed',
        ]);

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$confirmedBooking->id}/accept")
            ->assertStatus(400);

        // Test 7: Try to complete pending booking (must be confirmed first)
        $pendingBooking = Booking::factory()->create([
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $service->id,
            'status' => 'pending',
        ]);

        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$pendingBooking->id}/complete")
            ->assertStatus(400);

        // Test 8: Try to reject booking without reason
        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$pendingBooking->id}/reject", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['rejection_reason']);
    }

    /**
     * Test provider rejection workflow
     * 
     * @test
     */
    public function test_provider_rejection_workflow()
    {
        // Setup: Create service and booking
        $service = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'status' => 'active',
        ]);

        $booking = Booking::factory()->create([
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $service->id,
            'status' => 'pending',
        ]);

        // Provider rejects the booking with reason
        $rejectResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$booking->id}/reject", [
            'rejection_reason' => 'Not available on that date',
        ]);

        $rejectResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking rejected successfully',
                'data' => [
                    'id' => $booking->id,
                    'status' => 'rejected',
                ],
            ]);

        // Verify rejection reason is saved
        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'rejected',
            'cancellation_reason' => 'Not available on that date',
        ]);

        // Customer can view the rejected booking with reason
        $viewRejectedBooking = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->customerToken,
        ])->getJson("/api/v1/customer/bookings/{$booking->id}");

        $viewRejectedBooking->assertStatus(200)
            ->assertJson([
                'data' => [
                    'status' => 'rejected',
                    'cancellation_reason' => 'Not available on that date',
                ],
            ]);
    }

    /**
     * Test service deletion with active bookings
     * 
     * @test
     */
    public function test_service_deletion_with_active_bookings()
    {
        // Setup: Create service with active booking
        $service = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'status' => 'active',
        ]);

        $activeBooking = Booking::factory()->create([
            'customer_id' => $this->customer->id,
            'provider_id' => $this->provider->id,
            'service_id' => $service->id,
            'status' => 'confirmed',
        ]);

        // Try to delete service with active booking
        $deleteResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->deleteJson("/api/v1/provider/services/{$service->id}");

        $deleteResponse->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);

        // Service should still exist
        $this->assertDatabaseHas('services', [
            'id' => $service->id,
        ]);

        // Complete the booking
        $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->postJson("/api/v1/provider/bookings/{$activeBooking->id}/complete");

        // Now deletion should succeed (soft delete)
        $deleteAfterComplete = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->deleteJson("/api/v1/provider/services/{$service->id}");

        $deleteAfterComplete->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Service deleted successfully',
            ]);
    }

    /**
     * Test provider statistics and earnings workflow
     * 
     * @test
     */
    public function test_provider_statistics_and_earnings_workflow()
    {
        // Setup: Create multiple services and bookings
        $service1 = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'price' => 1000,
            'status' => 'active',
        ]);

        $service2 = Service::factory()->create([
            'provider_id' => $this->provider->id,
            'price' => 2000,
            'status' => 'active',
        ]);

        // Create bookings with different statuses
        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $service1->id,
            'status' => 'pending',
            'total_price' => 1000,
            'scheduled_at' => now()->addDays(5),
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $service2->id,
            'status' => 'confirmed',
            'total_price' => 2000,
            'scheduled_at' => now()->addDays(10),
        ]);

        Booking::factory()->create([
            'provider_id' => $this->provider->id,
            'customer_id' => $this->customer->id,
            'service_id' => $service1->id,
            'status' => 'completed',
            'total_price' => 1000,
            'scheduled_at' => now()->subDays(2),
        ]);

        // Test dashboard statistics
        $dashboardResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->getJson('/api/v1/provider/dashboard');

        $dashboardResponse->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'total_services',
                    'active_services',
                    'total_bookings',
                    'pending_bookings',
                    'this_month_earnings',
                    'this_month_bookings',
                ],
            ]);

        $dashboardData = $dashboardResponse->json('data');
        $this->assertEquals(2, $dashboardData['total_services']);
        $this->assertEquals(2, $dashboardData['active_services']);
        $this->assertEquals(3, $dashboardData['total_bookings']);
        $this->assertEquals(1, $dashboardData['pending_bookings']);

        // Test booking statistics
        $statsResponse = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->providerToken,
        ])->getJson('/api/v1/provider/bookings/stats');

        $statsResponse->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'total_bookings',
                    'pending_count',
                    'confirmed_count',
                    'completed_count',
                    'total_revenue',
                ],
            ]);

        $statsData = $statsResponse->json('data');
        $this->assertEquals(3, $statsData['total_bookings']);
        $this->assertEquals(1, $statsData['pending_count']);
        $this->assertEquals(1, $statsData['confirmed_count']);
        $this->assertEquals(1, $statsData['completed_count']);
        $this->assertEquals(1000, $statsData['total_revenue']); // Only completed bookings
    }
}
