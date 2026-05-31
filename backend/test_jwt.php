<?php

require __DIR__ . '/vendor/autoload.php';

try {
    $app = new \Illuminate\Foundation\Application(__DIR__);
    $provider = new \Tymon\JWTAuth\Providers\LaravelServiceProvider($app);
    echo "SUCCESS: JWT Service Provider loaded successfully!\n";
} catch (\Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
