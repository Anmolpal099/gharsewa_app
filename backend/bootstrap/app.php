<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Console\Scheduling\Schedule;
use App\Http\Middleware\RoleMiddleware;
use App\Http\Middleware\CorsMiddleware;
use App\Http\Middleware\ApiRateLimitMiddleware;
use App\Http\Middleware\LoginRateLimitMiddleware;
use App\Http\Middleware\JwtMiddleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {

        // ── Global middleware (runs on every request) ──────────────
        $middleware->prepend(CorsMiddleware::class);

        // ── Route-level middleware aliases ─────────────────────────
        $middleware->alias([
            'jwt.auth'      => JwtMiddleware::class,
            'role'          => RoleMiddleware::class,
            'api.limit'     => ApiRateLimitMiddleware::class,
            'login.limit'   => LoginRateLimitMiddleware::class,
        ]);

        // ── API middleware group ───────────────────────────────────
        $middleware->appendToGroup('api', [
            ApiRateLimitMiddleware::class,
        ]);
    })
    ->withSchedule(function (Schedule $schedule) {
        // ── AI Analytics Generation ────────────────────────────────
        // Generate all analytics daily at midnight
        $schedule->command('ai:generate-analytics --type=all')
            ->daily()
            ->at('00:00')
            ->timezone('UTC')
            ->onSuccess(function () {
                \Illuminate\Support\Facades\Log::info('AI analytics generated successfully');
            })
            ->onFailure(function () {
                \Illuminate\Support\Facades\Log::error('AI analytics generation failed');
            });
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Return JSON for all API exceptions
        $exceptions->render(function (\Throwable $e, \Illuminate\Http\Request $request) {
            if ($request->is('api/*')) {
                $status = method_exists($e, 'getStatusCode') ? $e->getStatusCode() : 500;

                return response()->json([
                    'success' => false,
                    'message' => $e->getMessage() ?: 'Server error',
                    'code'    => $status,
                ], $status);
            }
        });
    })
    ->create();
