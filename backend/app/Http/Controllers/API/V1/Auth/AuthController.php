<?php

namespace App\Http\Controllers\API\V1\Auth;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\User;
use App\Services\Auth\FirebaseAuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends BaseController
{
    public function __construct(private FirebaseAuthService $authService) {}

    /**
     * Verify Firebase token and sync user to DB
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate(['id_token' => 'required|string']);

        try {
            $user = $this->authService->loginWithFirebaseToken($request->id_token);
            return $this->success($user, 'Login successful');
        } catch (\Exception $e) {
            return $this->error('Authentication failed: ' . $e->getMessage(), 401);
        }
    }

    /**
     * Register new user (syncs Firebase user to DB)
     */
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'id_token' => 'required|string',
            'name'     => 'required|string|min:2|max:100',
            'role'     => 'required|in:customer,serviceProvider',
        ]);

        try {
            $user = $this->authService->registerUser(
                $request->id_token,
                $request->name,
                $request->role
            );
            return $this->success($user, 'Registration successful', 201);
        } catch (\Exception $e) {
            return $this->error('Registration failed: ' . $e->getMessage(), 400);
        }
    }

    /**
     * Get current authenticated user
     */
    public function me(Request $request): JsonResponse
    {
        $user = User::where('firebase_uid', $request->firebase_uid)->first();

        if (!$user) {
            return $this->error('User not found', 404);
        }

        return $this->success($user);
    }

    /**
     * Logout (update last login timestamp)
     */
    public function logout(Request $request): JsonResponse
    {
        User::where('firebase_uid', $request->firebase_uid)
            ->update(['last_login_at' => now()]);

        return $this->success(null, 'Logged out successfully');
    }

    /**
     * Verify token validity (used by Flutter to check token)
     */
    public function verifyToken(Request $request): JsonResponse
    {
        $request->validate(['id_token' => 'required|string']);

        try {
            $result = $this->authService->verifyToken($request->id_token);
            return $this->success($result, 'Token is valid');
        } catch (\Exception $e) {
            return $this->error('Invalid token', 401);
        }
    }
}
