# Restart Backend with Environment Variables Loaded
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Restarting Backend with Env Variables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

cd backend

# Stop the app container
Write-Host "[1/3] Stopping app container..." -ForegroundColor Yellow
docker-compose stop app
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# Remove the app container
Write-Host "[2/3] Removing app container..." -ForegroundColor Yellow
docker-compose rm -f app
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# Start the app container (this will recreate it with new env vars)
Write-Host "[3/3] Starting app container with environment variables..." -ForegroundColor Yellow
docker-compose up -d app
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# Wait for container to be ready
Write-Host "Waiting for container to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# Verify environment variables
Write-Host "Verifying OLLAMA environment variables..." -ForegroundColor Yellow
$envVars = docker exec gharsewa_app printenv | Select-String -Pattern "OLLAMA"
if ($envVars) {
    Write-Host "OK - Environment variables loaded:" -ForegroundColor Green
    docker exec gharsewa_app printenv | Select-String -Pattern "OLLAMA"
} else {
    Write-Host "ERROR - Still not loaded!" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Check if .env file exists and has OLLAMA variables
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" | Select-String -Pattern "OLLAMA"
        if ($envContent) {
            Write-Host "Found OLLAMA variables in .env file:" -ForegroundColor Cyan
            $envContent
        } else {
            Write-Host "ERROR - No OLLAMA variables in .env file!" -ForegroundColor Red
        }
    }
}
Write-Host ""

# Test network connectivity
Write-Host "Testing network connectivity..." -ForegroundColor Yellow
$pingTest = docker exec gharsewa_app ping -c 2 gharsewa_ollama 2>&1
if ($pingTest -match "2 received") {
    Write-Host "OK - Backend can reach Ollama container" -ForegroundColor Green
} else {
    Write-Host "ERROR - Backend CANNOT reach Ollama container" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next step: Run diagnostic script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "cd ..; .\debug_ai_simple.ps1" -ForegroundColor White
Write-Host ""
