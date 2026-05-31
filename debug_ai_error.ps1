# AI Model "Server Error" Debugging Script
# This script will help identify why you're getting "Server error" in the Flutter app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AI Model Error Debugging Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Docker containers are running
Write-Host "[1/10] Checking Docker containers..." -ForegroundColor Yellow
$containers = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "gharsewa"
if ($containers) {
    Write-Host "✓ Docker containers running:" -ForegroundColor Green
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "gharsewa"
} else {
    Write-Host "✗ No Gharsewa containers running!" -ForegroundColor Red
    Write-Host "  Run: cd backend; docker-compose up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 2: Check if Ollama container is running
Write-Host "[2/10] Checking Ollama container..." -ForegroundColor Yellow
$ollamaRunning = docker ps | Select-String -Pattern "gharsewa_ollama"
if ($ollamaRunning) {
    Write-Host "✓ Ollama container is running" -ForegroundColor Green
} else {
    Write-Host "✗ Ollama container is NOT running!" -ForegroundColor Red
    Write-Host "  Run: cd backend; docker-compose -f docker-compose.ollama.yml up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 3: Check if Qwen model is loaded
Write-Host "[3/10] Checking if Qwen 3.5 VL 2B model is loaded..." -ForegroundColor Yellow
$modelCheck = docker exec gharsewa_ollama ollama list 2>&1
if ($modelCheck -match "qwen3-vl:2b") {
    Write-Host "✓ Qwen 3.5 VL 2B model is loaded" -ForegroundColor Green
} else {
    Write-Host "✗ Qwen 3.5 VL 2B model is NOT loaded!" -ForegroundColor Red
    Write-Host "  Run: docker exec gharsewa_ollama ollama pull qwen3-vl:2b" -ForegroundColor Yellow
    Write-Host "  (This will download ~1.5GB, please wait)" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 4: Test Ollama API from host
Write-Host "[4/10] Testing Ollama API from host machine..." -ForegroundColor Yellow
try {
    $ollamaResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5
    if ($ollamaResponse) {
        Write-Host "✓ Ollama API is responding on localhost:11434" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Ollama API is NOT responding on localhost:11434" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 5: Test Ollama API from backend container
Write-Host "[5/10] Testing Ollama API from backend container..." -ForegroundColor Yellow
$pingTest = docker exec gharsewa_app ping -c 2 gharsewa_ollama 2>&1
if ($pingTest -match "2 received") {
    Write-Host "✓ Backend can reach Ollama container (ping successful)" -ForegroundColor Green
} else {
    Write-Host "✗ Backend CANNOT reach Ollama container!" -ForegroundColor Red
    Write-Host "  This is likely the cause of your 'Server error'" -ForegroundColor Yellow
    Write-Host "  Check Docker network configuration" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Check backend environment variables
Write-Host "[6/10] Checking backend environment variables..." -ForegroundColor Yellow
$envCheck = docker exec gharsewa_app printenv | Select-String -Pattern "OLLAMA"
if ($envCheck) {
    Write-Host "✓ Ollama environment variables found:" -ForegroundColor Green
    docker exec gharsewa_app printenv | Select-String -Pattern "OLLAMA"
} else {
    Write-Host "✗ Ollama environment variables NOT found!" -ForegroundColor Red
    Write-Host "  Check backend/.env file" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Check Laravel logs for errors
Write-Host "[7/10] Checking Laravel logs for recent errors..." -ForegroundColor Yellow
Write-Host "Last 20 lines of Laravel log:" -ForegroundColor Cyan
docker exec gharsewa_app tail -20 storage/logs/laravel.log 2>&1
Write-Host ""

# Step 8: Check if AI consultation route is registered
Write-Host "[8/10] Checking if AI consultation routes are registered..." -ForegroundColor Yellow
$routeCheck = docker exec gharsewa_app php artisan route:list 2>&1 | Select-String -Pattern "consultations"
if ($routeCheck) {
    Write-Host "✓ AI consultation routes found:" -ForegroundColor Green
    docker exec gharsewa_app php artisan route:list 2>&1 | Select-String -Pattern "consultations"
} else {
    Write-Host "✗ AI consultation routes NOT found!" -ForegroundColor Red
    Write-Host "  Run: docker exec gharsewa_app php artisan route:cache" -ForegroundColor Yellow
}
Write-Host ""

# Step 9: Test Ollama generation from backend container
Write-Host "[9/10] Testing Ollama generation from backend container..." -ForegroundColor Yellow
Write-Host "This will take 5-10 seconds..." -ForegroundColor Cyan
$testGeneration = docker exec gharsewa_app curl -s -X POST http://gharsewa_ollama:11434/api/generate -d '{\"model\":\"qwen3-vl:2b\",\"prompt\":\"Test\",\"stream\":false}' 2>&1
if ($testGeneration -match "response") {
    Write-Host "✓ Backend can successfully call Ollama API!" -ForegroundColor Green
    Write-Host "  Response preview: $($testGeneration.Substring(0, [Math]::Min(100, $testGeneration.Length)))..." -ForegroundColor Gray
} else {
    Write-Host "✗ Backend CANNOT call Ollama API!" -ForegroundColor Red
    Write-Host "  This is the root cause of your 'Server error'" -ForegroundColor Yellow
    Write-Host "  Response: $testGeneration" -ForegroundColor Red
}
Write-Host ""

# Step 10: Check Docker network
Write-Host "[10/10] Checking Docker network configuration..." -ForegroundColor Yellow
$networkCheck = docker network inspect gharsewa-network 2>&1
if ($networkCheck -match "gharsewa_app" -and $networkCheck -match "gharsewa_ollama") {
    Write-Host "✓ Both containers are on the same network (gharsewa-network)" -ForegroundColor Green
} else {
    Write-Host "✗ Containers may not be on the same network!" -ForegroundColor Red
    Write-Host "  Check docker-compose.yml network configuration" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEBUGGING SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "If all checks passed (✓), the infrastructure is working correctly." -ForegroundColor Green
Write-Host "The 'Server error' might be caused by:" -ForegroundColor Yellow
Write-Host "  1. JWT token expired - Try logging out and logging back in" -ForegroundColor White
Write-Host "  2. Image too large - Try with a smaller image (<5MB)" -ForegroundColor White
Write-Host "  3. Timeout - Increase OLLAMA_TIMEOUT in backend/.env to 120" -ForegroundColor White
Write-Host "  4. Rate limiting - Wait 1 minute and try again" -ForegroundColor White
Write-Host ""

Write-Host "If any checks failed (✗), fix those issues first." -ForegroundColor Red
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Check the Flutter console for detailed error messages" -ForegroundColor White
Write-Host "  2. Check browser Network tab (F12) for the actual API response" -ForegroundColor White
Write-Host "  3. Watch backend logs in real-time: docker logs -f gharsewa_app" -ForegroundColor White
Write-Host "  4. Watch Ollama logs in real-time: docker logs -f gharsewa_ollama" -ForegroundColor White
Write-Host ""

Write-Host "To see detailed logs, run:" -ForegroundColor Yellow
Write-Host "  docker logs -f gharsewa_app | Select-String -Pattern 'AI|Ollama|Vision'" -ForegroundColor Cyan
Write-Host ""
