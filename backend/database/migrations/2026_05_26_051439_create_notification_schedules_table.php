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
        Schema::create('notification_schedules', function (Blueprint $table) {
            $table->id();
            $table->uuid('user_id');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->string('notification_type'); // booking_reminder, promotion, update, etc.
            $table->timestamp('optimal_time'); // AI-determined best time to send
            $table->timestamp('scheduled_at')->nullable(); // When notification is scheduled
            $table->timestamp('sent_at')->nullable(); // When notification was actually sent
            $table->boolean('opened')->default(false);
            $table->boolean('clicked')->default(false);
            $table->timestamp('opened_at')->nullable();
            $table->timestamp('clicked_at')->nullable();
            $table->string('ab_test_group')->nullable(); // control, test_a, test_b, etc.
            $table->json('engagement_data')->nullable(); // User engagement patterns used for timing
            $table->timestamps();
            
            // Indexes
            $table->index('user_id');
            $table->index('notification_type');
            $table->index('optimal_time');
            $table->index('scheduled_at');
            $table->index('ab_test_group');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification_schedules');
    }
};
