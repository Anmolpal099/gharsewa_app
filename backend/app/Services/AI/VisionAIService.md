# VisionAIService Documentation

## Overview

The `VisionAIService` class extends the base `AIService` to provide specialized image analysis capabilities for the AI Visual Assistant feature. It integrates with the Ollama service running the Qwen 3.5 Vision model (qwen3-vl:2b) to analyze images with visual annotations and provide comprehensive home service recommendations.

## Class Location

```
backend/app/Services/AI/VisionAIService.php
```

## Dependencies

- **Extends**: `App\Services\AI\AIService`
- **Uses**:
  - `App\DTOs\AI\AIResponse`
  - `App\Models\User`
  - `App\Models\Service`
  - `Illuminate\Support\Facades\DB`
  - `Illuminate\Support\Facades\Http`
  - `Illuminate\Support\Facades\Log`

## Configuration

The service inherits configuration from the base `AIService` class:

- **Ollama Host**: `http://gharsewa_ollama:11434` (from env: `OLLAMA_HOST`)
- **Model**: `qwen3-vl:2b` (from env: `OLLAMA_MODEL`)
- **Timeout**: 60 seconds (from env: `OLLAMA_TIMEOUT`)
- **Max Retries**: 3 attempts (from env: `AI_MAX_RETRIES`)
- **Retry Delay**: 1000ms with exponential backoff (from env: `AI_RETRY_DELAY`)

## Public Methods

### analyzeImage()

Analyzes an image with markers and descriptions to provide diagnosis and recommendations.

**Signature:**
```php
public function analyzeImage(string $imagePath, array $markers): array
```

**Parameters:**
- `$imagePath` (string): Absolute path to the uploaded image file
- `$markers` (array): Array of marker objects, each containing:
  - `x` (float): Normalized x-coordinate (0.0 to 1.0)
  - `y` (float): Normalized y-coordinate (0.0 to 1.0)
  - `description` (string): Text description of the defect

**Returns:**
Array containing:
- `diagnosis` (string): Problem diagnosis (50-500 characters)
- `service_type` (string): Recommended service category
- `cost_min` (float): Minimum cost estimate in NPR
- `cost_max` (float): Maximum cost estimate in NPR
- `confidence` (float): AI confidence score (0.0 to 1.0)
- `recommended_providers` (array): Top 3 matching providers
- `processing_time_ms` (int): Total processing time in milliseconds
- `model` (string): AI model used

**Throws:**
- `Exception`: If image encoding fails, API call fails after retries, or parsing fails

**Example:**
```php
$service = new VisionAIService();

$markers = [
    ['x' => 0.45, 'y' => 0.32, 'description' => 'Water leaking from pipe joint'],
    ['x' => 0.67, 'y' => 0.58, 'description' => 'Rust visible on metal surface'],
];

try {
    $result = $service->analyzeImage('/path/to/image.jpg', $markers);
    
    echo "Diagnosis: " . $result['diagnosis'];
    echo "Service Type: " . $result['service_type'];
    echo "Cost Range: NPR " . $result['cost_min'] . " - " . $result['cost_max'];
    echo "Providers: " . count($result['recommended_providers']);
} catch (Exception $e) {
    Log::error('Analysis failed: ' . $e->getMessage());
}
```

## Private Methods

### buildVisionPrompt()

Constructs a structured prompt for the vision model including marker information.

**Signature:**
```php
private function buildVisionPrompt(array $markers): string
```

**Parameters:**
- `$markers` (array): Array of marker objects

**Returns:**
- String containing the formatted prompt with instructions and marker details

**Prompt Structure:**
- Expert role definition
- Marker list with positions and descriptions
- Expected JSON response format
- Guidelines for diagnosis and cost estimation
- Valid service type categories

### parseVisionResponse()

Parses the AI's raw text response into structured data with validation and fallbacks.

**Signature:**
```php
private function parseVisionResponse(string $rawResponse): array
```

**Parameters:**
- `$rawResponse` (string): Raw text response from AI

**Returns:**
Array containing validated and sanitized:
- `diagnosis` (string): Truncated to 500 characters
- `service_type` (string): Validated against known categories
- `cost_min` (float): Validated and bounded (500-50000 NPR)
- `cost_max` (float): Validated and bounded (500-50000 NPR)
- `confidence` (float): Confidence score (0.0-1.0)

**Validation Rules:**
1. Extracts JSON from markdown code blocks if present
2. Validates service type against predefined list
3. Ensures cost estimates are positive and within range
4. Ensures max cost is at least 1.5x min cost
5. Falls back to default values if validation fails

**Fallback Values:**
- Diagnosis: "Unable to determine specific issue..."
- Service Type: "General Maintenance"
- Cost Min: 1000 NPR
- Cost Max: 5000 NPR
- Confidence: 0.3

### findMatchingProviders()

Queries the database for service providers matching the diagnosed service type.

**Signature:**
```php
private function findMatchingProviders(string $serviceType, int $limit = 3): array
```

**Parameters:**
- `$serviceType` (string): Service category to match
- `$limit` (int): Maximum number of providers to return (default: 3)

**Returns:**
Array of provider objects, each containing:
- `id` (string): Provider UUID
- `name` (string): Provider name
- `rating` (float): Average rating (0.0-5.0)
- `reviews_count` (int): Number of reviews
- `services` (array): List of service names
- `match_score` (float): Calculated match score (0.0-1.0)

**Matching Logic:**
1. Filters active providers with active services in the category
2. Calculates average rating from reviews
3. Computes match score: `(rating/5.0) * 0.7 + (min(reviews,50)/50.0) * 0.3`
4. Sorts by rating (primary) and match score (secondary)
5. Returns top N providers

**Example Result:**
```php
[
    [
        'id' => 'uuid-1',
        'name' => 'Expert Plumbers',
        'rating' => 4.8,
        'reviews_count' => 45,
        'services' => ['Plumbing Repair', 'Drain Cleaning'],
        'match_score' => 0.95,
    ],
    // ... more providers
]
```

### encodeImageToBase64()

Encodes an image file to base64 format for API transmission.

**Signature:**
```php
private function encodeImageToBase64(string $imagePath): string
```

**Parameters:**
- `$imagePath` (string): Absolute path to image file

**Returns:**
- Base64 encoded string of the image data

**Throws:**
- `Exception`: If file doesn't exist or cannot be read

### callVisionAPIWithRetry()

Calls the Ollama Vision API with exponential backoff retry logic.

**Signature:**
```php
private function callVisionAPIWithRetry(string $imageBase64, string $prompt): AIResponse
```

**Parameters:**
- `$imageBase64` (string): Base64 encoded image
- `$prompt` (string): Vision prompt

**Returns:**
- `AIResponse` object with success/failure status

**Retry Logic:**
- Attempts: 3 (configurable via `maxRetries`)
- Backoff: Exponential (1s, 2s, 4s)
- Logs warnings on each retry
- Throws exception after all retries exhausted

### callVisionAPI()

Makes a single API call to Ollama Vision endpoint.

**Signature:**
```php
private function callVisionAPI(string $imageBase64, string $prompt): AIResponse
```

**Parameters:**
- `$imageBase64` (string): Base64 encoded image
- `$prompt` (string): Vision prompt

**Returns:**
- `AIResponse` object with AI-generated content and metadata

**API Request Format:**
```json
{
  "model": "qwen3-vl:2b",
  "prompt": "...",
  "images": ["base64_encoded_image"],
  "stream": false,
  "options": {
    "num_predict": 2048,
    "temperature": 0.7,
    "top_p": 0.9
  }
}
```

## Valid Service Types

The service validates AI responses against these predefined categories:

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

## Error Handling

### Logged Errors

All errors are logged with context for debugging:

```php
Log::error('Vision AI analysis failed', [
    'error' => $e->getMessage(),
    'image_path' => $imagePath,
    'markers_count' => count($markers),
]);
```

### Common Error Scenarios

1. **Image Not Found**
   - Exception: "Image file not found: {path}"
   - Logged with image path

2. **API Timeout**
   - Retries 3 times with exponential backoff
   - Final exception after all retries fail

3. **Invalid JSON Response**
   - Falls back to default values
   - Logs warning with received response

4. **Invalid Service Type**
   - Falls back to "General Maintenance"
   - Logs warning with received type

5. **Invalid Cost Estimates**
   - Falls back to NPR 1000-5000
   - Logs warning with received values

## Performance Considerations

### Processing Time

Typical processing times:
- Image encoding: 50-200ms
- API call: 15-30 seconds (depends on image size and complexity)
- Provider matching: 100-500ms
- Total: 15-35 seconds

### Optimization Tips

1. **Image Size**: Compress images to < 5MB before analysis
2. **Caching**: Consider caching provider queries (5 minutes)
3. **Async Processing**: Use job queues for non-blocking analysis
4. **Timeout**: Adjust timeout based on average response times

## Testing

### Unit Tests

Location: `tests/Unit/Services/VisionAIServiceTest.php`

**Test Coverage:**
- ✓ Successful image analysis
- ✓ Prompt building with markers
- ✓ Response parsing (valid JSON)
- ✓ Response parsing (markdown code blocks)
- ✓ Invalid service type handling
- ✓ Invalid cost estimate handling
- ✓ Malformed JSON handling
- ✓ Provider matching
- ✓ Provider filtering (inactive)
- ✓ Image encoding
- ✓ File not found error
- ✓ Retry logic
- ✓ Cost ratio validation

**Run Tests:**
```bash
./vendor/bin/phpunit tests/Unit/Services/VisionAIServiceTest.php
```

### Integration Testing

For integration testing with real Ollama service:

```php
// Ensure Ollama is running
$service = new VisionAIService();

// Test with real image
$imagePath = storage_path('app/test_images/plumbing_leak.jpg');
$markers = [
    ['x' => 0.5, 'y' => 0.5, 'description' => 'Water leak visible'],
];

$result = $service->analyzeImage($imagePath, $markers);

// Verify result structure
assert(isset($result['diagnosis']));
assert(isset($result['service_type']));
assert(isset($result['recommended_providers']));
```

## Usage in Controllers

Example usage in `AIConsultationController`:

```php
use App\Services\AI\VisionAIService;

class AIConsultationController extends Controller
{
    private VisionAIService $visionService;

    public function __construct(VisionAIService $visionService)
    {
        $this->visionService = $visionService;
    }

    public function store(CreateConsultationRequest $request)
    {
        // Decode and store image
        $imagePath = $this->storeImage($request->input('image'));

        // Analyze with AI
        $result = $this->visionService->analyzeImage(
            $imagePath,
            $request->input('markers')
        );

        // Create consultation record
        $consultation = AIConsultation::create([
            'customer_id' => auth()->id(),
            'image_path' => $imagePath,
            'markers' => $request->input('markers'),
            'ai_diagnosis' => $result['diagnosis'],
            'recommended_service_type' => $result['service_type'],
            'cost_min' => $result['cost_min'],
            'cost_max' => $result['cost_max'],
            'recommended_providers' => $result['recommended_providers'],
            'ai_response_raw' => $result,
            'processing_time_ms' => $result['processing_time_ms'],
        ]);

        return response()->json([
            'success' => true,
            'data' => ['consultation' => $consultation],
        ], 201);
    }
}
```

## Logging

### Info Logs

```php
Log::info('Vision AI analysis completed', [
    'model' => 'qwen3-vl:2b',
    'response_length' => 1234,
]);
```

### Warning Logs

```php
Log::warning('Invalid service type from AI, using fallback', [
    'received' => 'Unknown Service',
]);

Log::warning("Vision AI request failed, retrying in {$delay}ms", [
    'attempt' => 2,
    'error' => 'Connection timeout',
]);
```

### Error Logs

```php
Log::error('Vision AI analysis failed', [
    'error' => 'API timeout',
    'image_path' => '/path/to/image.jpg',
    'markers_count' => 3,
]);
```

## Troubleshooting

### Issue: API Timeout

**Symptoms**: Analysis takes > 60 seconds and times out

**Solutions**:
1. Increase timeout in config: `OLLAMA_TIMEOUT=90`
2. Compress images before analysis
3. Check Ollama service health
4. Verify network connectivity

### Issue: Invalid Service Type

**Symptoms**: AI returns service types not in the predefined list

**Solutions**:
1. Service automatically falls back to "General Maintenance"
2. Check AI prompt for clarity
3. Consider adding new service types to validation list
4. Review AI model performance

### Issue: No Providers Found

**Symptoms**: `recommended_providers` array is empty

**Solutions**:
1. Verify providers exist for the service type
2. Check provider `is_active` status
3. Check service `status` is 'active'
4. Verify service categories match exactly

### Issue: Poor Cost Estimates

**Symptoms**: Cost estimates are unrealistic

**Solutions**:
1. Review AI prompt guidelines
2. Check if costs are being clamped (500-50000 range)
3. Consider fine-tuning the AI model
4. Add more context to marker descriptions

## Future Enhancements

1. **Async Processing**: Move analysis to job queue
2. **Result Caching**: Cache similar image analyses
3. **Confidence Threshold**: Reject low-confidence results
4. **Multi-Model Support**: Allow switching between vision models
5. **Batch Analysis**: Analyze multiple images in one request
6. **Provider Scoring**: More sophisticated provider matching algorithm
7. **Cost Calibration**: Learn from actual booking costs
8. **Image Preprocessing**: Auto-enhance images before analysis

## Related Files

- Base Service: `app/Services/AI/AIService.php`
- DTO: `app/DTOs/AI/AIResponse.php`
- Model: `app/Models/AIConsultation.php`
- Controller: `app/Http/Controllers/API/V1/Customer/AIConsultationController.php`
- Tests: `tests/Unit/Services/VisionAIServiceTest.php`
- Migration: `database/migrations/*_create_ai_consultations_table.php`

