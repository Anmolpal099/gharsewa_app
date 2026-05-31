# Fix Docker Configuration and Restart Everything
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Docker Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend
cd backend

# Step 1: Stop all containers
Write-Host "[1/6] Stopping all containers..." -ForegroundColor Yellow
docker-compose down
docker-compose -f docker-compose.ollama.yml down
Write-Host "OK - All containers stopped" -ForegroundColor Green
Write-Host ""

# Step 2: Remove old network if it exists
Write-Host "[2/6] Cleaning up old network..." -ForegroundColor Yellow
docker network rm backend_gharsewa_network 2>$null
Write-Host "OK - Network cleaned" -ForegroundColor Green
Write-Host ""

# Step 3: Create public/storage directory
Write-Host "[3/6] Creating public/storage directory..." -ForegroundColor Yellow
if (-not (Test-Path "public/storage")) {
    New-Item -ItemType Directory -Path "public/storage" -Force | Out-Null
}
Write-Host "OK - Directory created" -ForegroundColor Green
Write-Host ""

# Step 4: Build backend container
Write-Host "[4/6] Building backend container..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Cyan
docker-compose build --no-cache app
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Backend container built successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR - Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Start all services
Write-Host "[5/6] Starting all services..." -ForegroundColor Yellow
Write-Host "Starting main backend services..." -ForegroundColor Cyan
docker-compose up -d

Write-Host "Waiting for backend to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host "Starting Ollama container..." -ForegroundColor Cyan
docker-compose -f docker-compose.ollama.yml up -d

Write-Host "Waiting for Ollama to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "OK - All services started" -ForegroundColor Green
Write-Host ""

# Step 6: Verify environment variables
Write-Host "[6/6] Verifying environment variables..." -ForegroundColor Yellow
$envVars = docker exec gharsewa_app printenv | Select-String -Pattern "OLLAMA"
if ($envVars) {
    Write-Host "OK - Environment variables loaded:" -ForegroundColor Green
    docker exec gharsewa_app printenv | Select-String -Pattern "OLLAMA"
} else {
    Write-Host "ERROR - Environment variables NOT loaded!" -ForegroundColor Red
    Write-Host "Checking .env file..." -ForegroundColor Yellow
    if (Test-Path ".env") {
        Write-Host "OK - .env file exists" -ForegroundColor Green
    } else {
        Write-Host "ERROR - .env file NOT found!" -ForegroundColor Red
    }
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run diagnostic script: cd ..; .\debug_ai_simple.ps1" -ForegroundColor White
Write-Host "  2. If all checks pass, test the endpoint: .\test_ai_endpoint.ps1" -ForegroundColor White
Write-Host "  3. Try the AI Assistant in your Flutter app" -ForegroundColor White
Write-Host ""

Write-Host "Checking container status..." -ForegroundColor Cyan
docker ps --format "table {{.Names}}`t{{.Status}}" | Select-String -Pattern "gharsewa"
Write-Host ""
