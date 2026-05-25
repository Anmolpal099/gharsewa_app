<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    | Allows Flutter mobile and web apps to communicate with the API
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'http://localhost',        // Flutter web dev (any port)
        'http://localhost:3000',   // Flutter web dev
        'http://localhost:8080',   // Flutter web dev alt
        'http://127.0.0.1',        // Local development
        'https://gharsewa.com',    // Production web
        'https://admin.gharsewa.com', // Admin panel
    ],

    'allowed_origins_patterns' => [
        '/^http:\/\/localhost(:\d+)?$/',  // Match localhost with any port
        '/^http:\/\/127\.0\.0\.1(:\d+)?$/', // Match 127.0.0.1 with any port
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [
        'X-RateLimit-Limit',
        'X-RateLimit-Remaining',
    ],

    'max_age' => 86400,

    'supports_credentials' => false,
];
