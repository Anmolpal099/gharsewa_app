<?php

namespace Tests\Feature\Auth;

use Tests\TestCase;
use App\Models\User;
use App\Models\OtpVerification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class OtpVerificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Fake mail to prevent actual emails from being sent
        Mail::fake();
    }

    /**
     * Test successful email verification with OTP returns JWT tokens
     * 
     * @return void
     */
    public function test_verify_email_otp_returns_jwt_tokens()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('Password123'),
            'role' => 'customer',
            'email_verified_at' => null, // Not verified yet
        ]);

        // Create OTP for email verification
        $otp = OtpVerification::createForEmailVerification($user->email);

        // Verify email with OTP
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
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

        // Verify email_verified_at is set
        $user->refresh();
        $this->assertNotNull($user->email_verified_at);
        $this->assertTrue($user->email_verified_at->isToday());

        // Verify access token is a valid JWT
        $token = $response->json('data.access_token');
        $parts = explode('.', $token);
        $this->assertCount(3, $parts);

        // Verify refresh token is created in database
        $refreshToken = $response->json('data.refresh_token');
        $this->assertDatabaseHas('refresh_tokens', [
            'user_id' => $user->id,
            'token' => $refreshToken,
            'is_revoked' => false,
        ]);
    }

    /**
     * Test email verification with invalid OTP
     * 
     * @return void
     */
    public function test_verify_email_with_invalid_otp()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'email_verified_at' => null,
        ]);

        // Create OTP
        OtpVerification::createForEmailVerification($user->email);

        // Attempt verification with wrong OTP
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => '999999', // Wrong OTP
        ]);

        // Assert error response
        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ]);

        // Verify email is still not verified
        $user->refresh();
        $this->assertNull($user->email_verified_at);
    }

    /**
     * Test email verification with expired OTP
     * 
     * @return void
     */
    public function test_verify_email_with_expired_otp()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'email_verified_at' => null,
        ]);

        // Create OTP and manually expire it
        $otp = OtpVerification::createForEmailVerification($user->email);
        $otp->update(['expires_at' => now()->subMinutes(1)]);

        // Attempt verification with expired OTP
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
        ]);

        // Assert error response
        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ]);

        // Verify email is still not verified
        $user->refresh();
        $this->assertNull($user->email_verified_at);
    }

    /**
     * Test email verification with non-existent user
     * 
     * @return void
     */
    public function test_verify_email_with_nonexistent_user()
    {
        // Create OTP for non-existent user
        $otp = OtpVerification::create([
            'email' => 'nonexistent@example.com',
            'otp' => '123456',
            'type' => 'email_verification',
            'expires_at' => now()->addMinutes(10),
        ]);

        // Attempt verification
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => 'nonexistent@example.com',
            'otp' => $otp->otp,
        ]);

        // Assert error response
        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'User not found',
            ]);
    }

    /**
     * Test email verification validation errors
     * 
     * @return void
     */
    public function test_verify_email_validation_errors()
    {
        // Missing email
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'otp' => '123456',
        ]);
        $response->assertStatus(422);

        // Missing OTP
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => 'test@example.com',
        ]);
        $response->assertStatus(422);

        // Invalid email format
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => 'invalid-email',
            'otp' => '123456',
        ]);
        $response->assertStatus(422);

        // OTP not 6 characters
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => 'test@example.com',
            'otp' => '12345', // Only 5 characters
        ]);
        $response->assertStatus(422);
    }

    /**
     * Test that already verified user can still verify again (idempotent)
     * 
     * @return void
     */
    public function test_verify_already_verified_email()
    {
        // Create a verified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'email_verified_at' => now()->subDay(), // Already verified
        ]);

        // Create new OTP
        $otp = OtpVerification::createForEmailVerification($user->email);

        // Verify email again
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
        ]);

        // Should still succeed and return tokens
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'access_token',
                    'refresh_token',
                    'token_type',
                    'expires_in',
                    'user',
                ],
            ]);

        // Verify email_verified_at is updated
        $user->refresh();
        $this->assertNotNull($user->email_verified_at);
        $this->assertTrue($user->email_verified_at->isToday());
    }

    /**
     * Test JWT token contains correct user claims
     * 
     * @return void
     */
    public function test_jwt_token_contains_correct_claims()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'name' => 'Test User',
            'role' => 'customer',
            'email_verified_at' => null,
        ]);

        // Create OTP
        $otp = OtpVerification::createForEmailVerification($user->email);

        // Verify email
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
        ]);

        $token = $response->json('data.access_token');

        // Decode the payload
        $parts = explode('.', $token);
        $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1])), true);

        // Verify custom claims
        $this->assertEquals($user->role, $payload['role']);
        $this->assertEquals($user->email, $payload['email']);
        $this->assertEquals($user->name, $payload['name']);
        $this->assertEquals($user->id, $payload['sub']);
    }

    /**
     * Test refresh token has correct expiry (30 days)
     * 
     * @return void
     */
    public function test_refresh_token_has_correct_expiry()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'email_verified_at' => null,
        ]);

        // Create OTP
        $otp = OtpVerification::createForEmailVerification($user->email);

        // Verify email
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
        ]);

        $refreshToken = $response->json('data.refresh_token');

        // Get refresh token from database
        $tokenRecord = \App\Models\RefreshToken::where('token', $refreshToken)->first();

        // Verify expiry is approximately 30 days from now
        $expectedExpiry = now()->addDays(30);
        $this->assertTrue(
            $tokenRecord->expires_at->diffInMinutes($expectedExpiry) < 1,
            'Refresh token expiry should be 30 days from now'
        );
    }

    /**
     * Test OTP is deleted after successful verification
     * 
     * @return void
     */
    public function test_otp_is_deleted_after_verification()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'email_verified_at' => null,
        ]);

        // Create OTP
        $otp = OtpVerification::createForEmailVerification($user->email);

        // Verify email
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
        ]);

        $response->assertStatus(200);

        // Verify OTP is deleted from database
        $this->assertDatabaseMissing('otp_verifications', [
            'id' => $otp->id,
        ]);
    }

    /**
     * Test welcome email is sent after verification
     * 
     * @return void
     */
    public function test_welcome_email_is_sent_after_verification()
    {
        // Create an unverified user
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'name' => 'Test User',
            'email_verified_at' => null,
        ]);

        // Create OTP
        $otp = OtpVerification::createForEmailVerification($user->email);

        // Verify email
        $response = $this->postJson('/api/v1/auth/otp/verify-email', [
            'email' => $user->email,
            'otp' => $otp->otp,
        ]);

        $response->assertStatus(200);

        // Assert welcome email was sent
        Mail::assertSent(\Illuminate\Mail\Mailable::class, function ($mail) use ($user) {
            return $mail->hasTo($user->email);
        });
    }
}
