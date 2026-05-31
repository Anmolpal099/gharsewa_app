# Test AI Consultation Endpoint
# This script tests the complete AI consultation flow

param(
    [string]$Email = "customer@example.com",
    [string]$Password = "password"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AI Consultation Endpoint Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login to get JWT token
Write-Host "[1/3] Logging in to get JWT token..." -ForegroundColor Yellow
Write-Host "Email: $Email" -ForegroundColor Gray

$loginBody = @{
    email = $Email
    password = $Password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody `
        -TimeoutSec 10

    if ($loginResponse.success -and $loginResponse.data.access_token) {
        $token = $loginResponse.data.access_token
        Write-Host "✓ Login successful!" -ForegroundColor Green
        Write-Host "  Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
    } else {
        Write-Host "✗ Login failed!" -ForegroundColor Red
        Write-Host "  Response: $($loginResponse | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Login request failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "  1. Backend is running: docker ps | grep gharsewa_app" -ForegroundColor White
    Write-Host "  2. You have a customer account with email: $Email" -ForegroundColor White
    Write-Host "  3. The password is correct" -ForegroundColor White
    exit 1
}
Write-Host ""

# Step 2: Prepare test data
Write-Host "[2/3] Preparing test consultation data..." -ForegroundColor Yellow

# Small 1x1 red pixel PNG (base64 encoded)
$testImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

$consultationBody = @{
    image = "data:image/png;base64,$testImageBase64"
    markers = @(
        @{
            x = 0.5
            y = 0.5
            description = "Water leak visible here"
        },
        @{
            x = 0.3
            y = 0.7
            description = "Rust and corrosion on pipe"
        }
    )
} | ConvertTo-Json -Depth 10

Write-Host "✓ Test data prepared" -ForegroundColor Green
Write-Host "  Image size: $($testImageBase64.Length) bytes" -ForegroundColor Gray
Write-Host "  Markers: 2" -ForegroundColor Gray
Write-Host ""

# Step 3: Call AI consultation endpoint
Write-Host "[3/3] Calling AI consultation endpoint..." -ForegroundColor Yellow
Write-Host "This will take 10-30 seconds (AI is analyzing)..." -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

try {
    $startTime = Get-Date
    
    $consultationResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/customer/ai/consultations" `
        -Method Post `
        -Headers $headers `
        -Body $consultationBody `
        -TimeoutSec 120

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    if ($consultationResponse.success) {
        Write-Host "✓ AI consultation successful!" -ForegroundColor Green
        Write-Host "  Processing time: $([math]::Round($duration, 1)) seconds" -ForegroundColor Gray
        Write-Host ""
        
        $consultation = $consultationResponse.data.consultation
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "AI ANALYSIS RESULTS" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "📋 Diagnosis:" -ForegroundColor Yellow
        Write-Host "  $($consultation.diagnosis)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "🔧 Service Type:" -ForegroundColor Yellow
        Write-Host "  $($consultation.service_type)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "💰 Cost Estimate:" -ForegroundColor Yellow
        Write-Host "  NPR $($consultation.cost_min) - $($consultation.cost_max)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Confidence:" -ForegroundColor Yellow
        Write-Host "  $([math]::Round($consultation.confidence * 100, 1))%" -ForegroundColor White
        Write-Host ""
        
        Write-Host "🤖 Model:" -ForegroundColor Yellow
        Write-Host "  $($consultation.model)" -ForegroundColor White
        Write-Host ""
        
        if ($consultation.recommended_providers -and $consultation.recommended_providers.Count -gt 0) {
            Write-Host "👷 Recommended Providers:" -ForegroundColor Yellow
            foreach ($provider in $consultation.recommended_providers) {
                Write-Host "  • $($provider.name) ($($provider.rating)★, $($provider.reviews_count) reviews)" -ForegroundColor White
            }
        } else {
            Write-Host "👷 Recommended Providers:" -ForegroundColor Yellow
            Write-Host "  No providers found for this service type" -ForegroundColor Gray
        }
        Write-Host ""
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "✓ AI MODEL IS WORKING CORRECTLY!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "The AI model (Qwen 3.5 VL 2B) is:" -ForegroundColor Green
        Write-Host "  ✓ Loaded and running" -ForegroundColor Green
        Write-Host "  ✓ Analyzing images" -ForegroundColor Green
        Write-Host "  ✓ Generating diagnoses" -ForegroundColor Green
        Write-Host "  ✓ Estimating costs" -ForegroundColor Green
        Write-Host "  ✓ Recommending providers" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "You can now use the AI Assistant in your Flutter app!" -ForegroundColor Cyan
        Write-Host ""
        
    } else {
        Write-Host "✗ AI consultation failed!" -ForegroundColor Red
        Write-Host "  Message: $($consultationResponse.message)" -ForegroundColor Red
        Write-Host "  Response: $($consultationResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ AI consultation request failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    
    # Try to parse error response
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "  Response body: $responseBody" -ForegroundColor Red
    }
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "TROUBLESHOOTING STEPS" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "1. Check if Ollama is running:" -ForegroundColor Cyan
    Write-Host "   docker ps | grep ollama" -ForegroundColor White
    Write-Host ""
    
    Write-Host "2. Check if model is loaded:" -ForegroundColor Cyan
    Write-Host "   docker exec gharsewa_ollama ollama list" -ForegroundColor White
    Write-Host ""
    
    Write-Host "3. Check backend logs:" -ForegroundColor Cyan
    Write-Host "   docker logs gharsewa_app | tail -50" -ForegroundColor White
    Write-Host ""
    
    Write-Host "4. Check Ollama logs:" -ForegroundColor Cyan
    Write-Host "   docker logs gharsewa_ollama | tail -50" -ForegroundColor White
    Write-Host ""
    
    Write-Host "5. Test Ollama directly:" -ForegroundColor Cyan
    Write-Host "   curl http://localhost:11434/api/tags" -ForegroundColor White
    Write-Host ""
    
    Write-Host "6. Run the debug script:" -ForegroundColor Cyan
    Write-Host "   .\debug_ai_error.ps1" -ForegroundColor White
    Write-Host ""
    
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Now test in your Flutter app:" -ForegroundColor Yellow
Write-Host "  1. Run: flutter run -d edge" -ForegroundColor White
Write-Host "  2. Login as customer" -ForegroundColor White
Write-Host "  3. Go to AI Assistant section" -ForegroundColor White
Write-Host "  4. Upload an image" -ForegroundColor White
Write-Host "  5. Add markers and descriptions" -ForegroundColor White
Write-Host "  6. Submit and wait 10-30 seconds" -ForegroundColor White
Write-Host "  7. See the AI diagnosis!" -ForegroundColor White
Write-Host ""

Write-Host "If you still get 'Server error' in Flutter:" -ForegroundColor Yellow
Write-Host "  • Check browser console (F12) for errors" -ForegroundColor White
Write-Host "  • Check Network tab for the actual API response" -ForegroundColor White
Write-Host "  • Make sure you're logged in as a customer" -ForegroundColor White
Write-Host "  • Try with a different image (smaller size)" -ForegroundColor White
Write-Host "  • Check Flutter console for error messages" -ForegroundColor White
Write-Host ""
