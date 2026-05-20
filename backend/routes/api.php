<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\V1\Auth\AuthController;
use App\Http\Controllers\API\V1\Customer\CustomerController;
use App\Http\Controllers\API\V1\Customer\BookingController as CustomerBookingController;
use App\Http\Controllers\API\V1\Provider\ProviderController;
use App\Http\Controllers\API\V1\Provider\BookingController as ProviderBookingController;
use App\Http\Controllers\API\V1\Provider\ServiceController;
use App\Http\Controllers\API\V1\Admin\AdminController;
use App\Http\Controllers\API\V1\Admin\UserManagementController;
use App\Http\Controllers\API\V1\Admin\BookingManagementController;

/*
|--------------------------------------------------------------------------
| API Routes - Version 1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ─── Public Routes (rate limited to 10/min for auth) ─────────
    Route::prefix('auth')->middleware('api.limit:10')->group(function () {
        Route::post('login', [AuthController::class, 'login']);
        Route::post('register', [AuthController::class, 'register']);
        Route::post('verify-token', [AuthController::class, 'verifyToken']);
    });

    // Health check
    Route::get('health', fn() => response()->json(['status' => 'ok', 'timestamp' => now()]));

    // ─── Protected Routes (Firebase Auth required) ────────────────
    Route::middleware('firebase.auth')->group(function () {

        // Auth
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('auth/me', [AuthController::class, 'me']);

        // ─── Customer Routes ──────────────────────────────────────
        Route::middleware('role:customer')->prefix('customer')->group(function () {
            Route::get('dashboard', [CustomerController::class, 'dashboard']);
            Route::get('services', [CustomerController::class, 'services']);
            Route::get('services/{id}', [CustomerController::class, 'serviceDetail']);
            Route::get('recommendations', [CustomerController::class, 'recommendations']);

            // Bookings
            Route::apiResource('bookings', CustomerBookingController::class);
            Route::post('bookings/{id}/cancel', [CustomerBookingController::class, 'cancel']);
        });

        // ─── Service Provider Routes ──────────────────────────────
        Route::middleware('role:serviceProvider')->prefix('provider')->group(function () {
            Route::get('dashboard', [ProviderController::class, 'dashboard']);
            Route::get('analytics', [ProviderController::class, 'analytics']);
            Route::get('earnings', [ProviderController::class, 'earnings']);

            // Bookings
            Route::get('bookings', [ProviderBookingController::class, 'index']);
            Route::post('bookings/{id}/accept', [ProviderBookingController::class, 'accept']);
            Route::post('bookings/{id}/reject', [ProviderBookingController::class, 'reject']);
            Route::post('bookings/{id}/complete', [ProviderBookingController::class, 'complete']);

            // Services
            Route::apiResource('services', ServiceController::class);
            Route::post('services/{id}/toggle', [ServiceController::class, 'toggle']);
        });

        // ─── Admin Routes ─────────────────────────────────────────
        Route::middleware('role:admin')->prefix('admin')->group(function () {
            Route::get('dashboard', [AdminController::class, 'dashboard']);
            Route::get('analytics', [AdminController::class, 'analytics']);
            Route::get('reports', [AdminController::class, 'reports']);

            // User Management
            Route::apiResource('users', UserManagementController::class);
            Route::post('users/{id}/activate', [UserManagementController::class, 'activate']);
            Route::post('users/{id}/deactivate', [UserManagementController::class, 'deactivate']);
            Route::post('users/{id}/role', [UserManagementController::class, 'setRole']);

            // Booking Management
            Route::get('bookings', [BookingManagementController::class, 'index']);
            Route::post('bookings/{id}/cancel', [BookingManagementController::class, 'cancel']);
            Route::post('bookings/{id}/note', [BookingManagementController::class, 'addNote']);
        });
    });
});
