<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('booking_id');
            $table->uuid('customer_id');
            $table->uuid('provider_id');
            $table->uuid('service_id');
            $table->tinyInteger('rating');  // 1-5
            $table->text('comment')->nullable();
            $table->timestamps();

            $table->foreign('booking_id')->references('id')->on('bookings');
            $table->foreign('customer_id')->references('id')->on('users');
            $table->foreign('provider_id')->references('id')->on('users');
            $table->foreign('service_id')->references('id')->on('services');
            $table->unique('booking_id');
            $table->index(['provider_id', 'rating']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
