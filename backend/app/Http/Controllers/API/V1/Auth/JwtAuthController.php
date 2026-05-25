<?php

namespace App\Http\Controllers\API\V1\Auth;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\User;
use App\Models\RefreshToken;
use App\Models\OtpVerification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Tymon\JWTAuth\Facades\JWTAuth;

class JwtAuthController extends BaseController
{
    /**
     * Register a new user
     * 
     * Creates a new user account and sends OTP verification email via Laravel Mail.
     * User must verify email before they can fully access the system.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
        // Validate registration data
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255',
            'password' => 'required|string|min:8|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/',
            'role' => 'required|in:customer,serviceProvider',
        ]);

        if ($validator->fails()) {
            return $this->error('Validation Error', 422, $validator->errors());
        }

        try {
            // Check if email already exists (including soft-deleted records)
            $existingUser = User::withTrashed()->where('email', $request->email)->first();
            
            if ($existingUser) {
                // If user exists and email is verified, reject registration
                if ($existingUser->email_verified_at !== null) {
                    return $this->error('Email already registered and verified. Please login.', 422);
                }
                
                // If user exists but email is NOT verified, permanently delete the old account
                // This allows users to re-register if they never verified their email
                Log::info('Deleting unverified user account to allow re-registration', [
                    'user_id' => $existingUser->id,
                    'email' => $existingUser->email,
                    'was_soft_deleted' => $existingUser->trashed(),
                ]);
                
                // Delete related OTP records
                OtpVerification::where('email', $existingUser->email)->delete();
                
                // Permanently delete the unverified user (works for both soft-deleted and active records)
                $existingUser->forceDelete();
            }
            
            // Create user account
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role, // Keep for backward compatibility
                'roles' => [$request->role], // New: Store as array
                'is_active' => true,
                'email_verified_at' => null, // Email not verified yet
            ]);

            // Generate OTP for email verification
            $otpRecord = OtpVerification::createForEmailVerification($user->email);

            // Send OTP via Laravel Mail
            try {
                Mail::send('emails.otp-verification', [
                    'name' => $user->name,
                    'otp' => $otpRecord->otp,
                    'expiryMinutes' => 10
                ], function ($message) use ($user) {
                    $message->to($user->email)
                            ->subject('Verify Your Email - Gharsewa');
                });

                Log::info('OTP email sent successfully during registration', [
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'otp' => $otpRecord->otp, // Remove in production
                ]);

            } catch (\Exception $emailException) {
                Log::error('Exception while sending OTP email during registration', [
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'exception' => $emailException->getMessage(),
                ]);
                
                // Don't fail registration if email fails
            }

            return $this->success([
                'user_id' => $user->id,
                'email' => $user->email,
                'name' => $user->name,
                'role' => $user->role,
                'otp_sent' => true,
                'otp_expires_in' => 600, // 10 minutes in seconds
            ], 'User registered successfully. Please check your email for the verification code.');

        } catch (\Exception $e) {
            Log::error('Registration failed', [
                'email' => $request->email,
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error(
                'Registration failed. Please try again.',
                500,
                config('app.debug') ? ['exception' => $e->getMessage()] : null
            );
        }
    }

    /**
     * Login user and return JWT tokens
     * 
     * Implements rate limiting: 5 attempts per 15 minutes per IP
     */
    public function login(Request $request)
    {
        // Rate limiting
        $key = 'login:' . $request->ip();
        
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);
            return $this->error(
                "Too many login attempts. Please try again in {$seconds} seconds.",
                429
            );
        }

        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->error('Validation Error', 422, $validator->errors());
        }

        $credentials = $request->only('email', 'password');

        if (!$token = auth()->attempt($credentials)) {
            RateLimiter::hit($key, 900); // 15 minutes
            return $this->error('Invalid credentials', 401);
        }

        RateLimiter::clear($key);

        $user = auth()->user();

        // Update last login timestamp
        $user->update(['last_login_at' => now()]);

        // Generate refresh token
        $refreshToken = $this->createRefreshToken($user, $request);

        return $this->success([
            'access_token' => $token,
            'refresh_token' => $refreshToken->token,
            'token_type' => 'bearer',
            'expires_in' => auth()->factory()->getTTL() * 60, // in seconds
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'roles' => $user->roles ?? [$user->role],
                'email_verified_at' => $user->email_verified_at,
            ],
        ], 'Login successful');
    }

    /**
     * Logout user (invalidate token)
     */
    public function logout(Request $request)
    {
        $user = auth()->user();

        // Revoke refresh token if provided
        if ($request->has('refresh_token')) {
            RefreshToken::where('user_id', $user->id)
                ->where('token', $request->refresh_token)
                ->update(['is_revoked' => true]);
        }

        auth()->logout();

        return $this->success([], 'Successfully logged out');
    }

    /**
     * Refresh access token using refresh token
     */
    public function refresh(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'refresh_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->error('Validation Error', 422, $validator->errors());
        }

        $refreshToken = RefreshToken::where('token', $request->refresh_token)
            ->where('is_revoked', false)
            ->first();

        if (!$refreshToken) {
            return $this->error('Invalid refresh token', 401);
        }

        if ($refreshToken->isExpired()) {
            return $this->error('Refresh token expired', 401);
        }

        $user = $refreshToken->user;

        // Generate new access token
        $token = auth()->login($user);

        // Optionally rotate refresh token (create new one and revoke old)
        $refreshToken->revoke();
        $newRefreshToken = $this->createRefreshToken($user, $request);

        return $this->success([
            'access_token' => $token,
            'refresh_token' => $newRefreshToken->token,
            'token_type' => 'bearer',
            'expires_in' => auth()->factory()->getTTL() * 60,
        ], 'Token refreshed successfully');
    }

    /**
     * Get authenticated user details
     */
    public function me()
    {
        $user = auth()->user();

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->getPrimaryRole(),
            'roles' => $user->roles,
            'phone_number' => $user->phone_number,
            'profile_image_url' => $user->profile_image_url,
            'is_active' => $user->is_active,
            'email_verified_at' => $user->email_verified_at,
            'last_login_at' => $user->last_login_at,
        ], 'User details retrieved successfully');
    }

    /**
     * Add service provider role to existing customer account
     * Allows customers to also become service providers
     */
    public function becomeServiceProvider(Request $request)
    {
        $user = auth()->user();

        // Check if user is already a service provider
        if ($user->isServiceProvider()) {
            return $this->error('You are already a service provider', 400);
        }

        // Add service provider role
        $user->addRole('serviceProvider');

        // Update primary role if needed
        if ($user->role === 'customer') {
            $user->role = 'serviceProvider';
            $user->save();
        }

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->getPrimaryRole(),
            'roles' => $user->roles,
        ], 'Successfully upgraded to service provider. You can now offer services!');
    }

    /**
     * Create a refresh token for the user
     */
    private function createRefreshToken(User $user, Request $request): RefreshToken
    {
        return RefreshToken::create([
            'user_id' => $user->id,
            'token' => Str::random(64),
            'expires_at' => now()->addDays(30),
            'device_info' => $request->header('User-Agent'),
            'ip_address' => $request->ip(),
        ]);
    }
}
