# Simple Profile Management Test Script

Write-Host "Profile Management Endpoints Test" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8000/api/v1"

# Register and login
Write-Host "`n1. Registering test user..." -ForegroundColor Yellow
$registerData = @{
    name = "Profile Test"
    email = "profiletest@example.com"
    password = "Test1234"
    password_confirmation = "Test1234"
    role = "customer"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$baseUrl/auth/jwt/register" -Method Post -Body $registerData -ContentType "application/json" | Out-Null
    Write-Host "User registered" -ForegroundColor Green
} catch {
    Write-Host "User exists, continuing..." -ForegroundColor Yellow
}

# Login
Write-Host "`n2. Logging in..." -ForegroundColor Yellow
$loginData = @{
    email = "profiletest@example.com"
    password = "Test1234"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/jwt/login" -Method Post -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.access_token
Write-Host "Login successful" -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Test 1: GET Profile
Write-Host "`n3. Testing GET Profile..." -ForegroundColor Yellow
$profile = Invoke-RestMethod -Uri "$baseUrl/profile" -Method Get -Headers $headers

if ($profile.success) {
    Write-Host "SUCCESS: GET Profile" -ForegroundColor Green
    Write-Host "  Name: $($profile.data.name)" -ForegroundColor Gray
    Write-Host "  Email: $($profile.data.email)" -ForegroundColor Gray
    Write-Host "  Role: $($profile.data.role)" -ForegroundColor Gray
} else {
    Write-Host "FAILED: GET Profile" -ForegroundColor Red
}

# Test 2: UPDATE Profile
Write-Host "`n4. Testing UPDATE Profile..." -ForegroundColor Yellow
$updateData = @{
    name = "Updated Name"
    phone_number = "9876543210"
    address = "Test Address"
} | ConvertTo-Json

$updateResult = Invoke-RestMethod -Uri "$baseUrl/profile" -Method Put -Headers $headers -Body $updateData

if ($updateResult.success) {
    Write-Host "SUCCESS: UPDATE Profile" -ForegroundColor Green
    Write-Host "  New Name: $($updateResult.data.name)" -ForegroundColor Gray
    Write-Host "  New Phone: $($updateResult.data.phone_number)" -ForegroundColor Gray
} else {
    Write-Host "FAILED: UPDATE Profile" -ForegroundColor Red
}

# Test 3: Validation
Write-Host "`n5. Testing Validation..." -ForegroundColor Yellow
$invalidData = @{
    name = "x" * 300
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$baseUrl/profile" -Method Put -Headers $headers -Body $invalidData | Out-Null
    Write-Host "FAILED: Validation should have rejected" -ForegroundColor Red
} catch {
    Write-Host "SUCCESS: Validation working (rejected invalid data)" -ForegroundColor Green
}

# Test 4: Authentication Required
Write-Host "`n6. Testing Authentication Requirement..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$baseUrl/profile" -Method Get | Out-Null
    Write-Host "FAILED: Should require authentication" -ForegroundColor Red
} catch {
    Write-Host "SUCCESS: Authentication required" -ForegroundColor Green
}

Write-Host "`n===================================" -ForegroundColor Cyan
Write-Host "All Tests Completed!" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
