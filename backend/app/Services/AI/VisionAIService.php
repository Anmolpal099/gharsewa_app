<?php

namespace App\Services\AI;

use App\DTOs\AI\AIResponse;
use App\Models\User;
use App\Models\Service;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class VisionAIService extends AIService
{
    /**
     * Analyze image with markers and descriptions
     * 
     * @param string $imagePath - Path to uploaded image
     * @param array $markers - Array of marker objects with x, y, description
     * @return array - Structured response with diagnosis and recommendations
     * @throws Exception
     */
    public function analyzeImage(string $imagePath, array $markers): array
    {
        $startTime = microtime(true);

        try {
            // Encode image to base64
            $imageBase64 = $this->encodeImageToBase64($imagePath);

            // Build vision prompt
            $prompt = $this->buildVisionPrompt($markers);

            // Call Ollama API with retry logic
            $aiResponse = $this->callVisionAPIWithRetry($imageBase64, $prompt);

            // Parse AI response
            $parsedData = $this->parseVisionResponse($aiResponse->content);

            // Find matching providers
            $providers = $this->findMatchingProviders($parsedData['service_type'], 3);

            // Calculate processing time
            $processingTime = (int) ((microtime(true) - $startTime) * 1000);

            // Build final response
            return [
                'diagnosis' => $parsedData['diagnosis'],
                'service_type' => $parsedData['service_type'],
                'cost_min' => $parsedData['cost_min'],
                'cost_max' => $parsedData['cost_max'],
                'confidence' => $parsedData['confidence'],
                'recommended_providers' => $providers,
                'processing_time_ms' => $processingTime,
                'model' => $this->model,
            ];

        } catch (Exception $e) {
            Log::error('Vision AI analysis failed', [
                'error' => $e->getMessage(),
                'image_path' => $imagePath,
                'markers_count' => count($markers),
            ]);

            throw $e;
        }
    }

    /**
     * Build prompt for vision model
     * 
     * @param array $markers - Marker data
     * @return string - Formatted prompt
     */
    private function buildVisionPrompt(array $markers): string
    {
        $markersList = '';
        foreach ($markers as $index => $marker) {
            $markerNumber = $index + 1;
            $x = round($marker['x'] * 100);
            $y = round($marker['y'] * 100);
            $description = $marker['description'];
            $markersList .= "Marker {$markerNumber} at position ({$x}%, {$y}%): {$description}\n";
        }

        return <<<PROMPT
You are an expert home service diagnostic assistant. Analyze the provided image with the following defect markers:

{$markersList}

Based on the image and marked defects, provide a structured diagnosis in the following JSON format:

{
  "diagnosis": "Brief description of the problem (50-500 characters)",
  "service_type": "One of: Plumbing Repair, Electrical Work, Carpentry, Painting, Cleaning, Appliance Repair, HVAC, Pest Control, Landscaping, General Maintenance",
  "cost_estimate": {
    "min": <minimum cost in NPR>,
    "max": <maximum cost in NPR>
  },
  "confidence": <confidence score 0.0 to 1.0>
}

Guidelines:
- Diagnosis should be clear and actionable
- Service type must match one of the listed categories
- Cost estimates should be realistic for Nepal market (NPR 500 - 50000)
- Maximum should be at least 1.5x minimum
- If uncertain, use default range NPR 1000-5000 and confidence < 0.5

Respond ONLY with the JSON object, no additional text.
PROMPT;
    }

    /**
     * Parse AI response into structured format
     * 
     * @param string $rawResponse - Raw AI text response
     * @return array - Structured data with diagnosis, service_type, cost, confidence
     */
    private function parseVisionResponse(string $rawResponse): array
    {
        try {
            // Extract JSON from response (handle markdown code blocks)
            $jsonString = $this->extractJSON($rawResponse);

            // Parse JSON
            $data = json_decode($jsonString, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new Exception('Invalid JSON in AI response: ' . json_last_error_msg());
            }

            // Validate required fields
            if (!isset($data['diagnosis']) || !isset($data['service_type']) || !isset($data['cost_estimate'])) {
                throw new Exception('Missing required fields in AI response');
            }

            // Validate service type
            $validServiceTypes = [
                'Plumbing Repair',
                'Electrical Work',
                'Carpentry',
                'Painting',
                'Cleaning',
                'Appliance Repair',
                'HVAC',
                'Pest Control',
                'Landscaping',
                'General Maintenance',
            ];

            $serviceType = $data['service_type'];
            if (!in_array($serviceType, $validServiceTypes)) {
                Log::warning('Invalid service type from AI, using fallback', [
                    'received' => $serviceType,
                ]);
                $serviceType = 'General Maintenance';
            }

            // Validate cost estimates
            $costMin = (float) ($data['cost_estimate']['min'] ?? 1000);
            $costMax = (float) ($data['cost_estimate']['max'] ?? 5000);

            if ($costMin <= 0 || $costMax <= 0 || $costMax < $costMin) {
                Log::warning('Invalid cost estimates from AI, using fallback', [
                    'received_min' => $costMin,
                    'received_max' => $costMax,
                ]);
                $costMin = 1000;
                $costMax = 5000;
            }

            // Ensure cost is within reasonable range
            $costMin = max(500, min($costMin, 50000));
            $costMax = max(500, min($costMax, 50000));

            // Ensure max is at least 1.5x min
            if ($costMax < $costMin * 1.5) {
                $costMax = $costMin * 1.5;
            }

            return [
                'diagnosis' => substr($data['diagnosis'], 0, 500),
                'service_type' => $serviceType,
                'cost_min' => $costMin,
                'cost_max' => $costMax,
                'confidence' => (float) ($data['confidence'] ?? 0.5),
            ];

        } catch (Exception $e) {
            Log::error('Failed to parse vision response', [
                'error' => $e->getMessage(),
                'response' => substr($rawResponse, 0, 500),
            ]);

            // Return fallback values
            return [
                'diagnosis' => 'Unable to determine specific issue. Please provide more details or consult with a service provider.',
                'service_type' => 'General Maintenance',
                'cost_min' => 1000,
                'cost_max' => 5000,
                'confidence' => 0.3,
            ];
        }
    }

    /**
     * Extract JSON from response (handle markdown code blocks)
     * 
     * @param string $response - Raw response
     * @return string - Extracted JSON string
     */
    private function extractJSON(string $response): string
    {
        // Remove markdown code blocks if present
        $response = preg_replace('/```json\s*/', '', $response);
        $response = preg_replace('/```\s*/', '', $response);

        // Trim whitespace
        $response = trim($response);

        // Find JSON object
        if (preg_match('/\{.*\}/s', $response, $matches)) {
            return $matches[0];
        }

        return $response;
    }

    /**
     * Find matching providers for service type
     * 
     * @param string $serviceType - Service category
     * @param int $limit - Number of providers to return
     * @return array - Top providers with ratings
     */
    private function findMatchingProviders(string $serviceType, int $limit = 3): array
    {
        try {
            // Query providers who offer the service type
            $providers = User::where('is_active', true)
                ->whereHas('services', function ($query) use ($serviceType) {
                    $query->where('category', $serviceType)
                          ->where('status', 'active');
                })
                ->with(['services' => function ($query) use ($serviceType) {
                    $query->where('category', $serviceType)
                          ->where('status', 'active');
                }])
                ->withCount(['reviewsReceived as reviews_count'])
                ->withAvg('reviewsReceived as rating', 'rating')
                ->get();

            // Calculate match scores and format response
            $providersWithScores = $providers->map(function ($provider) use ($serviceType) {
                $rating = $provider->rating ?? 0;
                $reviewsCount = $provider->reviews_count ?? 0;

                // Calculate match score based on rating and review count
                // Higher rating and more reviews = higher score
                $matchScore = ($rating / 5.0) * 0.7 + (min($reviewsCount, 50) / 50.0) * 0.3;

                return [
                    'id' => $provider->id,
                    'name' => $provider->name,
                    'rating' => round($rating, 1),
                    'reviews_count' => $reviewsCount,
                    'services' => $provider->services->pluck('name')->toArray(),
                    'match_score' => round($matchScore, 2),
                ];
            });

            // Sort by match score (rating primarily)
            $sortedProviders = $providersWithScores->sortByDesc(function ($provider) {
                return $provider['rating'] * 1000 + $provider['match_score'];
            })->values();

            // Return top N providers
            return $sortedProviders->take($limit)->toArray();

        } catch (Exception $e) {
            Log::error('Failed to find matching providers', [
                'error' => $e->getMessage(),
                'service_type' => $serviceType,
            ]);

            return [];
        }
    }

    /**
     * Encode image to base64 for Ollama API
     * 
     * @param string $imagePath - Path to image file
     * @return string - Base64 encoded image
     * @throws Exception
     */
    private function encodeImageToBase64(string $imagePath): string
    {
        try {
            if (!file_exists($imagePath)) {
                throw new Exception("Image file not found: {$imagePath}");
            }

            $imageData = file_get_contents($imagePath);

            if ($imageData === false) {
                throw new Exception("Failed to read image file: {$imagePath}");
            }

            return base64_encode($imageData);

        } catch (Exception $e) {
            Log::error('Failed to encode image to base64', [
                'error' => $e->getMessage(),
                'image_path' => $imagePath,
            ]);

            throw $e;
        }
    }

    /**
     * Call Ollama Vision API with retry logic
     * 
     * @param string $imageBase64 - Base64 encoded image
     * @param string $prompt - Vision prompt
     * @return AIResponse - AI response
     * @throws Exception
     */
    private function callVisionAPIWithRetry(string $imageBase64, string $prompt): AIResponse
    {
        $attempt = 0;
        $lastException = null;

        while ($attempt < $this->maxRetries) {
            try {
                return $this->callVisionAPI($imageBase64, $prompt);
            } catch (Exception $e) {
                $lastException = $e;
                $attempt++;

                if ($attempt < $this->maxRetries) {
                    $delay = $this->retryDelay * pow(2, $attempt - 1); // Exponential backoff
                    Log::warning("Vision AI request failed, retrying in {$delay}ms", [
                        'attempt' => $attempt,
                        'error' => $e->getMessage(),
                    ]);
                    usleep($delay * 1000);
                }
            }
        }

        throw $lastException ?? new Exception('Vision AI analysis failed after retries');
    }

    /**
     * Call Ollama Vision API
     * 
     * @param string $imageBase64 - Base64 encoded image
     * @param string $prompt - Vision prompt
     * @return AIResponse - AI response
     * @throws Exception
     */
    private function callVisionAPI(string $imageBase64, string $prompt): AIResponse
    {
        try {
            $response = Http::timeout($this->timeout)
                ->post("{$this->ollamaHost}/api/generate", [
                    'model' => $this->model,
                    'prompt' => $prompt,
                    'images' => [$imageBase64],
                    'stream' => false,
                    'options' => [
                        'num_predict' => $this->maxTokens,
                        'temperature' => $this->temperature,
                        'top_p' => $this->topP,
                    ],
                ]);

            if (!$response->successful()) {
                throw new Exception("Ollama Vision API error: " . $response->body());
            }

            $data = $response->json();

            if (!isset($data['response'])) {
                throw new Exception('Invalid response from Ollama Vision API');
            }

            Log::info('Vision AI analysis completed', [
                'model' => $data['model'] ?? $this->model,
                'response_length' => strlen($data['response']),
            ]);

            return AIResponse::success(
                content: $data['response'],
                metadata: [
                    'model' => $data['model'] ?? $this->model,
                    'total_duration' => $data['total_duration'] ?? null,
                    'load_duration' => $data['load_duration'] ?? null,
                    'prompt_eval_count' => $data['prompt_eval_count'] ?? null,
                    'eval_count' => $data['eval_count'] ?? null,
                ]
            );

        } catch (Exception $e) {
            Log::error('Vision API call failed', [
                'error' => $e->getMessage(),
                'prompt_length' => strlen($prompt),
            ]);

            throw $e;
        }
    }
}

