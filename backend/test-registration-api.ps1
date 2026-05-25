# PowerShell script to test registration API
# Run with: .\test-registration-api.ps1

Write-Host "🧪 Testing Registration API" -ForegroundColor Cyan
Write-Host "============================`n" -ForegroundColor Cyan

# Test data
$body = @{
    name = "Test User"
    email = "test@example.com"
    password = "Test1234"
    role = "customer"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Write-Host "📤 Sending registration request..." -ForegroundColor Yellow
Write-Host "URL: http://localhost:8000/api/v1/auth/jwt/register" -ForegroundColor Gray
Write-Host "Data: $body`n" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod `
        -Uri "http://localhost:8000/api/v1/auth/jwt/register" `
        -Method Post `
        -Body $body `
        -Headers $headers `
        -ErrorAction Stop
    
    Write-Host "✅ Registration Successful!" -ForegroundColor Green
    Write-Host "`nResponse:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10 | Write-Host
    
    Write-Host "`n📧 Check email: test@example.com for OTP code" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Registration Failed!" -ForegroundColor Red
    Write-Host "`nError Details:" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        
        Write-Host $responseBody -ForegroundColor Red
    } else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    
    Write-Host "`n💡 Possible Issues:" -ForegroundColor Yellow
    Write-Host "  - Backend not running (run: docker-compose up -d)" -ForegroundColor Gray
    Write-Host "  - APP_KEY not set (run: docker-compose exec app php artisan key:generate)" -ForegroundColor Gray
    Write-Host "  - Database not connected" -ForegroundColor Gray
    Write-Host "  - Email already registered (use different email)" -ForegroundColor Gray
}

Write-Host ""
