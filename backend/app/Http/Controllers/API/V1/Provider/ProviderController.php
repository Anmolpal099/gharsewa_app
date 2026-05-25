<?php

namespace App\Http\Controllers\API\V1\Provider;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Service;
use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProviderController extends BaseController
{
    /**
     * Get provider profile with services count
     * GET /api/v1/provider/profile
     * Requires authentication with serviceProvider role
     */
    public function getProfile(): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            // Get services count
            $servicesCount = Service::where('provider_id', $user->id)->count();

            $profileData = [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone_number' => $user->phone_number,
                'profile_image_url' => $user->profile_image_url,
                'is_active' => $user->is_active,
                'email_verified_at' => $user->email_verified_at,
                'last_login_at' => $user->last_login_at,
                'services_count' => $servicesCount,
                'metadata' => $this->metadataForResponse($user->metadata),
            ];

            Log::info('Provider profile retrieved', [
                'user_id' => $user->id,
                'services_count' => $servicesCount,
            ]);

            return $this->success($profileData, 'Provider profile retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to get provider profile', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to retrieve profile. Please try again.', 500);
        }
    }

    /**
     * Update provider profile
     * PUT /api/v1/provider/profile
     * Requires authentication with serviceProvider role
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
                'business_name' => 'sometimes|string|max:255',
                'business_description' => 'sometimes|string|max:1000',
                'address' => 'sometimes|string|max:500',
                'metadata' => 'sometimes|array',
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

            // Handle business fields in metadata
            $metadata = $user->metadata ?? [];
            if (isset($validatedData['business_name'])) {
                $metadata['business_name'] = $validatedData['business_name'];
            }
            if (isset($validatedData['business_description'])) {
                $metadata['business_description'] = $validatedData['business_description'];
            }
            if (isset($validatedData['address'])) {
                $metadata['address'] = $validatedData['address'];
            }
            if (isset($validatedData['metadata']) && is_array($validatedData['metadata'])) {
                $metadata = array_merge($metadata, $validatedData['metadata']);
            }

            if (!empty($metadata)) {
                $updateData['metadata'] = $metadata;
            }

            // Update user
            $user->update($updateData);

            // Refresh user data
            $user->refresh();

            // Get services count
            $servicesCount = Service::where('provider_id', $user->id)->count();

            $profileData = [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone_number' => $user->phone_number,
                'profile_image_url' => $user->profile_image_url,
                'is_active' => $user->is_active,
                'email_verified_at' => $user->email_verified_at,
                'last_login_at' => $user->last_login_at,
                'services_count' => $servicesCount,
                'metadata' => $this->metadataForResponse($user->metadata),
            ];

            Log::info('Provider profile updated', [
                'user_id' => $user->id,
                'updated_fields' => array_keys($updateData),
            ]);

            return $this->success($profileData, 'Provider profile updated successfully');

        } catch (\Exception $e) {
            Log::error('Failed to update provider profile', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to update profile. Please try again.', 500);
        }
    }

    /**
     * Get provider dashboard statistics
     * GET /api/v1/provider/dashboard
     * Requires authentication with serviceProvider role
     */
    public function getDashboard(): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            $providerId = $user->id;

            // Calculate statistics
            $totalServices = Service::where('provider_id', $providerId)->count();
            $activeServices = Service::where('provider_id', $providerId)
                ->where('status', 'active')
                ->count();

            $totalBookings = Booking::where('provider_id', $providerId)->count();
            $pendingBookings = Booking::where('provider_id', $providerId)
                ->where('status', 'pending')
                ->count();

            // Current month earnings (completed bookings only)
            $thisMonthEarnings = Booking::where('provider_id', $providerId)
                ->where('status', 'completed')
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->sum('total_price');

            // Current month bookings count
            $thisMonthBookings = Booking::where('provider_id', $providerId)
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->count();

            // Average rating (placeholder for future review system)
            $averageRating = 0;

            $dashboardData = [
                'total_services' => $totalServices,
                'active_services' => $activeServices,
                'total_bookings' => $totalBookings,
                'pending_bookings' => $pendingBookings,
                'this_month_earnings' => (float) $thisMonthEarnings,
                'this_month_bookings' => $thisMonthBookings,
                'average_rating' => $averageRating,
            ];

            Log::info('Provider dashboard retrieved', [
                'provider_id' => $providerId,
                'total_services' => $totalServices,
                'total_bookings' => $totalBookings,
            ]);

            return $this->success($dashboardData, 'Dashboard statistics retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to get provider dashboard', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to retrieve dashboard. Please try again.', 500);
        }
    }

    /**
     * Get earnings breakdown by time period
     * GET /api/v1/provider/earnings
     * Requires authentication with serviceProvider role
     * Query params: date_from, date_to, group_by (day|week|month)
     */
    public function getEarnings(Request $request): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            // Validate input
            $validator = Validator::make($request->all(), [
                'date_from' => 'sometimes|date',
                'date_to' => 'sometimes|date|after_or_equal:date_from',
                'group_by' => 'sometimes|in:day,week,month',
            ]);

            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }

            $providerId = $user->id;

            // Set default date range (current month)
            $dateFrom = $request->input('date_from', now()->startOfMonth()->toDateString());
            $dateTo = $request->input('date_to', now()->endOfMonth()->toDateString());
            $groupBy = $request->input('group_by', 'day');

            // Build base query for completed bookings
            $query = Booking::where('provider_id', $providerId)
                ->where('status', 'completed')
                ->whereBetween('created_at', [$dateFrom, $dateTo]);

            // Group by time period
            switch ($groupBy) {
                case 'day':
                    $earnings = $query
                        ->selectRaw('DATE(created_at) as date, SUM(total_price) as earnings, COUNT(*) as bookings')
                        ->groupBy('date')
                        ->orderBy('date')
                        ->get();
                    break;

                case 'week':
                    $earnings = $query
                        ->selectRaw('YEARWEEK(created_at) as week, MIN(DATE(created_at)) as date, SUM(total_price) as earnings, COUNT(*) as bookings')
                        ->groupBy('week')
                        ->orderBy('week')
                        ->get();
                    break;

                case 'month':
                    $earnings = $query
                        ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as month, SUM(total_price) as earnings, COUNT(*) as bookings')
                        ->groupBy('month')
                        ->orderBy('month')
                        ->get();
                    break;

                default:
                    $earnings = collect();
            }

            // Calculate total earnings
            $totalEarnings = $earnings->sum('earnings');
            $totalBookings = $earnings->sum('bookings');

            $earningsData = [
                'date_from' => $dateFrom,
                'date_to' => $dateTo,
                'group_by' => $groupBy,
                'total_earnings' => (float) $totalEarnings,
                'total_bookings' => $totalBookings,
                'breakdown' => $earnings->map(function ($item) use ($groupBy) {
                    return [
                        'period' => $groupBy === 'week' ? $item->week : ($groupBy === 'month' ? $item->month : $item->date),
                        'date' => $item->date ?? null,
                        'earnings' => (float) $item->earnings,
                        'bookings' => $item->bookings,
                    ];
                }),
            ];

            Log::info('Provider earnings retrieved', [
                'provider_id' => $providerId,
                'date_from' => $dateFrom,
                'date_to' => $dateTo,
                'group_by' => $groupBy,
                'total_earnings' => $totalEarnings,
            ]);

            return $this->success($earningsData, 'Earnings breakdown retrieved successfully');

        } catch (\Exception $e) {
            Log::error('Failed to get provider earnings', [
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->error('Failed to retrieve earnings. Please try again.', 500);
        }
    }

    /**
     * Get provider performance metrics
     * GET /api/v1/provider/metrics
     */
    public function getMetrics(): JsonResponse
    {
        try {
            $user = auth()->user();
            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            $providerId = $user->id;
            $completed = Booking::where('provider_id', $providerId)
                ->where('status', 'completed')
                ->count();
            $total = Booking::where('provider_id', $providerId)->count();
            $pending = Booking::where('provider_id', $providerId)
                ->where('status', 'pending')
                ->count();

            $metrics = [
                'rating' => 4.5,
                'total_reviews' => 0,
                'jobs_completed' => $completed,
                'average_response_time_minutes' => $pending > 0 ? 18 : 12,
                'is_top_performer' => $completed >= 10,
                'percentile' => $completed >= 10 ? 90.0 : 55.0,
                'total_bookings' => $total,
            ];

            return $this->success($metrics, 'Provider metrics retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Failed to get provider metrics', [
                'exception' => $e->getMessage(),
            ]);

            return $this->error('Failed to retrieve metrics. Please try again.', 500);
        }
    }

    /**
     * Upload a certification document (PDF/PNG/JPG, max 10MB)
     * POST /api/v1/provider/certifications/upload
     */
    public function uploadCertification(Request $request): JsonResponse
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return $this->error('User not authenticated', 401);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'document' => 'required|file|mimes:pdf,png,jpg,jpeg|max:10240',
            ]);

            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }

            $file = $request->file('document');
            $ext = strtolower($file->getClientOriginalExtension());
            $filename = time() . '_' . Str::uuid() . '.' . $ext;
            $path = $file->storeAs('certifications/' . $user->id, $filename, 'public');
            $documentUrl = Storage::disk('public')->url($path);

            $metadata = $user->metadata ?? [];
            $certifications = $metadata['certifications'] ?? [];
            $certifications[] = [
                'id' => (string) Str::uuid(),
                'name' => $request->name,
                'document_url' => $documentUrl,
                'file_type' => strtoupper($ext === 'jpeg' ? 'JPG' : $ext),
                'is_verified' => false,
                'uploaded_at' => now()->toIso8601String(),
                'verified_at' => null,
            ];
            $metadata['certifications'] = $certifications;
            $user->update(['metadata' => $metadata]);
            $user->refresh();

            $cert = end($certifications);

            Log::info('Certification uploaded', [
                'user_id' => $user->id,
                'certification_id' => $cert['id'],
            ]);

            return $this->success($cert, 'Certification uploaded successfully');
        } catch (\Exception $e) {
            Log::error('Failed to upload certification', [
                'exception' => $e->getMessage(),
            ]);

            return $this->error('Failed to upload certification. Please try again.', 500);
        }
    }

    /**
     * Get provider analytics (legacy method - kept for backward compatibility)
     */
    public function analytics(Request $request): JsonResponse
    {
        // Redirect to getDashboard
        return $this->getDashboard();
    }

    /**
     * Get provider dashboard data (legacy method - kept for backward compatibility)
     */
    public function dashboard(Request $request): JsonResponse
    {
        // Redirect to getDashboard
        return $this->getDashboard();
    }

    /**
     * Normalize user metadata for JSON responses.
     * Empty PHP arrays encode as JSON [] but clients expect an object {}.
     *
     * @param  array<string, mixed>|null  $metadata
     * @return array<string, mixed>|\stdClass
     */
    private function metadataForResponse(?array $metadata): array|\stdClass
    {
        if ($metadata === null || $metadata === [] || array_is_list($metadata)) {
            return new \stdClass();
        }

        return $metadata;
    }
}
