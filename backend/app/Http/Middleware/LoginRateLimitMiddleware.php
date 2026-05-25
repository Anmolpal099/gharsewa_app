<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

class LoginRateLimitMiddleware
{
    /**
     * Handle an incoming request.
     * 
     * Rate limits login attempts to 5 per 15 minutes per email/IP combination.
     * This prevents brute force attacks on user accounts.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $maxAttempts = 5;
        $decayMinutes = 15;
        
        $key = $this->resolveRequestSignature($request);

        if (RateLimiter::tooManyAttempts($key, $maxAttempts)) {
            $seconds = RateLimiter::availableIn($key);
            
            return response()->json([
                'error' => 'Too Many Attempts',
                'message' => 'Too many login attempts. Please try again later.',
                'retry_after' => $seconds,
                'retry_after_minutes' => ceil($seconds / 60),
            ], 429);
        }

        $response = $next($request);

        // Only increment the rate limiter on failed login attempts (401 status)
        if ($response->status() === 401) {
            RateLimiter::hit($key, $decayMinutes * 60); // Convert minutes to seconds
        }

        // Add rate limit headers
        return $response->withHeaders([
            'X-RateLimit-Limit' => $maxAttempts,
            'X-RateLimit-Remaining' => max(0, $maxAttempts - RateLimiter::attempts($key)),
        ]);
    }

    /**
     * Resolve request signature for rate limiting.
     * 
     * Uses email (if provided) + IP address to create a unique key.
     * This prevents attackers from trying multiple emails from the same IP,
     * while also preventing distributed attacks on a single email.
     */
    protected function resolveRequestSignature(Request $request): string
    {
        $email = $request->input('email', '');
        $ip = $request->ip();
        
        return sha1('login|' . $email . '|' . $ip);
    }
}
