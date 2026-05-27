# Phase 1 Backend APIs - PowerShell Testing Script
# This script tests all 35 endpoints using curl

$BASE_URL = "http://localhost:8000/api/v1"
$PROVIDER_TOKEN = ""
$CUSTOMER_TOKEN = ""
$SERVICE_ID = ""
$BOOKING_ID = ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Phase 1 Backend APIs - Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to make API calls
function Invoke-ApiTest {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [string]$Body = "",
        [string]$Token = "",
        [switch]$NoAuth
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  $Method $Endpoint" -ForegroundColor Gray
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not $NoAuth -and $Token) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri "$BASE_URL$Endpoint" -Method $Method -Headers $headers -Body $Body -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri "$BASE_URL$Endpoint" -Method $Method -Headers $headers -ErrorAction Stop
        }
        
        Write-Host "  ✓ Success" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}


# ========================================
# 1. AUTHENTICATION TESTS
# ========================================
Write-Host "`n1. AUTHENTICATION TESTS" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan

# 1.1 Register Customer
$customerBody = @{
    name = "Test Customer"
    email = "customer@test.com"
    password = "Test1234"
    password_confirmation = "Test1234"
    role = "customer"
} | ConvertTo-Json

$response = Invoke-ApiTest -Name "Register Customer" -Method "POST" -Endpoint "/auth/jwt/register" -Body $customerBody -NoAuth
if ($response -and $response.data.access_token) {
    $script:CUSTOMER_TOKEN = $response.data.access_token
    Write-Host "  → Customer token saved" -ForegroundColor Green
}

# 1.2 Register Provider
$providerBody = @{
    name = "Test Provider"
    email = "provider@test.com"
    password = "Test1234"
    password_confirmation = "Test1234"
    role = "serviceProvider"
} | ConvertTo-Json

$response = Invoke-ApiTest -Name "Register Provider" -Method "POST" -Endpoint "/auth/jwt/register" -Body $providerBody -NoAuth
if ($response -and $response.data.access_token) {
    $script:PROVIDER_TOKEN = $response.data.access_token
    Write-Host "  → Provider token saved" -ForegroundColor Green
}

# 1.3 Login Customer
$loginBody = @{
    email = "customer@test.com"
    password = "Test1234"
} | ConvertTo-Json

$response = Invoke-ApiTest -Name "Login Customer" -Method "POST" -Endpoint "/auth/jwt/login" -Body $loginBody -NoAuth
if ($response -and $response.data.access_token) {
    $script:CUSTOMER_TOKEN = $response.data.access_token
}

# 1.4 Login Provider
$loginBody = @{
    email = "provider@test.com"
    password = "Test1234"
} | ConvertTo-Json

$response = Invoke-ApiTest -Name "Login Provider" -Method "POST" -Endpoint "/auth/jwt/login" -Body $loginBody -NoAuth
if ($response -and $response.data.access_token) {
    $script:PROVIDER_TOKEN = $response.data.access_token
}

# 1.5 Get Current User
Invoke-ApiTest -Name "Get Current User" -Method "GET" -Endpoint "/auth/jwt/me" -Token $PROVIDER_TOKEN


# ========================================
# 2. SERVICES - PUBLIC TESTS
# ========================================
Write-Host "`n2. SERVICES - PUBLIC TESTS" -ForegroundColor Cyan
Write-Host "---------------------------" -ForegroundColor Cyan

Invoke-ApiTest -Name "Browse Services" -Method "GET" -Endpoint "/services" -NoAuth
Invoke-ApiTest -Name "Search Services" -Method "GET" -Endpoint "/services/search?q=cleaning" -NoAuth
Invoke-ApiTest -Name "Get Categories" -Method "GET" -Endpoint "/services/categories" -NoAuth

# ========================================
# 3. SERVICES - PROVIDER TESTS
# ========================================
Write-Host "`n3. SERVICES - PROVIDER TESTS" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan

# 3.1 Create Service
$serviceBody = @{
    name = "House Cleaning Service"
    description = "Professional house cleaning service with experienced staff"
    category = "Cleaning"
    price = 1500
    duration_minutes = 120
    currency = "NPR"
} | ConvertTo-Json

$response = Invoke-ApiTest -Name "Create Service" -Method "POST" -Endpoint "/provider/services" -Body $serviceBody -Token $PROVIDER_TOKEN
if ($response -and $response.data.id) {
    $script:SERVICE_ID = $response.data.id
    Write-Host "  → Service ID saved: $SERVICE_ID" -ForegroundColor Green
}

# 3.2 List My Services
Invoke-ApiTest -Name "List My Services" -Method "GET" -Endpoint "/provider/services" -Token $PROVIDER_TOKEN

# 3.3 Get Service Details
if ($SERVICE_ID) {
    Invoke-ApiTest -Name "Get Service Details" -Method "GET" -Endpoint "/provider/services/$SERVICE_ID" -Token $PROVIDER_TOKEN
    Invoke-ApiTest -Name "Get Service Details (Public)" -Method "GET" -Endpoint "/services/$SERVICE_ID" -NoAuth
}

# 3.4 Update Service
if ($SERVICE_ID) {
    $updateBody = @{
        name = "Premium House Cleaning Service"
        description = "Premium house cleaning with eco-friendly products"
        category = "Cleaning"
        price = 2000
        duration_minutes = 150
        currency = "NPR"
    } | ConvertTo-Json
    
    Invoke-ApiTest -Name "Update Service" -Method "PUT" -Endpoint "/provider/services/$SERVICE_ID" -Body $updateBody -Token $PROVIDER_TOKEN
}

# 3.5 Update Service Status
if ($SERVICE_ID) {
    $statusBody = @{
        status = "active"
    } | ConvertTo-Json
    
    Invoke-ApiTest -Name "Update Service Status" -Method "PATCH" -Endpoint "/provider/services/$SERVICE_ID/status" -Body $statusBody -Token $PROVIDER_TOKEN
}


# ========================================
# 4. BOOKINGS - CUSTOMER TESTS
# ========================================
Write-Host "`n4. BOOKINGS - CUSTOMER TESTS" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan

# 4.1 Create Booking
if ($SERVICE_ID) {
    $bookingBody = @{
        service_id = $SERVICE_ID
        scheduled_at = "2026-06-01 10:00:00"
        notes = "Please bring cleaning supplies"
    } | ConvertTo-Json
    
    $response = Invoke-ApiTest -Name "Create Booking" -Method "POST" -Endpoint "/customer/bookings" -Body $bookingBody -Token $CUSTOMER_TOKEN
    if ($response -and $response.data.id) {
        $script:BOOKING_ID = $response.data.id
        Write-Host "  → Booking ID saved: $BOOKING_ID" -ForegroundColor Green
    }
}

# 4.2 List My Bookings
Invoke-ApiTest -Name "List My Bookings" -Method "GET" -Endpoint "/customer/bookings" -Token $CUSTOMER_TOKEN

# 4.3 Get Booking Details
if ($BOOKING_ID) {
    Invoke-ApiTest -Name "Get Booking Details" -Method "GET" -Endpoint "/customer/bookings/$BOOKING_ID" -Token $CUSTOMER_TOKEN
}

# 4.4 Check Availability
if ($SERVICE_ID) {
    Invoke-ApiTest -Name "Check Availability" -Method "GET" -Endpoint "/customer/bookings/check-availability?service_id=$SERVICE_ID&date=2026-06-01" -Token $CUSTOMER_TOKEN
}

# ========================================
# 5. BOOKINGS - PROVIDER TESTS
# ========================================
Write-Host "`n5. BOOKINGS - PROVIDER TESTS" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan

# 5.1 List Bookings
Invoke-ApiTest -Name "List Bookings" -Method "GET" -Endpoint "/provider/bookings" -Token $PROVIDER_TOKEN

# 5.2 Get Pending Bookings
Invoke-ApiTest -Name "Get Pending Bookings" -Method "GET" -Endpoint "/provider/bookings/pending" -Token $PROVIDER_TOKEN

# 5.3 Get Booking Details
if ($BOOKING_ID) {
    Invoke-ApiTest -Name "Get Booking Details (Provider)" -Method "GET" -Endpoint "/provider/bookings/$BOOKING_ID" -Token $PROVIDER_TOKEN
}

# 5.4 Accept Booking
if ($BOOKING_ID) {
    Invoke-ApiTest -Name "Accept Booking" -Method "POST" -Endpoint "/provider/bookings/$BOOKING_ID/accept" -Token $PROVIDER_TOKEN
}

# 5.5 Complete Booking
if ($BOOKING_ID) {
    Invoke-ApiTest -Name "Complete Booking" -Method "POST" -Endpoint "/provider/bookings/$BOOKING_ID/complete" -Token $PROVIDER_TOKEN
}

# 5.6 Get Booking Statistics
Invoke-ApiTest -Name "Get Booking Statistics" -Method "GET" -Endpoint "/provider/bookings/stats?date_from=2026-05-01&date_to=2026-05-31" -Token $PROVIDER_TOKEN


# ========================================
# 6. PROFILE TESTS
# ========================================
Write-Host "`n6. PROFILE TESTS" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan

# 6.1 Get Profile
Invoke-ApiTest -Name "Get Profile" -Method "GET" -Endpoint "/profile" -Token $CUSTOMER_TOKEN

# 6.2 Update Profile
$profileBody = @{
    name = "Updated Customer Name"
    phone_number = "+977-9841234567"
    address = "Kathmandu, Nepal"
} | ConvertTo-Json

Invoke-ApiTest -Name "Update Profile" -Method "PUT" -Endpoint "/profile" -Body $profileBody -Token $CUSTOMER_TOKEN

# ========================================
# 7. PROVIDER DASHBOARD TESTS
# ========================================
Write-Host "`n7. PROVIDER DASHBOARD TESTS" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# 7.1 Get Provider Profile
Invoke-ApiTest -Name "Get Provider Profile" -Method "GET" -Endpoint "/provider/profile" -Token $PROVIDER_TOKEN

# 7.2 Update Provider Profile
$providerProfileBody = @{
    name = "Updated Provider Name"
    phone_number = "+977-9841234567"
    address = "Kathmandu, Nepal"
} | ConvertTo-Json

Invoke-ApiTest -Name "Update Provider Profile" -Method "PUT" -Endpoint "/provider/profile" -Body $providerProfileBody -Token $PROVIDER_TOKEN

# 7.3 Get Dashboard
Invoke-ApiTest -Name "Get Dashboard" -Method "GET" -Endpoint "/provider/dashboard" -Token $PROVIDER_TOKEN

# 7.4 Get Earnings
Invoke-ApiTest -Name "Get Earnings" -Method "GET" -Endpoint "/provider/earnings?date_from=2026-05-01&date_to=2026-05-31&group_by=day" -Token $PROVIDER_TOKEN

# ========================================
# SUMMARY
# ========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Provider Token: $($PROVIDER_TOKEN.Substring(0, 20))..." -ForegroundColor Gray
Write-Host "Customer Token: $($CUSTOMER_TOKEN.Substring(0, 20))..." -ForegroundColor Gray
Write-Host "Service ID: $SERVICE_ID" -ForegroundColor Gray
Write-Host "Booking ID: $BOOKING_ID" -ForegroundColor Gray
Write-Host "`nAll tests completed!" -ForegroundColor Green
Write-Host "Check the output above for any failures." -ForegroundColor Yellow
