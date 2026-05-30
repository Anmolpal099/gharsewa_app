<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== FIXING EXISTING CERTIFICATES ===\n\n";

try {
    // Find all users with certifications
    $users = DB::table('users')
        ->whereNotNull('metadata')
        ->get();

    $totalFixed = 0;
    $totalUsers = 0;

    foreach ($users as $user) {
        $metadata = json_decode($user->metadata, true) ?? [];
        $certifications = $metadata['certifications'] ?? [];

        if (empty($certifications)) {
            continue;
        }

        $needsUpdate = false;
        $updatedCerts = [];

        foreach ($certifications as $cert) {
            // Check if this cert has document_url but not document_data
            if (isset($cert['document_url']) && !isset($cert['document_data'])) {
                $documentUrl = $cert['document_url'];

                // Extract mime type and base64 data from data URL
                if (preg_match('/^data:([^;]+);base64,(.+)$/', $documentUrl, $matches)) {
                    $mimeType = $matches[1];
                    $base64Data = $matches[2];

                    // Update certificate structure
                    $cert['document_data'] = $base64Data;
                    $cert['mime_type'] = $mimeType;
                    unset($cert['document_url']); // Remove the long URL

                    $needsUpdate = true;
                    $totalFixed++;

                    echo "✓ Fixed certificate: {$cert['name']} for user {$user->name}\n";
                    echo "  - Extracted mime type: {$mimeType}\n";
                    echo "  - Data size: " . number_format(strlen($base64Data)) . " bytes\n";
                }
            }

            $updatedCerts[] = $cert;
        }

        if ($needsUpdate) {
            $metadata['certifications'] = $updatedCerts;

            DB::table('users')
                ->where('id', $user->id)
                ->update(['metadata' => json_encode($metadata)]);

            $totalUsers++;
            echo "  ✓ Updated user: {$user->name}\n\n";
        }
    }

    echo "\n=== MIGRATION COMPLETE ===\n";
    echo "Total certificates fixed: {$totalFixed}\n";
    echo "Total users updated: {$totalUsers}\n\n";

    if ($totalFixed === 0) {
        echo "ℹ️  No certificates needed fixing.\n";
    } else {
        echo "✓ All existing certificates have been migrated!\n";
    }

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
