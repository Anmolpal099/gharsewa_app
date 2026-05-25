<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tymon\JWTAuth\Facades\JWTAuth;

class MiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Run migrations
        $this->artisan('migrate');
    }

    /**
     * Test JWT middleware blocks unauthenticated requests
     */
    public function test_jwt_middleware_blocks_unauthenticated_requests()
    {
        $response = $this->getJson('/api/v1/test/authenticated');

        $response->assertStatus(401)
                 ->assertJson([
                     'success' => false,
                     'message' => 'Token not provided',
                 ]);
    }

    /**
     * Test JWT middleware allows authenticated requests
     */
    public function test_jwt_middleware_allows_authenticated_requests()
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'is_active' => true,
        ]);

        $token = JWTAuth::fromUser($user);

        $response = $this->getJson('/api/v1/test/authenticated', [
            'Authorization' => 'Bearer ' . $token,
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => 'JWT authentication working',
                 ]);
    }

    /**
     * Test JWT middleware blocks inactive users
     */
    public function test_jwt_middleware_blocks_inactive_users()
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'is_active' => false,
        ]);

        $token = JWTAuth::fromUser($user);

        $response = $this->getJson('/api/v1/test/authenticated', [
            'Authorization' => 'Bearer ' . $token,
        ]);

        $response->assertStatus(403)
                 ->assertJson([
                     'success' => false,
                     'message' => 'User account is inactive',
                 ]);
    }

    /**
     * Test role middleware allows correct role
     */
    public function test_role_middleware_allows_correct_role()
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'is_active' => true,
        ]);

        $token = JWTAuth::fromUser($user);

        $response = $this->getJson('/api/v1/test/customer-only', [
            'Authorization' => 'Bearer ' . $token,
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => 'Customer role middleware working',
                 ]);
    }

    /**
     * Test role middleware blocks wrong role
     */
    public function test_role_middleware_blocks_wrong_role()
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'is_active' => true,
        ]);

        $token = JWTAuth::fromUser($user);

        $response = $this->getJson('/api/v1/test/admin-only', [
            'Authorization' => 'Bearer ' . $token,
        ]);

        $response->assertStatus(403)
                 ->assertJson([
                     'success' => false,
                     'message' => 'You do not have permission to access this resource',
                     'required_roles' => ['admin'],
                     'your_role' => 'customer',
                 ]);
    }

    /**
     * Test role middleware with multiple allowed roles
     */
    public function test_role_middleware_with_multiple_roles()
    {
        // Test with customer
        $customer = User::factory()->create([
            'role' => 'customer',
            'is_active' => true,
        ]);

        $customerToken = JWTAuth::fromUser($customer);

        $response = $this->getJson('/api/v1/test/customer-or-provider', [
            'Authorization' => 'Bearer ' . $customerToken,
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                 ]);

        // Test with service provider
        $provider = User::factory()->create([
            'role' => 'serviceProvider',
            'is_active' => true,
        ]);

        $providerToken = JWTAuth::fromUser($provider);

        $response = $this->getJson('/api/v1/test/customer-or-provider', [
            'Authorization' => 'Bearer ' . $providerToken,
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                 ]);

        // Test with admin (should fail)
        $admin = User::factory()->create([
            'role' => 'admin',
            'is_active' => true,
        ]);

        $adminToken = JWTAuth::fromUser($admin);

        $response = $this->getJson('/api/v1/test/customer-or-provider', [
            'Authorization' => 'Bearer ' . $adminToken,
        ]);

        $response->assertStatus(403);
    }

    /**
     * Test all role-specific endpoints
     */
    public function test_all_role_specific_endpoints()
    {
        $roles = [
            'customer' => '/api/v1/test/customer-only',
            'serviceProvider' => '/api/v1/test/provider-only',
            'admin' => '/api/v1/test/admin-only',
        ];

        foreach ($roles as $role => $endpoint) {
            $user = User::factory()->create([
                'role' => $role,
                'is_active' => true,
            ]);

            $token = JWTAuth::fromUser($user);

            // Should succeed with correct role
            $response = $this->getJson($endpoint, [
                'Authorization' => 'Bearer ' . $token,
            ]);

            $response->assertStatus(200)
                     ->assertJson([
                         'success' => true,
                     ]);

            // Should fail with other endpoints
            foreach ($roles as $otherRole => $otherEndpoint) {
                if ($otherRole !== $role) {
                    $response = $this->getJson($otherEndpoint, [
                        'Authorization' => 'Bearer ' . $token,
                    ]);

                    $response->assertStatus(403);
                }
            }
        }
    }
}
