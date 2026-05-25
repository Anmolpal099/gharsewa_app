<?php

namespace Tests\Feature\API;

use Tests\TestCase;
use App\Models\User;
use App\Models\OtpVerification;
use App\Services\NodemailerService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Mockery;

class JwtAuthControllerTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test successful user registration with OTP email
     */
    public function test_user_can_register_with_valid_data()
    {
        // Mock NodemailerService to avoid actual email sending
        $nodemailerMock = Mockery::mock(NodemailerService::class);
        $nodemailerMock->shouldReceive('sendOtpEmail')
            ->once()
            ->andReturn([
                'success' => true,
                'messageId' => 'test-message-id',
            ]);
        
        $this->app->instance(NodemailerService::class, $nodemailerMock);

        // Registration data
        $registrationData = [
            'name' => 'John Doe',
            'email' => 'john.doe@example.com',
            'password' => 'Password123',
            'role' => 'customer',
        ];

        // Make registration request
        $response = $this->postJson('/api/v1/auth/jwt/register', $registrationData);

        // Assert response
        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'User registered successfully. Please check your email for the verification code.',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user_id',
                    'email',
                    'name',
                    'role',
                    'otp_sent',
                    'otp_expires_in',
                ],
            ]);

        // Assert user was created in database
        $this->assertDatabaseHas('users', [
            'email' => 'john.doe@example.com',
            'name' => 'John Doe',
            'role' => 'customer',
            'is_active' => true,
        ]);

        // Assert user email is not verified yet
        $user = User::where('email', 'john.doe@example.com')->first();
        $this->assertNull($user->email_verified_at);

        // Assert password is hashed
        $this->assertTrue(Hash::check('Password123', $user->password));

        // Assert OTP was created
        $this->assertDatabaseHas('otp_verifications', [
            'email' => 'john.doe@example.com',
            'type' => 'email_verification',
            'is_used' => false,
        ]);
    }

    /**
     * Test registration validation - missing required fields
     */
    public function test_registration_fails_with_missing_fields()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validation Error',
            ])
            ->assertJsonValidationErrors(['name', 'email', 'password', 'role']);
    }

    /**
     * Test registration validation - invalid email format
     */
    public function test_registration_fails_with_invalid_email()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'invalid-email',
            'password' => 'Password123',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /**
     * Test registration validation - duplicate email
     */
    public function test_registration_fails_with_duplicate_email()
    {
        // Create existing user
        User::factory()->create([
            'email' => 'existing@example.com',
        ]);

        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'existing@example.com',
            'password' => 'Password123',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /**
     * Test registration validation - weak password
     */
    public function test_registration_fails_with_weak_password()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'weak',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /**
     * Test registration validation - password without uppercase
     */
    public function test_registration_fails_with_password_without_uppercase()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /**
     * Test registration validation - password without lowercase
     */
    public function test_registration_fails_with_password_without_lowercase()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'PASSWORD123',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /**
     * Test registration validation - password without number
     */
    public function test_registration_fails_with_password_without_number()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'PasswordOnly',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /**
     * Test registration validation - invalid role
     */
    public function test_registration_fails_with_invalid_role()
    {
        $response = $this->postJson('/api/v1/auth/jwt/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'Password123',
            'role' => 'invalid_role',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['role']);
    }

    /**
     * Test registration succeeds even if email sending fails
     */
    public function test_registration_succeeds_even_if_email_fails()
    {
        // Mock NodemailerService to simulate email failure
        $nodemailerMock = Mockery::mock(NodemailerService::class);
        $nodemailerMock->shouldReceive('sendOtpEmail')
            ->once()
            ->andReturn([
                'success' => false,
                'error' => 'SMTP connection failed',
            ]);
        
        $this->app->instance(NodemailerService::class, $nodemailerMock);

        $registrationData = [
            'name' => 'Jane Doe',
            'email' => 'jane.doe@example.com',
            'password' => 'Password123',
            'role' => 'serviceProvider',
        ];

        $response = $this->postJson('/api/v1/auth/jwt/register', $registrationData);

        // Registration should still succeed
        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        // User should be created
        $this->assertDatabaseHas('users', [
            'email' => 'jane.doe@example.com',
        ]);

        // OTP should be created
        $this->assertDatabaseHas('otp_verifications', [
            'email' => 'jane.doe@example.com',
            'type' => 'email_verification',
        ]);
    }

    /**
     * Test registration with service provider role
     */
    public function test_user_can_register_as_service_provider()
    {
        // Mock NodemailerService
        $nodemailerMock = Mockery::mock(NodemailerService::class);
        $nodemailerMock->shouldReceive('sendOtpEmail')
            ->once()
            ->andReturn(['success' => true]);
        
        $this->app->instance(NodemailerService::class, $nodemailerMock);

        $registrationData = [
            'name' => 'Service Provider',
            'email' => 'provider@example.com',
            'password' => 'Password123',
            'role' => 'serviceProvider',
        ];

        $response = $this->postJson('/api/v1/auth/jwt/register', $registrationData);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'email' => 'provider@example.com',
            'role' => 'serviceProvider',
        ]);
    }

    /**
     * Clean up Mockery after each test
     */
    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}
