# AI Visual Assistant API - Quick Reference

## Base URL
```
http://localhost:8000/api/v1/customer/ai
```

## Authentication
All endpoints require JWT Bearer token in Authorization header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

## Rate Limiting
- **Limit:** 10 requests per minute per user
- **Response on exceed:** 429 Too Many Requests

---

## Endpoints

### 1. Create Consultation
**POST** `/consultations`

Creates a new AI consultation with image analysis.

**Request Body:**
```json
{
  "image": "base64_encoded_image_string",
  "markers": [
    {
      "x": 0.45,
      "y": 0.32,
      "description": "Water leaking from pipe joint"
    }
  ]
}
```

**Validation Rules:**
- `image`: required, base64 string, max 10MB decoded
- `markers`: required, array, min 1, max 10
- `markers.*.x`: required, numeric, 0.0-1.0
- `markers.*.y`: required, numeric, 0.0-1.0
- `markers.*.description`: required, string, 2-500 chars

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Consultation created successfully",
  "data": {
    "consultation": {
      "id": "uuid",
      "image_url": "https://...",
      "markers": [...],
      "diagnosis": "AI diagnosis text",
      "recommended_service_type": "Plumbing Repair",
      "cost_min": 2000.00,
      "cost_max": 5000.00,
      "recommended_providers": [
        {
          "id": "uuid",
          "name": "Provider Name",
          "rating": 4.5,
          "services": ["Service 1"]
        }
      ],
      "processing_time_ms": 27000,
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

---

### 2. Get Consultation History
**GET** `/consultations`

Retrieves paginated list of consultations for authenticated customer.

**Query Parameters:**
- `page` (optional): Page number, default 1
- `per_page` (optional): Items per page, default 20, max 50
- `service_type` (optional): Filter by service type

**Example:**
```
GET /consultations?page=1&per_page=20&service_type=Plumbing%20Repair
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "consultations": [
      {
        "id": "uuid",
        "image_url": "https://...",
        "diagnosis": "Brief diagnosis",
        "recommended_service_type": "Plumbing Repair",
        "cost_min": 2000.00,
        "cost_max": 5000.00,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 45,
      "last_page": 3
    }
  }
}
```

---

### 3. Get Consultation Details
**GET** `/consultations/{id}`

Retrieves full details of a specific consultation.

**Path Parameters:**
- `id`: Consultation UUID

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "consultation": {
      "id": "uuid",
      "image_url": "https://...",
      "markers": [
        {
          "x": 0.45,
          "y": 0.32,
          "description": "Water leak"
        }
      ],
      "diagnosis": "Full diagnosis text",
      "recommended_service_type": "Plumbing Repair",
      "cost_min": 2000.00,
      "cost_max": 5000.00,
      "recommended_providers": [...],
      "processing_time_ms": 27000,
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

**Error Responses:**
- `404 Not Found`: Consultation doesn't exist
- `403 Forbidden`: Unauthorized access (not owner)

---

### 4. Delete Consultation
**DELETE** `/consultations/{id}`

Soft deletes a consultation (can be recovered).

**Path Parameters:**
- `id`: Consultation UUID

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Consultation deleted successfully"
}
```

**Error Responses:**
- `404 Not Found`: Consultation doesn't exist
- `403 Forbidden`: Unauthorized access (not owner)

---

## Error Responses

### Validation Error (422)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "image": ["An image is required to create a consultation."],
    "markers": ["You cannot add more than 10 defect markers."]
  }
}
```

### Unauthorized (401)
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

### Forbidden (403)
```json
{
  "success": false,
  "message": "Unauthorized access to this consultation"
}
```

### Not Found (404)
```json
{
  "success": false,
  "message": "Consultation not found"
}
```

### Rate Limit Exceeded (429)
```json
{
  "success": false,
  "message": "Too Many Requests"
}
```

### Server Error (500)
```json
{
  "success": false,
  "message": "Failed to create consultation. Please try again later."
}
```

---

## Service Types

Valid service types returned by AI:
1. Plumbing Repair
2. Electrical Work
3. Carpentry
4. Painting
5. Cleaning
6. Appliance Repair
7. HVAC
8. Pest Control
9. Landscaping
10. General Maintenance

---

## Image Requirements

**Supported Formats:**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic)

**Size Limits:**
- Minimum: 100 KB
- Maximum: 10 MB
- Auto-compression: Images > 5MB compressed to max 1920x1920

**Encoding:**
- Base64 encoded string
- Can include data URI scheme: `data:image/jpeg;base64,`

---

## Marker Coordinates

Markers use normalized coordinates (0.0 to 1.0):
- `x`: Horizontal position (0.0 = left, 1.0 = right)
- `y`: Vertical position (0.0 = top, 1.0 = bottom)

**Example:**
- Center of image: `x: 0.5, y: 0.5`
- Top-left corner: `x: 0.0, y: 0.0`
- Bottom-right corner: `x: 1.0, y: 1.0`

---

## Cost Estimates

**Currency:** NPR (Nepali Rupees)

**Range:**
- Minimum: NPR 500
- Maximum: NPR 50,000
- Default (uncertain): NPR 1,000 - 5,000

**Format:**
- `cost_min`: Minimum estimated cost
- `cost_max`: Maximum estimated cost (at least 1.5x min)

---

## Processing Time

**Typical Duration:** 15-35 seconds

**Breakdown:**
- Image encoding: 50-200ms
- AI analysis: 15-30 seconds
- Provider matching: 100-500ms

**Timeout:** 30 seconds (configurable)

---

## Example cURL Commands

### Create Consultation
```bash
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "BASE64_IMAGE_DATA",
    "markers": [
      {"x": 0.45, "y": 0.32, "description": "Water leak"}
    ]
  }'
```

### Get History
```bash
curl -X GET "http://localhost:8000/api/v1/customer/ai/consultations?page=1&per_page=20" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Get Details
```bash
curl -X GET "http://localhost:8000/api/v1/customer/ai/consultations/CONSULTATION_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Delete Consultation
```bash
curl -X DELETE "http://localhost:8000/api/v1/customer/ai/consultations/CONSULTATION_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Implementation Status

**Completed (6/27 tasks - 22.2%):**
- ✅ Database schema
- ✅ Eloquent model
- ✅ AI service integration
- ✅ Request validation
- ✅ All CRUD endpoints
- ✅ Rate limiting

**Remaining:**
- Backend: Image storage service, cleanup command, tests
- Flutter: Complete mobile app implementation (16 tasks)

---

## Technical Details

**AI Model:** Qwen 3.5 Vision (qwen3-vl:2b)
**AI Service:** Ollama at http://gharsewa_ollama:11434
**Database:** MySQL with UUID primary keys
**Storage:** Laravel Storage (public disk)
**Authentication:** JWT tokens
**Framework:** Laravel 11

---

## Support

For issues or questions:
1. Check Laravel logs: `storage/logs/laravel.log`
2. Check Ollama logs: `docker logs gharsewa_ollama`
3. Verify services: `docker ps`
4. Review testing guide: `AI_VISUAL_ASSISTANT_TESTING_GUIDE.md`
