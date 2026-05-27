<?php

namespace App\Http\Controllers\API\V1\Customer;

use App\Http\Controllers\API\V1\BaseController;
use App\Http\Requests\AI\CreateConsultationRequest;
use App\Models\AIConsultation;
use App\Services\AI\VisionAIService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Exception;

class AIConsultationController extends BaseController
{
    protected VisionAIService $visionAIService;

    public function __construct(VisionAIService $visionAIService)
    {
        $this->visionAIService = $visionAIService;
    }

    /**
     * Create new consultation with AI analysis
     * 
     * POST /api/v1/customer/ai/consultations
     * 
     * @param CreateConsultationRequest $request
     * @return JsonResponse
     */
    public function store(CreateConsultationRequest $request): JsonResponse
    {
        try {
            $user = $request->user();
            $imageBase64 = $request->input('image');
            $markers = $request->input('markers');

            // Decode base64 image
            $imageData = base64_decode($imageBase64, true);
            
            if ($imageData === false) {
                return $this->error('Invalid base64 image data', 400);
            }

            // Validate image format - accept all image types
            $finfo = new \finfo(FILEINFO_MIME_TYPE);
            $mimeType = $finfo->buffer($imageData);
            
            // Check if it's an image file
            if (!str_starts_with($mimeType, 'image/')) {
                return $this->error('Invalid file type. Please upload an image file.', 400);
            }

            // Calculate image size
            $imageSizeKb = strlen($imageData) / 1024;

            // Optional compression for very large images (> 10MB)
            // Compression is optional - if it fails, use original
            if ($imageSizeKb > 10240) {
                try {
                    $compressedData = $this->compressImage($imageData, $mimeType);
                    if ($compressedData !== false) {
                        $imageData = $compressedData;
                        $imageSizeKb = strlen($imageData) / 1024;
                    }
                } catch (\Exception $e) {
                    Log::warning('Image compression failed, using original', [
                        'error' => $e->getMessage(),
                        'original_size_kb' => $imageSizeKb,
                    ]);
                }
            }

            // Generate unique filename
            $extension = $this->getExtensionFromMimeType($mimeType);
            $filename = Str::uuid() . '.' . $extension;

            // Store image in customer-specific directory
            $customerDirectory = "consultations/{$user->id}";
            $imagePath = "{$customerDirectory}/{$filename}";
            
            // Ensure directory exists and store image
            Storage::disk('public')->put($imagePath, $imageData);

            // Get full path for AI analysis
            $fullImagePath = Storage::disk('public')->path($imagePath);

            // Call VisionAIService for analysis
            $aiResponse = $this->visionAIService->analyzeImage($fullImagePath, $markers);

            // Query matching providers based on service type
            $recommendedProviders = $aiResponse['recommended_providers'] ?? [];

            // Create AIConsultation record
            $consultation = AIConsultation::create([
                'customer_id' => $user->id,
                'image_path' => $imagePath,
                'image_size_kb' => (int) round($imageSizeKb),
                'markers' => $markers,
                'ai_diagnosis' => $aiResponse['diagnosis'],
                'recommended_service_type' => $aiResponse['service_type'],
                'cost_min' => $aiResponse['cost_min'],
                'cost_max' => $aiResponse['cost_max'],
                'recommended_providers' => $recommendedProviders,
                'ai_response_raw' => $aiResponse,
                'processing_time_ms' => $aiResponse['processing_time_ms'],
            ]);

            // Load the consultation with fresh data to get computed attributes
            $consultation->refresh();

            // Format response
            $responseData = [
                'consultation' => [
                    'id' => $consultation->id,
                    'image_url' => $consultation->image_url,
                    'markers' => $consultation->markers,
                    'diagnosis' => $consultation->ai_diagnosis,
                    'recommended_service_type' => $consultation->recommended_service_type,
                    'cost_min' => $consultation->cost_min,
                    'cost_max' => $consultation->cost_max,
                    'recommended_providers' => $this->formatProviders($recommendedProviders),
                    'processing_time_ms' => $consultation->processing_time_ms,
                    'created_at' => $consultation->created_at->toIso8601String(),
                ],
            ];

            return $this->success($responseData, 'Consultation created successfully', 201);

        } catch (Exception $e) {
            Log::error('Failed to create AI consultation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $request->user()->id ?? null,
            ]);

            // Clean up image if it was stored
            if (isset($imagePath)) {
                Storage::disk('public')->delete($imagePath);
            }

            return $this->error(
                'Failed to create consultation. Please try again later.',
                500,
                config('app.debug') ? ['error' => $e->getMessage()] : null
            );
        }
    }

    /**
     * Compress image if it exceeds size limit
     * 
     * @param string $imageData
     * @param string $mimeType
     * @return string|false Returns compressed data or false on failure
     */
    private function compressImage(string $imageData, string $mimeType): string|false
    {
        try {
            // Create image resource from string
            $image = imagecreatefromstring($imageData);
            
            if ($image === false) {
                return false; // Return false if compression fails
            }

            // Get original dimensions
            $originalWidth = imagesx($image);
            $originalHeight = imagesy($image);

            // Calculate new dimensions (max 1920x1920 while maintaining aspect ratio)
            $maxDimension = 1920;
            $scale = min($maxDimension / $originalWidth, $maxDimension / $originalHeight, 1);
            
            $newWidth = (int) ($originalWidth * $scale);
            $newHeight = (int) ($originalHeight * $scale);

            // Create new image with calculated dimensions
            $newImage = imagecreatetruecolor($newWidth, $newHeight);
            
            // Preserve transparency for PNG
            if ($mimeType === 'image/png') {
                imagealphablending($newImage, false);
                imagesavealpha($newImage, true);
            }

            // Resize image
            imagecopyresampled(
                $newImage, $image,
                0, 0, 0, 0,
                $newWidth, $newHeight,
                $originalWidth, $originalHeight
            );

            // Output to buffer
            ob_start();
            
            if ($mimeType === 'image/png') {
                imagepng($newImage, null, 8); // Compression level 8
            } else {
                imagejpeg($newImage, null, 85); // Quality 85%
            }
            
            $compressedData = ob_get_clean();

            // Clean up
            imagedestroy($image);
            imagedestroy($newImage);

            return $compressedData;

        } catch (Exception $e) {
            Log::warning('Image compression failed', [
                'error' => $e->getMessage(),
            ]);
            
            return false;
        }
    }

    /**
     * Get file extension from MIME type
     * 
     * @param string $mimeType
     * @return string
     */
    private function getExtensionFromMimeType(string $mimeType): string
    {
        return match ($mimeType) {
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/heic' => 'heic',
            default => 'jpg',
        };
    }

    /**
     * Get consultation history for authenticated customer
     * 
     * GET /api/v1/customer/ai/consultations
     * 
     * @param \Illuminate\Http\Request $request
     * @return JsonResponse
     */
    public function index(\Illuminate\Http\Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            
            // Get pagination parameters
            $perPage = min((int) $request->input('per_page', 20), 50); // Max 50 per page
            $page = (int) $request->input('page', 1);
            
            // Get optional service type filter
            $serviceType = $request->input('service_type');
            
            // Build query
            $query = AIConsultation::forCustomer($user->id)
                ->orderBy('created_at', 'desc');
            
            // Apply service type filter if provided
            if ($serviceType) {
                $query->byServiceType($serviceType);
            }
            
            // Paginate results
            $consultations = $query->paginate($perPage, ['*'], 'page', $page);
            
            // Format consultation data for list view (brief format)
            $formattedConsultations = $consultations->map(function ($consultation) {
                return [
                    'id' => $consultation->id,
                    'image_url' => $consultation->image_url,
                    'diagnosis' => $consultation->ai_diagnosis,
                    'recommended_service_type' => $consultation->recommended_service_type,
                    'cost_min' => $consultation->cost_min,
                    'cost_max' => $consultation->cost_max,
                    'created_at' => $consultation->created_at->toIso8601String(),
                ];
            });
            
            // Format response with pagination metadata
            $responseData = [
                'consultations' => $formattedConsultations,
                'pagination' => [
                    'current_page' => $consultations->currentPage(),
                    'per_page' => $consultations->perPage(),
                    'total' => $consultations->total(),
                    'last_page' => $consultations->lastPage(),
                ],
            ];
            
            return $this->success($responseData);
            
        } catch (Exception $e) {
            Log::error('Failed to retrieve consultation history', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $request->user()->id ?? null,
            ]);
            
            return $this->error(
                'Failed to retrieve consultation history. Please try again later.',
                500,
                config('app.debug') ? ['error' => $e->getMessage()] : null
            );
        }
    }

    /**
     * Get detailed consultation by ID
     * 
     * GET /api/v1/customer/ai/consultations/{id}
     * 
     * @param \Illuminate\Http\Request $request
     * @param string $id
     * @return JsonResponse
     */
    public function show(\Illuminate\Http\Request $request, string $id): JsonResponse
    {
        try {
            $user = $request->user();
            
            // Find consultation
            $consultation = AIConsultation::find($id);
            
            // Check if consultation exists
            if (!$consultation) {
                return $this->error('Consultation not found', 404);
            }
            
            // Authorization check - customer can only view own consultations
            if ($consultation->customer_id !== $user->id) {
                return $this->error('Unauthorized access to this consultation', 403);
            }
            
            // Format full consultation data
            $responseData = [
                'consultation' => [
                    'id' => $consultation->id,
                    'image_url' => $consultation->image_url,
                    'markers' => $consultation->markers,
                    'diagnosis' => $consultation->ai_diagnosis,
                    'recommended_service_type' => $consultation->recommended_service_type,
                    'cost_min' => $consultation->cost_min,
                    'cost_max' => $consultation->cost_max,
                    'recommended_providers' => $this->formatProviders($consultation->recommended_providers ?? []),
                    'processing_time_ms' => $consultation->processing_time_ms,
                    'created_at' => $consultation->created_at->toIso8601String(),
                ],
            ];
            
            return $this->success($responseData);
            
        } catch (Exception $e) {
            Log::error('Failed to retrieve consultation details', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'consultation_id' => $id,
                'user_id' => $request->user()->id ?? null,
            ]);
            
            return $this->error(
                'Failed to retrieve consultation details. Please try again later.',
                500,
                config('app.debug') ? ['error' => $e->getMessage()] : null
            );
        }
    }

    /**
     * Delete a consultation (soft delete)
     * 
     * DELETE /api/v1/customer/ai/consultations/{id}
     * 
     * @param \Illuminate\Http\Request $request
     * @param string $id
     * @return JsonResponse
     */
    public function destroy(\Illuminate\Http\Request $request, string $id): JsonResponse
    {
        try {
            $user = $request->user();
            
            // Find consultation
            $consultation = AIConsultation::find($id);
            
            // Check if consultation exists
            if (!$consultation) {
                return $this->error('Consultation not found', 404);
            }
            
            // Authorization check - customer can only delete own consultations
            if ($consultation->customer_id !== $user->id) {
                return $this->error('Unauthorized access to this consultation', 403);
            }
            
            // Soft delete the consultation
            $consultation->delete();
            
            return $this->success(null, 'Consultation deleted successfully');
            
        } catch (Exception $e) {
            Log::error('Failed to delete consultation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'consultation_id' => $id,
                'user_id' => $request->user()->id ?? null,
            ]);
            
            return $this->error(
                'Failed to delete consultation. Please try again later.',
                500,
                config('app.debug') ? ['error' => $e->getMessage()] : null
            );
        }
    }

    /**
     * Format providers for response
     * 
     * @param array $providers
     * @return array
     */
    private function formatProviders(array $providers): array
    {
        return array_map(function ($provider) {
            return [
                'id' => $provider['id'],
                'name' => $provider['name'],
                'rating' => $provider['rating'],
                'services' => $provider['services'] ?? [],
            ];
        }, $providers);
    }
}
