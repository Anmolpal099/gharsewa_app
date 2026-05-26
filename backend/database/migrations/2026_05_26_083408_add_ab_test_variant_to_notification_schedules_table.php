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
        Schema::table('notification_schedules', function (Blueprint $table) {
            // Add ab_test_variant column to track which variant the user received
            // 'control' = default timing, 'test' = AI-optimized timing
            $table->string('ab_test_variant')->nullable()->after('ab_test_group');
            
            // Add index for efficient querying by variant
            $table->index('ab_test_variant');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notification_schedules', function (Blueprint $table) {
            $table->dropIndex(['ab_test_variant']);
            $table->dropColumn('ab_test_variant');
        });
    }
};
