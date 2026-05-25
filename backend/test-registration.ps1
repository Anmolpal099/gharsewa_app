# Test Registration API Endpoint
# This script tests the JWT registration endpoint with various scenarios

$API_URL = "http://localhost:8000/api/v1/auth/jwt/register"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Testing Registration API Endpoint" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Successful Registration
Write-Host "Test 1: Successful Registration (Customer)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body1 = @{
    name = "John Doe"
    email = "john.doe@example.com"
    password = "Password123"
    role = "customer"
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body1 -ContentType "application/json"
    $response1 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host ""

# Test 2: Successful Registration (Service Provider)
Write-Host "Test 2: Successful Registration (Service Provider)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body2 = @{
    name = "Jane Smith"
    email = "jane.smith@example.com"
    password = "SecurePass456"
    role = "serviceProvider"
} | ConvertTo-Json

try {
    $response2 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body2 -ContentType "application/json"
    $response2 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host ""

# Test 3: Duplicate Email
Write-Host "Test 3: Duplicate Email (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body3 = @{
    name = "Another User"
    email = "john.doe@example.com"
    password = "Password123"
    role = "customer"
} | ConvertTo-Json

try {
    $response3 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body3 -ContentType "application/json"
    $response3 | ConvertTo-Json -Depth 10
} catch {
    $_.Exception.Response | ConvertTo-Json -Depth 10
}
Write-Host ""
Write-Host ""

# Test 4: Invalid Email Format
Write-Host "Test 4: Invalid Email Format (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body4 = @{
    name = "Test User"
    email = "invalid-email"
    password = "Password123"
    role = "customer"
} | ConvertTo-Json

try {
    $response4 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body4 -ContentType "application/json"
    $response4 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Validation Error (Expected)" -ForegroundColor Green
}
Write-Host ""
Write-Host ""

# Test 5: Weak Password
Write-Host "Test 5: Weak Password (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body5 = @{
    name = "Test User"
    email = "test@example.com"
    password = "weak"
    role = "customer"
} | ConvertTo-Json

try {
    $response5 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body5 -ContentType "application/json"
    $response5 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Validation Error (Expected)" -ForegroundColor Green
}
Write-Host ""
Write-Host ""

# Test 6: Password Without Uppercase
Write-Host "Test 6: Password Without Uppercase (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body6 = @{
    name = "Test User"
    email = "test2@example.com"
    password = "password123"
    role = "customer"
} | ConvertTo-Json

try {
    $response6 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body6 -ContentType "application/json"
    $response6 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Validation Error (Expected)" -ForegroundColor Green
}
Write-Host ""
Write-Host ""

# Test 7: Password Without Number
Write-Host "Test 7: Password Without Number (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body7 = @{
    name = "Test User"
    email = "test3@example.com"
    password = "PasswordOnly"
    role = "customer"
} | ConvertTo-Json

try {
    $response7 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body7 -ContentType "application/json"
    $response7 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Validation Error (Expected)" -ForegroundColor Green
}
Write-Host ""
Write-Host ""

# Test 8: Invalid Role
Write-Host "Test 8: Invalid Role (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body8 = @{
    name = "Test User"
    email = "test4@example.com"
    password = "Password123"
    role = "invalid_role"
} | ConvertTo-Json

try {
    $response8 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body8 -ContentType "application/json"
    $response8 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Validation Error (Expected)" -ForegroundColor Green
}
Write-Host ""
Write-Host ""

# Test 9: Missing Required Fields
Write-Host "Test 9: Missing Required Fields (Should Fail)" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow
$body9 = @{
    name = "Test User"
} | ConvertTo-Json

try {
    $response9 = Invoke-RestMethod -Uri $API_URL -Method Post -Body $body9 -ContentType "application/json"
    $response9 | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Validation Error (Expected)" -ForegroundColor Green
}
Write-Host ""
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "All Tests Completed" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
