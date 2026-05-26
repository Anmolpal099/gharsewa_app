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
            // Add status column to track notification lifecycle
            // Values: 'scheduled', 'sent', 'failed', 'cancelled'
            $table->string('status')->default('scheduled')->after('ab_test_variant');
            
            // Add index for efficient querying by status
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notification_schedules', function (Blueprint $table) {
            $table->dropIndex(['status']);
            $table->dropColumn('status');
        });
    }
};
