<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Tymon\JWTAuth\Exceptions\TokenExpiredException;
use Tymon\JWTAuth\Exceptions\TokenInvalidException;
use App\Models\User;

class WebSocketAuthMiddleware
{
    /**
     * Handle an incoming WebSocket authentication request.
     *
     * This middleware authenticates WebSocket connections using JWT tokens.
     * Tokens can be provided via query parameter (?token=...) or Authorization header.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Extract token from query parameter or Authorization header
        $token = $this->extractToken($request);

        // Check if token is missing
        if (!$token) {
            return $this->unauthorizedResponse('Missing authentication token', 'token_absent');
        }

        try {
            // Set the token and get the payload
            $payload = JWTAuth::setToken($token)->getPayload();
            
            // Extract user ID from the 'sub' claim
            $userId = $payload->get('sub');
            
            // Find the user
            $user = User::find($userId);
            
            if (!$user) {
                return $this->unauthorizedResponse('User not found', 'user_not_found');
            }

            // Check if user is active
            if (!$user->is_active) {
                return $this->unauthorizedResponse('User account is inactive', 'user_inactive');
            }

            // Set the authenticated user in the Auth facade
            Auth::setUser($user);
            
            return $next($request);

        } catch (TokenExpiredException $e) {
            return $this->unauthorizedResponse('Token has expired', 'token_expired');

        } catch (TokenInvalidException $e) {
            return $this->unauthorizedResponse('Token is invalid', 'token_invalid');

        } catch (JWTException $e) {
            return $this->unauthorizedResponse('Token authentication failed', 'token_error');
        }
    }

    /**
     * Extract JWT token from request.
     * Checks query parameter first, then Authorization header.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return string|null
     */
    private function extractToken(Request $request): ?string
    {
        // First, try to get token from query parameter
        $token = $request->query('token');
        
        if ($token) {
            return $token;
        }

        // Second, try to get token from Authorization header
        $authHeader = $request->header('Authorization');
        
        if ($authHeader && str_starts_with($authHeader, 'Bearer ')) {
            return substr($authHeader, 7); // Remove 'Bearer ' prefix
        }

        return null;
    }

    /**
     * Return an unauthorized response.
     *
     * @param  string  $message
     * @param  string  $error
     * @return \Symfony\Component\HttpFoundation\Response
     */
    private function unauthorizedResponse(string $message, string $error): Response
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'error' => $error,
        ], 401);
    }
}
