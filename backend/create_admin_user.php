<?php

/**
 * Create an admin user without tinker.
 *
 * Usage (from backend folder):
 *   docker-compose exec app php create_admin_user.php
 *   docker-compose exec app php create_admin_user.php admin@gharsewa.com "Admin User" "Password123"
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

$email = $argv[1] ?? 'admin@gharsewa.com';
$name = $argv[2] ?? 'Admin User';
$password = $argv[3] ?? 'Password123';

$existing = User::where('email', $email)->first();

if ($existing) {
    $existing->update([
        'name' => $name,
        'password' => Hash::make($password),
        'role' => 'admin',
        'roles' => ['admin'],
        'is_active' => true,
        'email_verified_at' => $existing->email_verified_at ?? now(),
    ]);
    echo "Updated existing user to admin: {$email}\n";
    exit(0);
}

$user = User::create([
    'name' => $name,
    'email' => $email,
    'password' => Hash::make($password),
    'role' => 'admin',
    'roles' => ['admin'],
    'is_active' => true,
    'email_verified_at' => now(),
]);

echo "Admin user created successfully.\n";
echo "  Email:    {$user->email}\n";
echo "  Password: {$password}\n";
echo "  ID:       {$user->id}\n";
