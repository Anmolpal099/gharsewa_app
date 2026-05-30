<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

echo "Checking if columns exist...\n";

try {
    // Check if columns already exist
    $hasData = Schema::hasColumn('users', 'profile_image_data');
    $hasMime = Schema::hasColumn('users', 'profile_image_mime_type');
    
    echo "profile_image_data exists: " . ($hasData ? 'YES' : 'NO') . "\n";
    echo "profile_image_mime_type exists: " . ($hasMime ? 'YES' : 'NO') . "\n";
    
    if (!$hasData || !$hasMime) {
        echo "\nAdding missing columns...\n";
        
        if (!$hasData) {
            DB::statement("ALTER TABLE users ADD COLUMN profile_image_data LONGTEXT NULL AFTER profile_image_url");
            echo "✓ Added profile_image_data column\n";
        }
        
        if (!$hasMime) {
            DB::statement("ALTER TABLE users ADD COLUMN profile_image_mime_type VARCHAR(50) NULL AFTER profile_image_data");
            echo "✓ Added profile_image_mime_type column\n";
        }
        
        echo "✓ Columns added successfully!\n";
    } else {
        echo "\n✓ All columns already exist!\n";
    }
    
    // Verify
    echo "\nVerifying columns...\n";
    $columns = DB::select("SHOW COLUMNS FROM users WHERE Field LIKE 'profile_image%'");
    foreach ($columns as $column) {
        echo "  - {$column->Field} ({$column->Type})\n";
    }
    
    echo "\n✓ Done!\n";
    
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
    exit(1);
}
