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
        Schema::create('ai_predictions', function (Blueprint $table) {
            $table->id();
            $table->string('prediction_type'); // booking_volume, churn_risk, revenue_forecast, trend
            $table->json('prediction_data'); // The actual prediction results
            $table->decimal('confidence_score', 5, 2); // 0.00 to 100.00
            $table->date('prediction_date'); // Date this prediction is for
            $table->date('generated_date'); // Date prediction was generated
            $table->json('input_data')->nullable(); // Historical data used for prediction
            $table->text('insights')->nullable(); // AI-generated insights
            $table->timestamps();
            
            // Indexes
            $table->index('prediction_type');
            $table->index('prediction_date');
            $table->index(['prediction_type', 'prediction_date']);
            $table->index('generated_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_predictions');
    }
};
