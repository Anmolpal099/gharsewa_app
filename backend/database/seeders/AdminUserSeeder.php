<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create admin user if it doesn't exist
        $adminEmail = 'admin@gharsewa.com';
        
        if (!User::where('email', $adminEmail)->exists()) {
            User::create([
                'name' => 'Admin User',
                'email' => $adminEmail,
                'password' => Hash::make('Admin123'),
                'role' => 'admin',
                'roles' => ['admin'],
                'is_active' => true,
                'email_verified_at' => now(), // Admin is pre-verified
            ]);
            
            $this->command->info('Admin user created successfully!');
            $this->command->info('Email: ' . $adminEmail);
            $this->command->info('Password: Admin123');
        } else {
            $this->command->info('Admin user already exists.');
        }
    }
}
