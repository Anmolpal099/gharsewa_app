<?php

namespace Tests\Feature\API;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;

class LoginRateLimitTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Clear rate limiter before each test
        RateLimiter::clear($this->getRateLimitKey());
    }

    protected function tearDown(): void
    {
        // Clear rate limiter after each test
        RateLimiter::clear($this->getRateLimitKey());
        
        parent::tearDown();
    }

    /**
     * Get the rate limit key for testing
     */
    protected function getRateLimitKey(): string
    {
        return sha1('login|test@example.com|127.0.0.1');
    }

    /**
     * Test that successful login does not increment rate limiter
     */
    public function test_successful_login_does_not_increment_rate_limiter(): void
    {
        // Create a user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Perform successful login
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);

        $response->assertStatus(200);
        
        // Verify rate limiter was not incremented
        $this->assertEquals(0, RateLimiter::attempts($this->getRateLimitKey()));
    }

    /**
     * Test that failed login increments rate limiter
     */
    public function test_failed_login_increments_rate_limiter(): void
    {
        // Create a user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Perform failed login
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(401);
        
        // Verify rate limiter was incremented
        $this->assertEquals(1, RateLimiter::attempts($this->getRateLimitKey()));
    }

    /**
     * Test that rate limit blocks after 5 failed attempts
     */
    public function test_rate_limit_blocks_after_five_failed_attempts(): void
    {
        // Create a user
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
            ->assertJson([
                'error' => 'Too Many Attempts',
            ])
            ->assertJsonStructure([
                'error',
                'message',
                'retry_after',
                'retry_after_minutes',
            ]);
    }

    /**
     * Test that rate limit includes proper headers
     */
    public function test_rate_limit_headers_are_present(): void
    {
        // Create a user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make a failed login attempt
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(401)
            ->assertHeader('X-RateLimit-Limit', '5')
            ->assertHeader('X-RateLimit-Remaining', '4');
    }

    /**
     * Test that rate limit is per email and IP combination
     */
    public function test_rate_limit_is_per_email_and_ip(): void
    {
        // Create two users
        User::factory()->create([
            'email' => 'user1@example.com',
            'password' => Hash::make('Password123'),
        ]);

        User::factory()->create([
            'email' => 'user2@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make 5 failed attempts for user1
        for ($i = 0; $i < 5; $i++) {
            $response = $this->postJson('/api/v1/auth/jwt/login', [
                'email' => 'user1@example.com',
                'password' => 'WrongPassword',
            ]);

            $response->assertStatus(401);
        }

        // user1 should be rate limited
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'user1@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(429);

        // user2 should still be able to attempt login (different email)
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'user2@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(401); // Not rate limited, just wrong password
    }

    /**
     * Test that successful login after failed attempts still works
     */
    public function test_successful_login_works_after_failed_attempts(): void
    {
        // Create a user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make 3 failed login attempts
        for ($i = 0; $i < 3; $i++) {
            $response = $this->postJson('/api/v1/auth/jwt/login', [
                'email' => 'test@example.com',
                'password' => 'WrongPassword',
            ]);

            $response->assertStatus(401);
        }

        // Now try with correct password
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'Password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'access_token',
                    'refresh_token',
                    'token_type',
                    'expires_in',
                    'user',
                ],
            ]);
    }

    /**
     * Test that rate limit window is 15 minutes (900 seconds)
     */
    public function test_rate_limit_window_is_fifteen_minutes(): void
    {
        // Create a user
        User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
        ]);

        // Make 5 failed login attempts to trigger rate limit
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/jwt/login', [
                'email' => 'test@example.com',
                'password' => 'WrongPassword',
            ]);
        }

        // 6th attempt should be rate limited
        $response = $this->postJson('/api/v1/auth/jwt/login', [
            'email' => 'test@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(429);
        
        // Check that retry_after is approximately 900 seconds (15 minutes)
        $retryAfter = $response->json('retry_after');
        $this->assertGreaterThanOrEqual(890, $retryAfter);
        $this->assertLessThanOrEqual(900, $retryAfter);
    }
}
