<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('customer_id');
            $table->uuid('service_id');
            $table->uuid('provider_id');
            $table->timestamp('scheduled_at');
            $table->enum('status', [
                'pending', 'confirmed', 'inProgress', 'completed', 'cancelled'
            ])->default('pending');
            $table->decimal('total_price', 10, 2);
            $table->string('currency', 3)->default('NPR');
            $table->text('cancellation_reason')->nullable();
            $table->text('admin_notes')->nullable();
            $table->boolean('is_disputed')->default(false);
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('customer_id')->references('id')->on('users');
            $table->foreign('service_id')->references('id')->on('services');
            $table->foreign('provider_id')->references('id')->on('users');
            $table->index(['status', 'scheduled_at']);
            $table->index('customer_id');
            $table->index('provider_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
