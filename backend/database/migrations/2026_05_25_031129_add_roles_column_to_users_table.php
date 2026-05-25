<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Adds 'roles' JSON column to support multiple roles per user.
     * Migrates existing 'role' data to 'roles' array format.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Add new roles column (JSON array)
            $table->json('roles')->nullable()->after('role');
        });

        // Migrate existing role data to roles array
        DB::table('users')->get()->each(function ($user) {
            $currentRole = $user->role;
            DB::table('users')
                ->where('id', $user->id)
                ->update(['roles' => json_encode([$currentRole])]);
        });

        // Make roles column non-nullable after migration
        Schema::table('users', function (Blueprint $table) {
            $table->json('roles')->nullable(false)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('roles');
        });
    }
};

