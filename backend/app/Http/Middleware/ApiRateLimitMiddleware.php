<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Cache\RateLimiter;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiRateLimitMiddleware
{
    public function __construct(private RateLimiter $limiter) {}

    public function handle(Request $request, Closure $next, int $maxAttempts = 100): Response
    {
        // Key: user UID or IP address
        $key = $request->get('firebase_uid', $request->ip());

        if ($this->limiter->tooManyAttempts($key, $maxAttempts)) {
            $retryAfter = $this->limiter->availableIn($key);

            return response()->json([
                'success' => false,
                'message' => 'Too many requests. Please try again later.',
                'code'    => 'RATE_LIMIT_EXCEEDED',
                'retry_after' => $retryAfter,
            ], 429)->header('Retry-After', $retryAfter);
        }

        $this->limiter->hit($key, 60); // 60 second window

        $response = $next($request);

        $response->headers->set('X-RateLimit-Limit', $maxAttempts);
        $response->headers->set('X-RateLimit-Remaining', $this->limiter->remaining($key, $maxAttempts));

        return $response;
    }
}
