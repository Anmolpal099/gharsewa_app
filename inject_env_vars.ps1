# Inject Environment Variables into Running Container
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Injecting OLLAMA Environment Variables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create a script that sets environment variables and restarts PHP-FPM
$envScript = @'
#!/bin/sh
# Add OLLAMA environment variables to PHP-FPM pool config
cat >> /usr/local/etc/php-fpm.d/www.conf << 'EOF'

; OLLAMA Configuration
env[OLLAMA_HOST] = http://gharsewa_ollama:11434
env[OLLAMA_MODEL] = qwen3-vl:2b
env[OLLAMA_TIMEOUT] = 120
env[OLLAMA_MAX_TOKENS] = 2048
env[OLLAMA_TEMPERATURE] = 0.7
env[OLLAMA_TOP_P] = 0.9
env[AI_MAX_RETRIES] = 3
env[AI_RETRY_DELAY] = 1000
env[AI_CACHE_TTL] = 3600
EOF

# Restart PHP-FPM to load new config
kill -USR2 1
echo "Environment variables injected and PHP-FPM reloaded"
'@

# Write script to temp file
$envScript | Out-File -FilePath "temp_inject.sh" -Encoding ASCII

# Copy script to container
Write-Host "[1/4] Copying injection script to container..." -ForegroundColor Yellow
docker cp temp_inject.sh gharsewa_app:/tmp/inject_env.sh
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# Make script executable and run it
Write-Host "[2/4] Executing injection script..." -ForegroundColor Yellow
docker exec gharsewa_app chmod +x /tmp/inject_env.sh
docker exec gharsewa_app /tmp/inject_env.sh
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# Wait for PHP-FPM to reload
Write-Host "[3/4] Waiting for PHP-FPM to reload..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# Verify by running a PHP script that checks environment variables
Write-Host "[4/4] Verifying environment variables in PHP..." -ForegroundColor Yellow
$phpCheck = docker exec gharsewa_app php -r "echo getenv('OLLAMA_HOST') . PHP_EOL; echo getenv('OLLAMA_MODEL') . PHP_EOL;"
if ($phpCheck -match "gharsewa_ollama") {
    Write-Host "OK - Environment variables are now available in PHP:" -ForegroundColor Green
    Write-Host $phpCheck -ForegroundColor Cyan
} else {
    Write-Host "ERROR - Variables still not available in PHP" -ForegroundColor Red
    Write-Host "Output: $phpCheck" -ForegroundColor Red
}
Write-Host ""

# Clean up
Remove-Item temp_inject.sh -ErrorAction SilentlyContinue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INJECTION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run diagnostic script: .\debug_ai_simple.ps1" -ForegroundColor White
Write-Host "  2. If all checks pass, test endpoint: .\test_ai_endpoint.ps1" -ForegroundColor White
Write-Host "  3. Try AI Assistant in Flutter app" -ForegroundColor White
Write-Host ""
