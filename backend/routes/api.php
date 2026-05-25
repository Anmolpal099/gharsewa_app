<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\V1\Auth\JwtAuthController;
use App\Http\Controllers\API\V1\Auth\OtpController;
use App\Http\Controllers\API\V1\Customer\CustomerController;
use App\Http\Controllers\API\V1\Customer\BookingController as CustomerBookingController;
use App\Http\Controllers\API\V1\Provider\ProviderController;
use App\Http\Controllers\API\V1\Provider\BookingController as ProviderBookingController;
use App\Http\Controllers\API\V1\Provider\ServiceController;
use App\Http\Controllers\API\V1\Admin\AdminController;
use App\Http\Controllers\API\V1\Admin\UserManagementController;
use App\Http\Controllers\API\V1\Admin\BookingManagementController;
use App\Http\Controllers\API\V1\Ai\AiController;

/*
|--------------------------------------------------------------------------
| API Routes - Version 1 (JWT-first)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ─── Public auth (rate limited) ─────────────────────────────
    Route::prefix('auth')->middleware('api.limit:10')->group(function () {
        Route::post('jwt/register', [JwtAuthController::class, 'register']);
        Route::post('jwt/login', [JwtAuthController::class, 'login'])->middleware('login.limit');
        Route::post('jwt/refresh', [JwtAuthController::class, 'refresh']);

        Route::post('otp/send-email-verification', [OtpController::class, 'sendEmailVerificationOtp']);
        Route::post('otp/verify-email', [OtpController::class, 'verifyEmailOtp']);
        Route::post('otp/send-password-reset', [OtpController::class, 'sendPasswordResetOtp']);
        Route::post('otp/verify-password-reset', [OtpController::class, 'verifyPasswordResetOtp']);
        Route::post('otp/reset-password', [OtpController::class, 'resetPassword']);
    });

    Route::get('health', fn () => response()->json(['status' => 'ok', 'timestamp' => now()]));

    // ─── Public service browsing ────────────────────────────────
    Route::prefix('services')->group(function () {
        Route::get('/', [CustomerController::class, 'listServices']);
        Route::get('/search', [CustomerController::class, 'searchServices']);
        Route::get('/categories', [CustomerController::class, 'getCategories']);
        Route::get('/{id}', [CustomerController::class, 'getService']);
    });

    // ─── JWT protected routes ─────────────────────────────────────
    Route::middleware('jwt.auth')->group(function () {

        Route::prefix('auth/jwt')->group(function () {
            Route::post('logout', [JwtAuthController::class, 'logout']);
            Route::get('me', [JwtAuthController::class, 'me']);
            Route::post('become-service-provider', [JwtAuthController::class, 'becomeServiceProvider']);
        });

        Route::post('ai/safety-sop', [AiController::class, 'safetySop']);

        Route::prefix('profile')->group(function () {
            Route::get('/', [CustomerController::class, 'getProfile']);
            Route::put('/', [CustomerController::class, 'updateProfile']);
            Route::post('/image', [CustomerController::class, 'uploadProfileImage']);
        });

        // ─── Customer ───────────────────────────────────────────
        Route::middleware('role:customer')->prefix('customer')->group(function () {
            Route::get('dashboard', [CustomerController::class, 'dashboard']);
            Route::get('services', [CustomerController::class, 'services']);
            Route::get('services/{id}', [CustomerController::class, 'serviceDetail']);
            Route::get('recommendations', [CustomerController::class, 'recommendations']);

            Route::get('bookings/check-availability', [CustomerBookingController::class, 'checkAvailability']);
            Route::apiResource('bookings', CustomerBookingController::class);
            Route::post('bookings/{id}/cancel', [CustomerBookingController::class, 'cancel']);
        });

        // ─── Provider ───────────────────────────────────────────
        Route::middleware('role:serviceProvider')->prefix('provider')->group(function () {
            Route::get('profile', [ProviderController::class, 'getProfile']);
            Route::put('profile', [ProviderController::class, 'updateProfile']);
            Route::get('dashboard', [ProviderController::class, 'getDashboard']);
            Route::get('earnings', [ProviderController::class, 'getEarnings']);
            Route::get('metrics', [ProviderController::class, 'getMetrics']);
            Route::post('certifications/upload', [ProviderController::class, 'uploadCertification']);

            Route::get('analytics', [ProviderController::class, 'analytics']);
            Route::get('bookings', [ProviderBookingController::class, 'index']);
            Route::get('bookings/pending', [ProviderBookingController::class, 'pending']);
            Route::get('bookings/stats', [ProviderBookingController::class, 'stats']);
            Route::get('bookings/{id}', [ProviderBookingController::class, 'show']);
            Route::post('bookings/{id}/accept', [ProviderBookingController::class, 'accept']);
            Route::post('bookings/{id}/reject', [ProviderBookingController::class, 'reject']);
            Route::post('bookings/{id}/counter', [ProviderBookingController::class, 'counter']);
            Route::post('bookings/{id}/complete', [ProviderBookingController::class, 'complete']);

            Route::apiResource('services', ServiceController::class);
            Route::patch('services/{id}/status', [ServiceController::class, 'updateStatus']);
        });

        // ─── Admin ──────────────────────────────────────────────
        Route::middleware('role:admin')->prefix('admin')->group(function () {
            Route::get('dashboard', [AdminController::class, 'dashboard']);
            Route::get('analytics', [AdminController::class, 'analytics']);
            Route::get('reports', [AdminController::class, 'reports']);

            Route::apiResource('users', UserManagementController::class);
            Route::post('users/{id}/activate', [UserManagementController::class, 'activate']);
            Route::post('users/{id}/deactivate', [UserManagementController::class, 'deactivate']);
            Route::post('users/{id}/password-reset', [UserManagementController::class, 'passwordReset']);
            Route::post('users/{id}/role', [UserManagementController::class, 'setRole']);

            Route::get('bookings', [BookingManagementController::class, 'index']);
            Route::post('bookings/{id}/cancel', [BookingManagementController::class, 'cancel']);
            Route::post('bookings/{id}/note', [BookingManagementController::class, 'addNote']);
        });

        Route::prefix('test')->group(function () {
            Route::get('authenticated', function () {
                return response()->json([
                    'success' => true,
                    'message' => 'JWT authentication working',
                    'user' => auth()->user()->only(['id', 'name', 'email', 'role']),
                ]);
            });
        });
    });
});
