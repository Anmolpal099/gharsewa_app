<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, string $role): Response
    {
        $userRole = $request->get('firebase_role', 'customer');

        if ($userRole !== $role) {
            return response()->json([
                'success' => false,
                'message' => "Access denied. Required role: {$role}",
                'code'    => 'FORBIDDEN',
            ], 403);
        }

        return $next($request);
    }
}
