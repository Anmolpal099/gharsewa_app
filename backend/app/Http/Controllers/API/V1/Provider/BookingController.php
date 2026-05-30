<?php

namespace App\Http\Controllers\API\V1\Provider;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Booking;
use App\Services\Notification\NotificationService;
use App\Events\BookingStatusChanged;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BookingController extends BaseController
{
    protected NotificationService $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * List provider's bookings
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            // Build query
            $query = Booking::where('provider_id', $providerId)
                ->with(['customer', 'service', 'provider']);
            
            // Filter by status if provided
            if ($request->has('status')) {
                $query->byStatus($request->status);
            }
            
            // Filter by date range if provided
            if ($request->has('date_from')) {
                $query->whereDate('scheduled_at', '>=', $request->date_from);
            }
            
            if ($request->has('date_to')) {
                $query->whereDate('scheduled_at', '<=', $request->date_to);
            }
            
            // Paginate results
            $bookings = $query->orderBy('scheduled_at', 'desc')
                ->paginate(15);
            
            Log::info('Provider bookings retrieved', [
                'provider_id' => $providerId,
                'count' => $bookings->count()
            ]);
            
            return $this->paginated($bookings, 'Bookings retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error retrieving provider bookings', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve bookings', 500);
        }
    }

    /**
     * Get booking details
     * 
     * @param string $id
     * @return JsonResponse
     */
    public function show(string $id): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            // Load booking with relationships
            $booking = Booking::with(['customer', 'service', 'provider'])
                ->find($id);
            
            if (!$booking) {
                return $this->error('Booking not found', 404);
            }
            
            // Verify provider ownership
            if ($booking->provider_id !== $providerId) {
                Log::warning('Unauthorized booking access attempt', [
                    'booking_id' => $id,
                    'provider_id' => $providerId,
                    'booking_provider' => $booking->provider_id
                ]);
                
                return $this->error('Unauthorized access to booking', 403);
            }
            
            Log::info('Booking details retrieved', [
                'booking_id' => $id,
                'provider_id' => $providerId
            ]);
            
            return $this->success($booking, 'Booking retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error retrieving booking', [
                'booking_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve booking', 500);
        }
    }

    /**
     * Accept pending booking
     * 
     * @param string $id
     * @return JsonResponse
     */
    public function accept(string $id): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            // Find booking
            $booking = Booking::find($id);
            
            if (!$booking) {
                return $this->error('Booking not found', 404);
            }
            
            // Verify provider ownership
            if ($booking->provider_id !== $providerId) {
                Log::warning('Unauthorized booking accept attempt', [
                    'booking_id' => $id,
                    'provider_id' => $providerId,
                    'booking_provider' => $booking->provider_id
                ]);
                
                return $this->error('Unauthorized access to booking', 403);
            }
            
            // Check if status is pending
            if ($booking->status !== 'pending') {
                return $this->error(
                    'Only pending bookings can be accepted. Current status: ' . $booking->status,
                    400
                );
            }
            
            // Store old status for event
            $oldStatus = $booking->status;
            
            // Update status to confirmed
            $booking->status = 'confirmed';
            $booking->save();
            
            // Dispatch BookingStatusChanged event
            event(new BookingStatusChanged($booking, $oldStatus, 'confirmed'));
            
            // Load relationships
            $booking->load(['customer', 'service', 'provider']);
            
            // Send acceptance notification to customer (urgent)
            try {
                $this->notificationService->sendBookingNotification(
                    $booking->customer,
                    'booking_accepted',
                    [
                        'booking_id' => $booking->id,
                        'provider_name' => auth()->user()->name,
                        'service_name' => $booking->service->name,
                        'scheduled_at' => $booking->scheduled_at
                    ],
                    true // urgent
                );
            } catch (\Exception $e) {
                // Log error but don't fail the acceptance
                Log::error('Failed to send acceptance notification', [
                    'booking_id' => $booking->id,
                    'error' => $e->getMessage()
                ]);
            }
            
            Log::info('Booking accepted', [
                'booking_id' => $id,
                'provider_id' => $providerId
            ]);
            
            return $this->success($booking, 'Booking accepted successfully');
            
        } catch (\Exception $e) {
            Log::error('Error accepting booking', [
                'booking_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to accept booking', 500);
        }
    }

    /**
     * Reject pending booking
     * 
     * @param Request $request
     * @param string $id
     * @return JsonResponse
     */
    public function reject(Request $request, string $id): JsonResponse
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'rejection_reason' => 'required|string|max:500',
            ]);
            
            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }
            
            $providerId = auth()->user()->id;
            
            // Find booking
            $booking = Booking::find($id);
            
            if (!$booking) {
                return $this->error('Booking not found', 404);
            }
            
            // Verify provider ownership
            if ($booking->provider_id !== $providerId) {
                Log::warning('Unauthorized booking reject attempt', [
                    'booking_id' => $id,
                    'provider_id' => $providerId,
                    'booking_provider' => $booking->provider_id
                ]);
                
                return $this->error('Unauthorized access to booking', 403);
            }
            
            // Check if status is pending
            if ($booking->status !== 'pending') {
                return $this->error(
                    'Only pending bookings can be rejected. Current status: ' . $booking->status,
                    400
                );
            }
            
            // Store old status for event
            $oldStatus = $booking->status;
            
            // Update status to rejected and save reason
            $booking->status = 'rejected';
            $booking->cancellation_reason = $request->rejection_reason;
            $booking->save();
            
            // Dispatch BookingStatusChanged event
            event(new BookingStatusChanged($booking, $oldStatus, 'rejected'));
            
            // Load relationships
            $booking->load(['customer', 'service', 'provider']);
            
            // Send rejection notification to customer (urgent)
            try {
                $this->notificationService->sendBookingNotification(
                    $booking->customer,
                    'booking_rejected',
                    [
                        'booking_id' => $booking->id,
                        'provider_name' => auth()->user()->name,
                        'service_name' => $booking->service->name,
                        'scheduled_at' => $booking->scheduled_at,
                        'rejection_reason' => $request->rejection_reason
                    ],
                    true // urgent
                );
            } catch (\Exception $e) {
                // Log error but don't fail the rejection
                Log::error('Failed to send rejection notification', [
                    'booking_id' => $booking->id,
                    'error' => $e->getMessage()
                ]);
            }
            
            Log::info('Booking rejected', [
                'booking_id' => $id,
                'provider_id' => $providerId,
                'reason' => $request->rejection_reason
            ]);
            
            return $this->success($booking, 'Booking rejected successfully');
            
        } catch (\Exception $e) {
            Log::error('Error rejecting booking', [
                'booking_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to reject booking', 500);
        }
    }

    /**
     * Send a counter-offer for a pending booking
     *
     * POST /api/v1/provider/bookings/{id}/counter
     */
    public function counter(Request $request, string $id): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'counter_price' => 'required|numeric|min:0.01',
                'message' => 'nullable|string|max:500',
            ]);

            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }

            $providerId = auth()->user()->id;
            $booking = Booking::find($id);

            if (!$booking) {
                return $this->error('Booking not found', 404);
            }

            if ($booking->provider_id !== $providerId) {
                return $this->error('Unauthorized access to booking', 403);
            }

            if ($booking->status !== 'pending') {
                return $this->error(
                    'Only pending bookings can receive counter-offers. Current status: ' . $booking->status,
                    400
                );
            }

            $metadata = $booking->metadata ?? [];
            $metadata['counter_offer'] = [
                'original_price' => (float) $booking->total_price,
                'counter_price' => (float) $request->counter_price,
                'message' => $request->message,
                'status' => 'pending',
                'created_at' => now()->toIso8601String(),
            ];

            $booking->metadata = $metadata;
            $booking->save();
            $booking->load(['customer', 'service', 'provider']);

            Log::info('Counter-offer sent', [
                'booking_id' => $id,
                'provider_id' => $providerId,
                'counter_price' => $request->counter_price,
            ]);

            return $this->success($booking, 'Counter-offer sent successfully');
        } catch (\Exception $e) {
            Log::error('Error sending counter-offer', [
                'booking_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return $this->error('Failed to send counter-offer', 500);
        }
    }

    /**
     * Mark confirmed booking as completed
     * 
     * @param string $id
     * @return JsonResponse
     */
    public function complete(string $id): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            // Find booking
            $booking = Booking::find($id);
            
            if (!$booking) {
                return $this->error('Booking not found', 404);
            }
            
            // Verify provider ownership
            if ($booking->provider_id !== $providerId) {
                Log::warning('Unauthorized booking complete attempt', [
                    'booking_id' => $id,
                    'provider_id' => $providerId,
                    'booking_provider' => $booking->provider_id
                ]);
                
                return $this->error('Unauthorized access to booking', 403);
            }
            
            // Check if status is confirmed
            if ($booking->status !== 'confirmed') {
                return $this->error(
                    'Only confirmed bookings can be completed. Current status: ' . $booking->status,
                    400
                );
            }
            
            // Store old status for event
            $oldStatus = $booking->status;
            
            // Update status to completed
            $booking->status = 'completed';
            $booking->save();
            
            // Dispatch BookingStatusChanged event
            event(new BookingStatusChanged($booking, $oldStatus, 'completed'));
            
            // Load relationships
            $booking->load(['customer', 'service', 'provider']);
            
            // Send completion notification to customer (non-urgent, use AI timing)
            try {
                $this->notificationService->sendBookingNotification(
                    $booking->customer,
                    'booking_completed',
                    [
                        'booking_id' => $booking->id,
                        'provider_name' => auth()->user()->name,
                        'service_name' => $booking->service->name,
                        'completed_at' => now()->toIso8601String()
                    ],
                    false // non-urgent
                );
            } catch (\Exception $e) {
                // Log error but don't fail the completion
                Log::error('Failed to send completion notification', [
                    'booking_id' => $booking->id,
                    'error' => $e->getMessage()
                ]);
            }
            
            Log::info('Booking completed', [
                'booking_id' => $id,
                'provider_id' => $providerId
            ]);
            
            return $this->success($booking, 'Booking marked as completed successfully');
            
        } catch (\Exception $e) {
            Log::error('Error completing booking', [
                'booking_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to complete booking', 500);
        }
    }

    /**
     * Get list of pending bookings only
     * 
     * @return JsonResponse
     */
    public function pending(): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            // Query pending bookings
            $bookings = Booking::where('provider_id', $providerId)
                ->where('status', 'pending')
                ->with(['customer', 'service', 'provider'])
                ->orderBy('scheduled_at', 'asc')
                ->paginate(15);
            
            Log::info('Provider pending bookings retrieved', [
                'provider_id' => $providerId,
                'count' => $bookings->count()
            ]);
            
            return $this->paginated($bookings, 'Pending bookings retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error retrieving pending bookings', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve pending bookings', 500);
        }
    }

    /**
     * Get booking statistics
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function stats(Request $request): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            // Default to current month if no date range provided
            $dateFrom = $request->input('date_from', now()->startOfMonth()->toDateString());
            $dateTo = $request->input('date_to', now()->endOfMonth()->toDateString());
            
            // Build base query for the date range
            $query = Booking::where('provider_id', $providerId)
                ->whereDate('scheduled_at', '>=', $dateFrom)
                ->whereDate('scheduled_at', '<=', $dateTo);
            
            // Calculate statistics
            $stats = [
                'total_bookings' => (clone $query)->count(),
                'pending_count' => (clone $query)->where('status', 'pending')->count(),
                'confirmed_count' => (clone $query)->where('status', 'confirmed')->count(),
                'completed_count' => (clone $query)->where('status', 'completed')->count(),
                'cancelled_count' => (clone $query)->where('status', 'cancelled')->count(),
                'rejected_count' => (clone $query)->where('status', 'rejected')->count(),
                'total_revenue' => (clone $query)->where('status', 'completed')->sum('total_price'),
                'date_from' => $dateFrom,
                'date_to' => $dateTo,
            ];
            
            Log::info('Provider booking statistics retrieved', [
                'provider_id' => $providerId,
                'date_from' => $dateFrom,
                'date_to' => $dateTo
            ]);
            
            return $this->success($stats, 'Booking statistics retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error retrieving booking statistics', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve booking statistics', 500);
        }
    }
}
