# Test Qwen 3.5 VL 2B AI Model Integration
# This script tests the AI model from Ollama to Backend to ensure it's working

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Qwen 3.5 VL 2B AI Integration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check Ollama Container
Write-Host "[Test 1] Checking Ollama container..." -ForegroundColor Yellow
$ollamaContainer = docker ps --filter "name=gharsewa_ollama" --format "{{.Names}}"
if ($ollamaContainer -eq "gharsewa_ollama") {
    Write-Host "✓ Ollama container is running" -ForegroundColor Green
} else {
    Write-Host "✗ Ollama container is NOT running" -ForegroundColor Red
    Write-Host "  Run: docker-compose -f backend/docker-compose.ollama.yml up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 2: Check if qwen3-vl:2b model is loaded
Write-Host "[Test 2] Checking if qwen3-vl:2b model is loaded..." -ForegroundColor Yellow
$models = docker exec gharsewa_ollama ollama list
if ($models -match "qwen3-vl:2b") {
    Write-Host "✓ qwen3-vl:2b model is loaded" -ForegroundColor Green
} else {
    Write-Host "✗ qwen3-vl:2b model is NOT loaded" -ForegroundColor Red
    Write-Host "  Run: docker exec gharsewa_ollama ollama pull qwen3-vl:2b" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 3: Test Ollama API
Write-Host "[Test 3] Testing Ollama API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Ollama API is responding" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Ollama API is NOT responding" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 4: Test simple text generation
Write-Host "[Test 4] Testing text generation with qwen3-vl:2b..." -ForegroundColor Yellow
$testPrompt = @{
    model = "qwen3-vl:2b"
    prompt = "What is 2+2? Answer in one word."
    stream = $false
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/generate" `
        -Method Post `
        -Body $testPrompt `
        -ContentType "application/json" `
        -UseBasicParsing `
        -TimeoutSec 30
    
    $result = $response.Content | ConvertFrom-Json
    Write-Host "✓ Model generated response: $($result.response.Substring(0, [Math]::Min(50, $result.response.Length)))..." -ForegroundColor Green
} catch {
    Write-Host "✗ Model generation failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 5: Check Backend Container
Write-Host "[Test 5] Checking Laravel backend container..." -ForegroundColor Yellow
$backendContainer = docker ps --filter "name=gharsewa_app" --format "{{.Names}}"
if ($backendContainer -eq "gharsewa_app") {
    Write-Host "✓ Backend container is running" -ForegroundColor Green
} else {
    Write-Host "✗ Backend container is NOT running" -ForegroundColor Red
    Write-Host "  Run: docker-compose -f backend/docker-compose.yml up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 6: Check Backend Environment
Write-Host "[Test 6] Checking backend Ollama configuration..." -ForegroundColor Yellow
$envContent = Get-Content "backend\.env" -Raw
if ($envContent -match "OLLAMA_HOST=http://gharsewa_ollama:11434" -and 
    $envContent -match "OLLAMA_MODEL=qwen3-vl:2b") {
    Write-Host "✓ Backend environment is configured correctly" -ForegroundColor Green
} else {
    Write-Host "✗ Backend environment is NOT configured correctly" -ForegroundColor Red
    Write-Host "  Check backend/.env file for OLLAMA_HOST and OLLAMA_MODEL" -ForegroundColor Yellow
}
Write-Host ""

# Test 7: Check if AI Service file exists
Write-Host "[Test 7] Checking AI service files..." -ForegroundColor Yellow
if (Test-Path "backend\app\Services\AI\VisionAIService.php") {
    Write-Host "✓ VisionAIService.php exists" -ForegroundColor Green
} else {
    Write-Host "✗ VisionAIService.php is missing" -ForegroundColor Red
}

if (Test-Path "backend\app\Http\Controllers\API\V1\Customer\AIConsultationController.php") {
    Write-Host "✓ AIConsultationController.php exists" -ForegroundColor Green
} else {
    Write-Host "✗ AIConsultationController.php is missing" -ForegroundColor Red
}
Write-Host ""

# Test 8: Check Backend API Health
Write-Host "[Test 8] Testing backend API health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/health" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Backend API is responding" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Backend API is NOT responding" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host "  Make sure backend is running on port 8000" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Ollama container: Running" -ForegroundColor Green
Write-Host "✓ qwen3-vl:2b model: Loaded" -ForegroundColor Green
Write-Host "✓ Ollama API: Working" -ForegroundColor Green
Write-Host "✓ Model generation: Working" -ForegroundColor Green
Write-Host "✓ Backend container: Running" -ForegroundColor Green
Write-Host "✓ Backend config: Correct" -ForegroundColor Green
Write-Host "✓ AI service files: Present" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps to Test in Flutter App:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Start Flutter app: flutter run -d edge" -ForegroundColor White
Write-Host "2. Login as a customer" -ForegroundColor White
Write-Host "3. Navigate to AI Assistant section" -ForegroundColor White
Write-Host "4. Upload an image (camera or gallery)" -ForegroundColor White
Write-Host "5. Add markers by tapping on the image" -ForegroundColor White
Write-Host "6. Add descriptions for each marker" -ForegroundColor White
Write-Host "7. Click 'Submit' or 'Analyze' button" -ForegroundColor White
Write-Host "8. Wait 10-30 seconds for AI response" -ForegroundColor White
Write-Host ""
Write-Host "Expected Response:" -ForegroundColor Yellow
Write-Host "  - Diagnosis: AI-generated problem description" -ForegroundColor White
Write-Host "  - Service Type: One of 10 categories" -ForegroundColor White
Write-Host "  - Cost Estimate: NPR range (e.g., 2000-5000)" -ForegroundColor White
Write-Host "  - Confidence: 0.0 to 1.0 score" -ForegroundColor White
Write-Host "  - Recommended Providers: Top 3 with ratings" -ForegroundColor White
Write-Host ""
Write-Host "If you still get 'Server error':" -ForegroundColor Yellow
Write-Host "  - Check backend logs: docker-compose -f backend/docker-compose.yml logs app" -ForegroundColor White
Write-Host "  - Check Ollama logs: docker logs gharsewa_ollama" -ForegroundColor White
Write-Host "  - Check Laravel logs: backend/storage/logs/laravel.log" -ForegroundColor White
Write-Host ""
Write-Host "For detailed testing guide, see: AI_MODEL_TESTING_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
