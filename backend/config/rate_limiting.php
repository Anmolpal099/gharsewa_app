<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Rate Limiting Configuration
    |--------------------------------------------------------------------------
    | Controls how many API requests each user can make per minute
    */

    // General API: 100 requests/minute per user
    'api'  => env('RATE_LIMIT_API', 100),

    // Auth endpoints: 10 requests/minute (brute force protection)
    'auth' => env('RATE_LIMIT_AUTH', 10),

    // Admin endpoints: 200 requests/minute
    'admin' => env('RATE_LIMIT_ADMIN', 200),
];
