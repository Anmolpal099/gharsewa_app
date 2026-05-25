<?php

/**
 * Test Registration Endpoint
 * 
 * Run this script to test if the JWT registration endpoint is working
 * 
 * Usage: php test-registration.php
 */

echo "🧪 Testing JWT Registration Endpoint\n";
echo "=====================================\n\n";

$baseUrl = 'http://localhost:8000/api/v1/auth/jwt/register';

$testData = [
    'name' => 'Test User ' . time(),
    'email' => 'test' . time() . '@example.com',
    'password' => 'Test1234',
    'role' => 'customer',
];

echo "📤 Sending POST request to: $baseUrl\n";
echo "📦 Data:\n";
echo json_encode($testData, JSON_PRETTY_PRINT) . "\n\n";

$ch = curl_init($baseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ cURL Error: $error\n";
    exit(1);
}

echo "📥 Response (HTTP $httpCode):\n";
echo $response . "\n\n";

$responseData = json_decode($response, true);

if ($httpCode === 200 && isset($responseData['success']) && $responseData['success']) {
    echo "✅ Registration successful!\n";
    echo "📧 OTP should be sent to: {$testData['email']}\n";
    echo "👤 User ID: {$responseData['data']['user_id']}\n";
} else {
    echo "❌ Registration failed!\n";
    if (isset($responseData['message'])) {
        echo "Error: {$responseData['message']}\n";
    }
    if (isset($responseData['errors'])) {
        echo "Validation errors:\n";
        print_r($responseData['errors']);
    }
}

echo "\n";
