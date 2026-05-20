<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Kreait\Firebase\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;
use Symfony\Component\HttpFoundation\Response;

class FirebaseAuthMiddleware
{
    public function __construct(private FirebaseAuth $auth) {}

    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'No authentication token provided',
                'code'    => 'MISSING_TOKEN',
            ], 401);
        }

        try {
            // Verify Firebase ID token
            $verifiedToken = $this->auth->verifyIdToken($token);

            // Extract claims
            $uid   = $verifiedToken->claims()->get('sub');
            $role  = $verifiedToken->claims()->get('role', 'customer');
            $email = $verifiedToken->claims()->get('email');

            // Attach user info to request
            $request->merge([
                'firebase_uid'   => $uid,
                'firebase_role'  => $role,
                'firebase_email' => $email,
            ]);

            return $next($request);

        } catch (FailedToVerifyToken $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired token',
                'code'    => 'INVALID_TOKEN',
            ], 401);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Authentication failed',
                'code'    => 'AUTH_ERROR',
            ], 401);
        }
    }
}
