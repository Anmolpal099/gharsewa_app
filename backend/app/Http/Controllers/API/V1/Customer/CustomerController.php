<?php

namespace App\Http\Controllers\API\V1\Customer;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Service;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class CustomerController extends BaseController
{
    /**
     * Browse all active services with filtering
     * GET /api/v1/services
     * Public endpoint - no authentication required
     */
    public function listServices(Request $request): JsonResponse
    {
        try {
            $query = Service::query()
                ->with(['provider:id,name,email', 'images'])
                ->active();

            // Filter by category
            if ($request->has('category') && $request->category) {
                $query->where('category', $request->category);
            }

            // Filter by price range
            if ($request->has('min_price') && $request->min_price !== null) {
                $query->where('price', '>=', $request->min_price);
            }

            if ($request->has('max_price') && $request->max_price !== null) {
                $query->where('price', '<=', $request->max_price);
            }

            // Search by term (name or description)
            if ($request->has('search') && $request->search) {
                $searchTerm = $request->search;
                $query->where(function ($q) use ($searchTerm) {
                    $q->where('name', 'like', "%{$searchTerm}%")
                      ->orWhere('description', 'like', "%{$searchTerm}%");
                });
            }

            // Paginate results
            $services = $query->paginate(15);

            Log::info('Services listed', [
                'filters' => $request->only(['category', 'min_price', 'max_price', 'search']),
                'count' => $services->total(),
            ]);

            return $this->paginated($services, 'Services retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to list services', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to retrieve services. Please try again.', 500);
        }
    }

    /**
     * Get service details with provider information
     * GET /api/v1/services/{id}
     * Public endpoint - no authentication required
     */
    public function getService(string $id): JsonResponse
    {
        try {
            $service = Service::with(['provider:id,name,email,phone_number', 'images'])
                ->active()
                ->find($id);

            if ($service) {
                $service->setAttribute(
                    'image_urls',
                    $service->images->pluck('url')->values()->all()
                );
            }

            if (!$service) {
                return $this->error('Service not found or not available', 404);
            }

            Log::info('Service details retrieved', [
                'service_id' => $id,
            ]);

            return $this->success($service, 'Service details retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to get service details', [
                'service_id' => $id,
                'exception' => $e->getMessage(),
            ]);

            return $this->error('Failed to retrieve service details. Please try again.', 500);
        }
    }

    /**
     * Search services by query term
     * GET /api/v1/services/search
     * Public endpoint - no authentication required
     */
    public function searchServices(Request $request): JsonResponse
    {
        try {
            $searchTerm = $request->input('q', '');

            if (empty($searchTerm)) {
                return $this->error('Search term is required', 400);
            }

            $query = Service::query()
                ->with('provider:id,name,email')
                ->active()
                ->where(function ($q) use ($searchTerm) {
                    $q->where('name', 'like', "%{$searchTerm}%")
                      ->orWhere('description', 'like', "%{$searchTerm}%");
                });

            // Optional category filter
            if ($request->has('category') && $request->category) {
                $query->where('category', $request->category);
            }

            // Paginate results
            $services = $query->paginate(15);

            Log::info('Services searched', [
                'search_term' => $searchTerm,
                'category' => $request->category,
                'results_count' => $services->total(),
            ]);

            return $this->paginated($services, 'Search results retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to search services', [
                'search_term' => $request->input('q'),
                'exception' => $e->getMessage(),
            ]);

            return $this->error('Failed to search services. Please try again.', 500);
        }
    }

    /**
     * Get unique categories with service counts
     * GET /api/v1/services/categories
     * Public endpoint - no authentication required
     */
    public function getCategories(): JsonResponse
    {
        try {
            $categories = Service::select('category', DB::raw('COUNT(*) as count'))
                ->active()
                ->groupBy('category')
                ->orderBy('category')
                ->get()
                ->map(function ($item) {
                    return [
                        'category' => $item->category,
                        'count' => $item->count,
                    ];
                });

            Log::info('Categories retrieved', [
                'categories_count' => $categories->count(),
            ]);

            return $this->success($categories, 'Categories retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to get categories', [
                'exception' => $e->getMessage(),
            ]);

            return $this->error('Failed to retrieve categories. Please try again.', 500);
        }
    }

    /**
     * Get customer dashboard data
     */
    public function dashboard(Request $request): JsonResponse
    {
        // TODO: Implement actual dashboard logic
        return response()->json([
            'success' => true,
            'data' => [
                'total_bookings' => 0,
                'pending_bookings' => 0,
                'completed_bookings' => 0,
                'favorite_services' => [],
                'recent_bookings' => [],
            ]
        ]);
    }

    /**
     * Get available services (legacy method - use listServices instead)
     */
    public function services(Request $request): JsonResponse
    {
        // Redirect to listServices
        return $this->listServices($request);
    }

    /**
     * Get service details (legacy method - use getService instead)
     */
    public function serviceDetail(Request $request, string $id): JsonResponse
    {
        // Redirect to getService
        return $this->getService($id);
    }

    /**
     * Get AI-powered recommendations
     */
    public function recommendations(Request $request): JsonResponse
    {
        // TODO: Implement AI recommendation logic
        return response()->json([
            'success' => true,
            'data' => [
                'recommended_services' => [],
                'trending_services' => [],
                'personalized_offers' => [],
            ]
        ]);
    }

    /**
     * Get current user profile
     * GET /api/v1/profile
     * Requires authentication
     */
    public function getProfile(): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            // Generate full URL for profile image if exists
            $profileImageUrl = $user->profile_image_url 
                ? url(Storage::url($user->profile_image_url))
                : null;

            $profileData = [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone_number' => $user->phone_number,
                'profile_image_url' => $profileImageUrl,
                'is_active' => $user->is_active,
                'email_verified_at' => $user->email_verified_at,
                'last_login_at' => $user->last_login_at,
            ];

            Log::info('User profile retrieved', [
                'user_id' => $user->id,
            ]);

            return $this->success($profileData, 'Profile retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to get user profile', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to retrieve profile. Please try again.', 500);
        }
    }

    /**
     * Update user profile
     * PUT /api/v1/profile
     * Requires authentication
     */
    public function updateProfile(Request $request): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            // Validate input
            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|string|max:255',
                'phone_number' => 'sometimes|string|max:20',
                'address' => 'sometimes|string|max:500',
            ]);

            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }

            $validatedData = $validator->validated();

            // Update only the fields that exist in the User model
            $updateData = [];
            if (isset($validatedData['name'])) {
                $updateData['name'] = $validatedData['name'];
            }
            if (isset($validatedData['phone_number'])) {
                $updateData['phone_number'] = $validatedData['phone_number'];
            }

            // Handle address field gracefully - store in metadata if not in schema
            if (isset($validatedData['address'])) {
                $metadata = $user->metadata ?? [];
                $metadata['address'] = $validatedData['address'];
                $updateData['metadata'] = $metadata;
            }

            // Update user
            $user->update($updateData);

            // Refresh user data
            $user->refresh();

            // Generate full URL for profile image if exists
            $profileImageUrl = $user->profile_image_url 
                ? url(Storage::url($user->profile_image_url))
                : null;

            $profileData = [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone_number' => $user->phone_number,
                'profile_image_url' => $profileImageUrl,
                'is_active' => $user->is_active,
                'email_verified_at' => $user->email_verified_at,
                'last_login_at' => $user->last_login_at,
            ];

            Log::info('User profile updated', [
                'user_id' => $user->id,
                'updated_fields' => array_keys($updateData),
            ]);

            return $this->success($profileData, 'Profile updated successfully');

        } catch (\Exception $e) {
            Log::error('Failed to update user profile', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to update profile. Please try again.', 500);
        }
    }

    /**
     * Upload profile image
     * POST /api/v1/profile/image
     * Requires authentication
     */
    public function uploadProfileImage(Request $request): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            // Validate image - accept base64 or file upload
            $validator = Validator::make($request->all(), [
                'image' => ['required', new \App\Rules\Base64Image(51200)], // Max 50MB
            ]);

            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }

            // Delete old image if exists
            if ($user->profile_image_url) {
                // Extract path from URL if it's a full URL
                $oldPath = $user->profile_image_url;
                
                // If it's a storage path, delete it
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                    Log::info('Old profile image deleted', [
                        'user_id' => $user->id,
                        'old_path' => $oldPath,
                    ]);
                }
            }

            // Handle base64 image
            $base64Image = $request->input('image');
            
            // Remove data URI scheme if present
            if (preg_match('/^data:image\/(\w+);base64,/', $base64Image, $matches)) {
                $base64Image = substr($base64Image, strpos($base64Image, ',') + 1);
            }
            
            // Decode base64
            $imageData = base64_decode($base64Image);
            
            // Generate filename
            $filename = time() . '_' . $user->id . '.jpg';
            $path = 'profile-images/' . $filename;
            
            // Store image
            Storage::disk('public')->put($path, $imageData);

            // Update user's profile_image_url
            $user->update([
                'profile_image_url' => $path,
            ]);

            // Generate full URL with domain
            $imageUrl = url(Storage::url($path));

            Log::info('Profile image uploaded', [
                'user_id' => $user->id,
                'path' => $path,
                'url' => $imageUrl,
            ]);

            return $this->success([
                'image_url' => $imageUrl,
                'url' => $imageUrl,
                'path' => $path,
            ], 'Profile image uploaded successfully');

        } catch (\Exception $e) {
            Log::error('Failed to upload profile image', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to upload profile image. Please try again.', 500);
        }
    }
}
