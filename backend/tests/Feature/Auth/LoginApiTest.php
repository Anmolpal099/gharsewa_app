<?php

namespace Tests\Feature\Auth;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;

class LoginApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Clear rate limiter before each test
        RateLimiter::clear('login|test@example.com|127.0.0.1');
    }

    /**
     * Test successful login with valid credentials
     * 
     * @return void
     */
    public function test_login_with_valid_credentials()
    {
        // Create a test user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
            'role' => 'customer',
            'email_verified_at' => now(),
        ]);

        // Attempt login
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);

        // Assert successful response
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'access_token',
                    'refresh_token',
                    'token_type',
                    'expires_in',
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'role',
                        'email_verified_at',
                    ],
                ],
            ]);

        // Verify token type is bearer
        $this->assertEquals('bearer', $response->json('data.token_type'));

        // Verify expires_in is 3600 seconds (1 hour)
        $this->assertEquals(3600, $response->json('data.expires_in'));

        // Verify user data is correct
        $this->assertEquals($user->email, $response->json('data.user.email'));
        $this->assertEquals($user->role, $response->json('data.user.role'));

        // Verify last_login_at was updated
        $user->refresh();
        $this->assertNotNull($user->last_login_at);
        $this->assertTrue($user->last_login_at->isToday());
    }

    /**
     * Test login with invalid credentials
     * 
     * @return void
     */
    public function test_login_with_invalid_credentials()
    {
        // Create a test user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Attempt login with wrong password
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'WrongPassword',
        ]);

        // Assert unauthorized response
        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid credentials',
            ]);
    }

    /**
     * Test login with non-existent email
     * 
     * @return void
     */
    public function test_login_with_nonexistent_email()
    {
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'nonexistent@example.com',
            'password' => 'Password123',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid credentials',
            ]);
    }

    /**
     * Test login validation errors
     * 
     * @return void
     */
    public function test_login_validation_errors()
    {
        // Missing email
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'password' => 'Password123',
        ]);
        $response->assertStatus(422);

        // Missing password
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
        ]);
        $response->assertStatus(422);

        // Invalid email format
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'invalid-email',
            'password' => 'Password123',
        ]);
        $response->assertStatus(422);
    }

    /**
     * Test rate limiting (5 attempts per 15 minutes)
     * 
     * @return void
     */
    public function test_login_rate_limiting()
    {
        // Create a test user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make 5 failed login attempts
        for ($i = 0; $i < 5; $i++) {
            $response = $this->postJson('/api/v1/auth/jwt/login', [
                'email' => 'test@example.com',
                'password' => 'WrongPassword',
            ]);
            $response->assertStatus(401);
        }

        // 6th attempt should be rate limited
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(429)
            ->assertJsonStructure([
                'error',
                'message',
                'retry_after',
                'retry_after_minutes',
            ]);
    }

    /**
     * Test that successful login clears rate limit
     * 
     * @return void
     */
    public function test_successful_login_clears_rate_limit()
    {
        // Create a test user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make 4 failed attempts
        for ($i = 0; $i < 4; $i++) {
            $this->postJson('/api/v1/auth/jwt/login', [
                'email' => 'test@example.com',
                'password' => 'WrongPassword',
            ]);
        }

        // Successful login should clear the rate limit
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);
        $response->assertStatus(200);

        // Should be able to make more attempts now
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);
        $response->assertStatus(200);
    }

    /**
     * Test JWT token structure and claims
     * 
     * @return void
     */
    public function test_jwt_token_structure()
    {
        // Create a test user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
            'role' => 'customer',
        ]);

        // Login
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);

        $token = $response->json('data.access_token');

        // Verify token is a valid JWT (3 parts separated by dots)
        $parts = explode('.', $token);
        $this->assertCount(3, $parts);

        // Decode the payload (second part)
        $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1])), true);

        // Verify custom claims
        $this->assertEquals($user->role, $payload['role']);
        $this->assertEquals($user->email, $payload['email']);
        $this->assertEquals($user->name, $payload['name']);
        $this->assertEquals($user->id, $payload['sub']);

        // Verify standard claims exist
        $this->assertArrayHasKey('iss', $payload);
        $this->assertArrayHasKey('iat', $payload);
        $this->assertArrayHasKey('exp', $payload);
        $this->assertArrayHasKey('nbf', $payload);
        $this->assertArrayHasKey('jti', $payload);
    }

    /**
     * Test refresh token is created
     * 
     * @return void
     */
    public function test_refresh_token_is_created()
    {
        // Create a test user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Login
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);

        $refreshToken = $response->json('data.refresh_token');

        // Verify refresh token exists
        $this->assertNotNull($refreshToken);
        $this->assertIsString($refreshToken);
        $this->assertGreaterThan(0, strlen($refreshToken));

        // Verify refresh token is stored in database
        $this->assertDatabaseHas('refresh_tokens', [
            'user_id' => $user->id,
            'token' => $refreshToken,
            'is_revoked' => false,
        ]);
    }

    /**
     * Test rate limit headers are present
     * 
     * @return void
     */
    public function test_rate_limit_headers()
    {
        // Create a test user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make a login attempt
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);

        // Verify rate limit headers are present
        $response->assertHeader('X-RateLimit-Limit', '5');
        $this->assertTrue($response->headers->has('X-RateLimit-Remaining'));
    }
}
