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
        Schema::create('ai_consultations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('customer_id');
            $table->string('image_path', 500);
            $table->unsignedInteger('image_size_kb');
            $table->json('markers')->comment('Array of {x, y, description}');
            $table->text('ai_diagnosis');
            $table->string('recommended_service_type', 100);
            $table->decimal('cost_min', 10, 2);
            $table->decimal('cost_max', 10, 2);
            $table->json('recommended_providers')->nullable()->comment('Array of provider IDs');
            $table->json('ai_response_raw')->comment('Full AI response for reference');
            $table->unsignedInteger('processing_time_ms');
            $table->timestamps();
            $table->softDeletes();

            // Foreign key constraint
            $table->foreign('customer_id')
                  ->references('id')
                  ->on('users')
                  ->onDelete('cascade');

            // Indexes for performance optimization
            $table->index(['customer_id', 'created_at'], 'idx_customer_created');
            $table->index('recommended_service_type', 'idx_service_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_consultations');
    }
};
