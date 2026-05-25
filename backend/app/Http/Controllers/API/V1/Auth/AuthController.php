<?php

namespace App\Http\Controllers\API\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AuthController extends Controller
{
    /**
     * Register a new user
     * TODO: Implement JWT-based registration in Task 2
     */
    public function register(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Registration endpoint not yet implemented. Firebase dependencies removed.'
        ], 501);
    }

    /**
     * Login user
     * TODO: Implement JWT-based login in Task 2
     */
    public function login(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Login endpoint not yet implemented. Firebase dependencies removed.'
        ], 501);
    }

    /**
     * Verify token
     * TODO: Implement JWT token verification in Task 2
     */
    public function verifyToken(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Token verification not yet implemented. Firebase dependencies removed.'
        ], 501);
    }

    /**
     * Logout user
     * TODO: Implement JWT logout in Task 2
     */
    public function logout(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Logout endpoint not yet implemented. Firebase dependencies removed.'
        ], 501);
    }

    /**
     * Get current user info
     * TODO: Implement JWT-based user retrieval in Task 2
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'User info endpoint not yet implemented. Firebase dependencies removed.'
        ], 501);
    }

    /**
     * Update user role (Admin only)
     * TODO: Implement JWT-based role update in Task 2
     */
    public function updateRole(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Role update endpoint not yet implemented. Firebase dependencies removed.'
        ], 501);
    }
}
