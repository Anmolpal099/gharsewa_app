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
        Schema::create('ai_match_scores', function (Blueprint $table) {
            $table->id();
            $table->uuid('booking_id');
            $table->foreign('booking_id')->references('id')->on('bookings')->onDelete('cascade');
            $table->uuid('provider_id');
            $table->foreign('provider_id')->references('id')->on('users')->onDelete('cascade');
            $table->decimal('overall_score', 5, 2); // 0.00 to 100.00
            $table->decimal('skill_match_score', 5, 2)->nullable();
            $table->decimal('availability_score', 5, 2)->nullable();
            $table->decimal('location_score', 5, 2)->nullable();
            $table->decimal('rating_score', 5, 2)->nullable();
            $table->decimal('price_score', 5, 2)->nullable();
            $table->decimal('experience_score', 5, 2)->nullable();
            $table->text('reasoning')->nullable();
            $table->json('factor_breakdown')->nullable(); // Detailed scoring factors
            $table->timestamps();
            
            // Indexes
            $table->index('booking_id');
            $table->index('provider_id');
            $table->index(['booking_id', 'overall_score']);
            $table->unique(['booking_id', 'provider_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_match_scores');
    }
};
