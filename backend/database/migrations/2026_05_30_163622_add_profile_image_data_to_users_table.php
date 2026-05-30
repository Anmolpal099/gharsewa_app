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
            // Add column to store base64 image data directly in database
            $table->longText('profile_image_data')->nullable()->after('profile_image_url');
            $table->string('profile_image_mime_type', 50)->nullable()->after('profile_image_data');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['profile_image_data', 'profile_image_mime_type']);
        });
    }
};
