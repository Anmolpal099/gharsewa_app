<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('firebase_uid')->unique();
            $table->string('email')->unique();
            $table->string('name');
            $table->enum('role', ['customer', 'serviceProvider', 'admin'])->default('customer');
            $table->string('phone_number')->nullable();
            $table->string('profile_image_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->json('metadata')->nullable();
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['role', 'is_active']);
            $table->index('firebase_uid');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
