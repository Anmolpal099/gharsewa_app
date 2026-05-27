# AI Visual Assistant - Testing Guide

## Overview

This guide provides step-by-step instructions for testing the AI Visual Assistant backend API that has been implemented.

**Completed Features:**
- ✅ Database schema and migration
- ✅ AIConsultation model with relationships
- ✅ VisionAIService with Ollama integration
- ✅ Request validation with custom rules
- ✅ Complete CRUD API endpoints

## Prerequisites

### 1. Ensure Services are Running

```bash
# Check if Docker containers are running
docker ps

# You should see:
# - gharsewa_app (Laravel application)
# - gharsewa_db (MySQL database)
# - gharsewa_ollama (Ollama AI service)

# If Ollama is not running, start it:
docker-compose -f docker-compose.ollama.yml up -d
```

### 2. Verify Database Migration

```bash
# Check if ai_consultations table exists
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "DESCRIBE ai_consultations;"

# Expected output: Table structure with 15 columns
```

### 3. Verify Ollama Model

```bash
# Check if qwen3-vl:2b model is available
curl http://localhost:11434/api/tags

# Expected: JSON response with list of models including qwen3-vl:2b
```

## API Endpoints to Test

### Base URL
```
http://localhost:8000/api/v1/customer/ai
```

### Authentication
All endpoints require JWT authentication. You'll need a valid JWT token for a customer user.

## Step-by-Step Testing

### Step 1: Get Authentication Token

```bash
# Register a new customer (if needed)
curl -X POST http://localhost:8000/api/v1/auth/jwt/register \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Test Customer",
    "email": "testcustomer@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "customer"
  }'

# Login to get JWT token
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "testcustomer@example.com",
    "password": "password123"
  }'

# Save the "access_token" from the response
# Example: export JWT_TOKEN="your_token_here"
```

### Step 2: Prepare Test Image

Create a test image in base64 format:

```bash
# Option 1: Use an existing image
base64 -w 0 test_image.jpg > image_base64.txt

# Option 2: Create a simple test image using PHP
php -r '
$img = imagecreatetruecolor(800, 600);
$bg = imagecolorallocate($img, 200, 200, 200);
imagefill($img, 0, 0, $bg);
$red = imagecolorallocate($img, 255, 0, 0);
imagefilledellipse($img, 300, 200, 100, 100, $red);
ob_start();
imagejpeg($img, null, 85);
$data = ob_get_clean();
echo base64_encode($data);
imagedestroy($img);
' > image_base64.txt
```

### Step 3: Test Create Consultation (POST)

```bash
# Read the base64 image
IMAGE_BASE64=$(cat image_base64.txt)

# Create consultation
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"image\": \"$IMAGE_BASE64\",
    \"markers\": [
      {
        \"x\": 0.45,
        \"y\": 0.32,
        \"description\": \"Water leaking from pipe joint\"
      },
      {
        \"x\": 0.67,
        \"y\": 0.58,
        \"description\": \"Rust visible on metal surface\"
      }
    ]
  }"

# Expected Response (201 Created):
# {
#   "success": true,
#   "message": "Consultation created successfully",
#   "data": {
#     "consultation": {
#       "id": "uuid",
#       "image_url": "http://...",
#       "markers": [...],
#       "diagnosis": "AI diagnosis text",
#       "recommended_service_type": "Service Type",
#       "cost_min": 1000.00,
#       "cost_max": 5000.00,
#       "recommended_providers": [...],
#       "processing_time_ms": 27000,
#       "created_at": "2024-01-15T10:30:00Z"
#     }
#   }
# }

# Save the consultation ID for next tests
# export CONSULTATION_ID="uuid_from_response"
```

### Step 4: Test Get Consultation History (GET)

```bash
# Get all consultations (default pagination)
curl -X GET http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Accept: application/json'

# Expected Response (200 OK):
# {
#   "success": true,
#   "data": {
#     "consultations": [...],
#     "pagination": {
#       "current_page": 1,
#       "per_page": 20,
#       "total": 1,
#       "last_page": 1
#     }
#   }
# }

# Test with pagination parameters
curl -X GET "http://localhost:8000/api/v1/customer/ai/consultations?page=1&per_page=10" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Accept: application/json'

# Test with service type filter
curl -X GET "http://localhost:8000/api/v1/customer/ai/consultations?service_type=Plumbing%20Repair" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Accept: application/json'
```

### Step 5: Test Get Consultation Details (GET)

```bash
# Get specific consultation by ID
curl -X GET "http://localhost:8000/api/v1/customer/ai/consultations/$CONSULTATION_ID" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Accept: application/json'

# Expected Response (200 OK):
# {
#   "success": true,
#   "data": {
#     "consultation": {
#       "id": "uuid",
#       "image_url": "http://...",
#       "markers": [...],
#       "diagnosis": "Full diagnosis",
#       "recommended_service_type": "Service Type",
#       "cost_min": 1000.00,
#       "cost_max": 5000.00,
#       "recommended_providers": [...],
#       "processing_time_ms": 27000,
#       "created_at": "2024-01-15T10:30:00Z"
#     }
#   }
# }
```

### Step 6: Test Delete Consultation (DELETE)

```bash
# Delete consultation
curl -X DELETE "http://localhost:8000/api/v1/customer/ai/consultations/$CONSULTATION_ID" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Accept: application/json'

# Expected Response (200 OK):
# {
#   "success": true,
#   "message": "Consultation deleted successfully"
# }

# Verify deletion - should return 404
curl -X GET "http://localhost:8000/api/v1/customer/ai/consultations/$CONSULTATION_ID" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Accept: application/json'

# Expected Response (404 Not Found):
# {
#   "success": false,
#   "message": "Consultation not found"
# }
```

## Testing Error Scenarios

### Test 1: Invalid Image Format

```bash
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "image": "not_valid_base64",
    "markers": [{"x": 0.5, "y": 0.5, "description": "Test"}]
  }'

# Expected: 422 Validation Error
```

### Test 2: Missing Markers

```bash
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"image\": \"$IMAGE_BASE64\",
    \"markers\": []
  }"

# Expected: 422 Validation Error - "At least one defect marker is required"
```

### Test 3: Too Many Markers

```bash
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"image\": \"$IMAGE_BASE64\",
    \"markers\": [
      {\"x\": 0.1, \"y\": 0.1, \"description\": \"Marker 1\"},
      {\"x\": 0.2, \"y\": 0.2, \"description\": \"Marker 2\"},
      {\"x\": 0.3, \"y\": 0.3, \"description\": \"Marker 3\"},
      {\"x\": 0.4, \"y\": 0.4, \"description\": \"Marker 4\"},
      {\"x\": 0.5, \"y\": 0.5, \"description\": \"Marker 5\"},
      {\"x\": 0.6, \"y\": 0.6, \"description\": \"Marker 6\"},
      {\"x\": 0.7, \"y\": 0.7, \"description\": \"Marker 7\"},
      {\"x\": 0.8, \"y\": 0.8, \"description\": \"Marker 8\"},
      {\"x\": 0.9, \"y\": 0.9, \"description\": \"Marker 9\"},
      {\"x\": 0.95, \"y\": 0.95, \"description\": \"Marker 10\"},
      {\"x\": 0.99, \"y\": 0.99, \"description\": \"Marker 11\"}
    ]
  }"

# Expected: 422 Validation Error - "You cannot add more than 10 defect markers"
```

### Test 4: Invalid Coordinates

```bash
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"image\": \"$IMAGE_BASE64\",
    \"markers\": [
      {\"x\": 1.5, \"y\": 0.5, \"description\": \"Invalid X coordinate\"}
    ]
  }"

# Expected: 422 Validation Error - "Marker X coordinate must be between 0 and 1"
```

### Test 5: Unauthorized Access

```bash
# Try to access without token
curl -X GET http://localhost:8000/api/v1/customer/ai/consultations \
  -H 'Accept: application/json'

# Expected: 401 Unauthorized
```

### Test 6: Rate Limiting

```bash
# Send 11 requests rapidly (limit is 10 per minute)
for i in {1..11}; do
  curl -X GET http://localhost:8000/api/v1/customer/ai/consultations \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H 'Accept: application/json'
  echo "Request $i"
done

# Expected: First 10 succeed, 11th returns 429 Too Many Requests
```

## Verification Checklist

### Database Verification

```bash
# Check if consultations are being stored
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT id, customer_id, recommended_service_type, cost_min, cost_max, created_at FROM ai_consultations;"

# Check if images are being stored
docker exec gharsewa_app ls -lh /var/www/storage/app/public/consultations/

# Check soft deletes
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT id, deleted_at FROM ai_consultations WHERE deleted_at IS NOT NULL;"
```

### Log Verification

```bash
# Check Laravel logs for any errors
docker exec gharsewa_app tail -f /var/www/storage/logs/laravel.log

# Check for AI service logs
docker logs gharsewa_ollama --tail 50
```

### Performance Testing

```bash
# Measure response time for consultation creation
time curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"image\": \"$IMAGE_BASE64\",
    \"markers\": [{\"x\": 0.5, \"y\": 0.5, \"description\": \"Test marker\"}]
  }"

# Expected: 15-35 seconds (AI processing time)
```

## Postman Collection

For easier testing, you can import this Postman collection:

**Collection Name:** AI Visual Assistant API

**Variables:**
- `base_url`: http://localhost:8000/api/v1
- `jwt_token`: (set after login)
- `consultation_id`: (set after creating consultation)

**Requests:**
1. Auth - Login
2. Create Consultation
3. Get Consultation History
4. Get Consultation Details
5. Delete Consultation

## Troubleshooting

### Issue: "Ollama API error"

**Solution:**
```bash
# Restart Ollama service
docker-compose -f docker-compose.ollama.yml restart

# Check if model is loaded
curl http://localhost:11434/api/tags
```

### Issue: "Image file not found"

**Solution:**
```bash
# Check storage permissions
docker exec gharsewa_app chmod -R 775 /var/www/storage
docker exec gharsewa_app chown -R www-data:www-data /var/www/storage
```

### Issue: "Validation failed"

**Solution:**
- Check that image is properly base64 encoded
- Verify markers array has 1-10 items
- Ensure coordinates are between 0 and 1
- Check description length (2-500 characters)

### Issue: "Unauthorized"

**Solution:**
- Verify JWT token is valid and not expired
- Check that user has 'customer' role
- Ensure Authorization header is set correctly

## Next Steps

After verifying the backend API works correctly:

1. **Document any issues found** in the testing process
2. **Create sample data** for demonstration purposes
3. **Prepare for Flutter integration** (Tasks 12-27)
4. **Consider performance optimizations** if needed

## Summary

**Implemented Endpoints:**
- ✅ POST `/api/v1/customer/ai/consultations` - Create consultation
- ✅ GET `/api/v1/customer/ai/consultations` - List consultations
- ✅ GET `/api/v1/customer/ai/consultations/{id}` - Get details
- ✅ DELETE `/api/v1/customer/ai/consultations/{id}` - Delete consultation

**Features Verified:**
- ✅ JWT Authentication
- ✅ Request Validation
- ✅ Image Processing & Storage
- ✅ AI Analysis with Ollama
- ✅ Provider Recommendations
- ✅ Pagination
- ✅ Service Type Filtering
- ✅ Authorization
- ✅ Soft Deletes
- ✅ Rate Limiting
- ✅ Error Handling

**Ready for:** Flutter frontend integration (Tasks 12-27)
