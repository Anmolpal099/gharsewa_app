# Test OTP Endpoints
Write-Host "=== Testing OTP Endpoints ===" -ForegroundColor Cyan

# Test 1: Send Email Verification OTP
Write-Host "`n1. Testing Send Email Verification OTP..." -ForegroundColor Yellow
$response1 = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/otp/send-email-verification" `
    -Method Post `
    -ContentType "application/json" `
    -Body '{"email":"test@example.com"}' `
    -ErrorAction SilentlyContinue

if ($response1.success) {
    Write-Host "✅ Email verification OTP sent successfully!" -ForegroundColor Green
    Write-Host "   Expires in: $($response1.expires_in) seconds" -ForegroundColor Gray
} else {
    Write-Host "❌ Failed to send email verification OTP" -ForegroundColor Red
}

# Wait a moment
Start-Sleep -Seconds 2

# Test 2: Send Password Reset OTP
Write-Host "`n2. Testing Send Password Reset OTP..." -ForegroundColor Yellow
$response2 = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/otp/send-password-reset" `
    -Method Post `
    -ContentType "application/json" `
    -Body '{"email":"test@example.com"}' `
    -ErrorAction SilentlyContinue

if ($response2.success) {
    Write-Host "✅ Password reset OTP sent successfully!" -ForegroundColor Green
    Write-Host "   Expires in: $($response2.expires_in) seconds" -ForegroundColor Gray
} else {
    Write-Host "❌ Failed to send password reset OTP" -ForegroundColor Red
}

# Test 3: Check OTP in database
Write-Host "`n3. Checking OTPs in database..." -ForegroundColor Yellow
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT email, otp, type, expires_at, is_used FROM otp_verifications ORDER BY created_at DESC LIMIT 5;" 2>$null

# Test 4: Check Laravel logs for OTP
Write-Host "`n4. Recent OTPs from Laravel logs:" -ForegroundColor Yellow
docker exec gharsewa_app tail -n 20 storage/logs/laravel.log 2>$null | Select-String "OTP Email"

Write-Host "`n=== Testing Complete ===" -ForegroundColor Cyan
Write-Host "`nTo test the full flow:" -ForegroundColor Yellow
Write-Host "1. Run: flutter run" -ForegroundColor White
Write-Host "2. Register a new user" -ForegroundColor White
Write-Host "3. Check logs above for the 6-digit OTP" -ForegroundColor White
Write-Host "4. Enter OTP in the app" -ForegroundColor White
Write-Host "5. Login with the verified account" -ForegroundColor White
