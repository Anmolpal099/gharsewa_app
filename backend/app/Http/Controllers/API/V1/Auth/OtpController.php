<?php

namespace App\Http\Controllers\API\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\OtpVerification;
use App\Models\User;
use App\Models\RefreshToken;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class OtpController extends Controller
{
    /**
     * Send OTP for email verification
     */
    public function sendEmailVerificationOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        try {
            $otp = OtpVerification::createForEmailVerification($request->email);

            // Send OTP via email
            $this->sendOtpEmail($request->email, $otp->otp, 'Email Verification');

            return response()->json([
                'success' => true,
                'message' => 'OTP sent to your email',
                'expires_in' => 600, // 10 minutes in seconds
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to send email verification OTP: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to send OTP',
                'error' => config('app.debug') ? $e->getMessage() : 'Please try again'
            ], 500);
        }
    }

    /**
     * Verify email OTP and return JWT tokens
     */
    public function verifyEmailOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $isValid = OtpVerification::verify(
            $request->email,
            $request->otp,
            'email_verification'
        );

        if (!$isValid) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ], 400);
        }

        // Mark user as email verified in database
        $user = User::where('email', $request->email)->first();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        $user->update(['email_verified_at' => now()]);
        
        // Generate JWT tokens
        $token = auth()->login($user);
        $refreshToken = $this->createRefreshToken($user, $request);
        
        // Send welcome email
        try {
            Mail::send('emails.welcome', [
                'name' => $user->name
            ], function ($message) use ($user) {
                $message->to($user->email)
                        ->subject('Welcome to Gharsewa!');
            });
            
            Log::info('Welcome email sent', ['user_id' => $user->id]);
        } catch (\Exception $e) {
            Log::error('Failed to send welcome email', [
                'user_id' => $user->id,
                'error' => $e->getMessage()
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Email verified successfully',
            'data' => [
                'access_token' => $token,
                'refresh_token' => $refreshToken->token,
                'token_type' => 'bearer',
                'expires_in' => auth()->factory()->getTTL() * 60,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'email_verified_at' => $user->email_verified_at,
                ],
            ],
        ]);
    }

    /**
     * Send OTP for password reset
     */
    public function sendPasswordResetOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        // Check if user exists in Laravel database
        $user = User::where('email', $request->email)->first();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'No account found with this email',
            ], 404);
        }

        try {
            $otp = OtpVerification::createForPasswordReset($request->email);

            // Send OTP via email
            $this->sendOtpEmail($request->email, $otp->otp, 'Password Reset');

            return response()->json([
                'success' => true,
                'message' => 'OTP sent to your email',
                'expires_in' => 600, // 10 minutes in seconds
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to send password reset OTP: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to send OTP',
                'error' => config('app.debug') ? $e->getMessage() : 'Please try again'
            ], 500);
        }
    }

    /**
     * Verify password reset OTP
     */
    public function verifyPasswordResetOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $isValid = OtpVerification::verify(
            $request->email,
            $request->otp,
            'password_reset'
        );

        if (!$isValid) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP verified successfully',
            'data' => [
                'email' => $request->email,
                'can_reset_password' => true,
            ]
        ]);
    }

    /**
     * Reset password with verified OTP
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
            'new_password' => 'required|string|min:8|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/',
        ]);

        // Verify OTP again
        $isValid = OtpVerification::verify(
            $request->email,
            $request->otp,
            'password_reset'
        );

        if (!$isValid) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ], 400);
        }

        try {
            // Update password in Laravel database
            $user = User::where('email', $request->email)->first();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found',
                ], 404);
            }

            $user->update([
                'password' => bcrypt($request->new_password),
                'updated_at' => now(),
            ]);

            // Invalidate all refresh tokens for security
            RefreshToken::where('user_id', $user->id)->update(['is_revoked' => true]);
            
            Log::info('Password reset successful, all refresh tokens revoked', [
                'user_id' => $user->id
            ]);
            
            // Send password changed confirmation email
            try {
                Mail::send('emails.password-changed', [
                    'name' => $user->name
                ], function ($message) use ($user) {
                    $message->to($user->email)
                            ->subject('Password Changed Successfully - Gharsewa');
                });
                
                Log::info('Password changed email sent', ['user_id' => $user->id]);
            } catch (\Exception $e) {
                Log::error('Failed to send password changed email', [
                    'user_id' => $user->id,
                    'error' => $e->getMessage()
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Password reset successful. Please login with your new password.',
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to reset password: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to reset password',
                'error' => config('app.debug') ? $e->getMessage() : 'Please try again'
            ], 500);
        }
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

    /**
     * Send OTP email using Laravel Mail
     */
    private function sendOtpEmail(string $email, string $otp, string $purpose): void
    {
        try {
            $user = User::where('email', $email)->first();
            $userName = $user ? $user->name : 'User';
            
            if ($purpose === 'Email Verification') {
                Mail::send('emails.otp-verification', [
                    'name' => $userName,
                    'otp' => $otp,
                    'expiryMinutes' => 10
                ], function ($message) use ($email) {
                    $message->to($email)
                            ->subject('Verify Your Email - Gharsewa');
                });
            } else {
                Mail::send('emails.password-reset', [
                    'name' => $userName,
                    'otp' => $otp,
                    'expiryMinutes' => 10
                ], function ($message) use ($email) {
                    $message->to($email)
                            ->subject('Reset Your Password - Gharsewa');
                });
            }
            
            Log::info("OTP Email sent successfully", [
                'to' => $email,
                'purpose' => $purpose,
                'otp' => $otp // Remove in production
            ]);
            
        } catch (\Exception $e) {
            Log::error("Failed to send OTP email", [
                'email' => $email,
                'purpose' => $purpose,
                'error' => $e->getMessage()
            ]);
            // Don't throw exception, OTP is logged for development
        }
    }
}
