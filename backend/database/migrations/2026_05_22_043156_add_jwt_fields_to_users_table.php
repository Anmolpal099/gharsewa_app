<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Add password field for JWT authentication
            $table->string('password')->nullable()->after('name');
            
            // Add email verification timestamp
            $table->timestamp('email_verified_at')->nullable()->after('email');
            
            // Make firebase_uid nullable for JWT-only users
            $table->string('firebase_uid')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['password', 'email_verified_at']);
            
            // Revert firebase_uid to non-nullable
            $table->string('firebase_uid')->nullable(false)->change();
        });
    }
};
