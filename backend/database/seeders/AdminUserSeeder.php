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
        $admins = [
            [
                'name' => 'Anmol Pal',
                'email' => 'anmolpal156@gmail.com',
                'password' => 'Anmol123@',
                'role' => 'admin',
                'roles' => ['admin'],
            ],
            [
                'name' => 'Admin User',
                'email' => 'admin@gharsewa.com',
                'password' => 'Admin123',
                'role' => 'admin',
                'roles' => ['admin'],
            ],
        ];

        foreach ($admins as $adminData) {
            if (!User::where('email', $adminData['email'])->exists()) {
                User::create([
                    'name' => $adminData['name'],
                    'email' => $adminData['email'],
                    'password' => Hash::make($adminData['password']),
                    'role' => $adminData['role'],
                    'roles' => $adminData['roles'],
                    'is_active' => true,
                    'email_verified_at' => now(), // Admin is pre-verified
                ]);
                
                $this->command->info('✅ Admin created: ' . $adminData['email']);
            } else {
                $this->command->info('⚠️  Admin already exists: ' . $adminData['email']);
            }
        }
        
        $this->command->info('');
        $this->command->info('Admin accounts ready!');
    }
}
