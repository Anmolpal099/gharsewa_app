<?php

namespace App\Http\Controllers\API\V1\Customer;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Booking;
use App\Models\Service;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BookingController extends BaseController
{
    /**
     * List customer's bookings
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $customerId = auth()->user()->id;
            
            // Build query
            $query = Booking::where('customer_id', $customerId)
                ->with(['customer', 'service', 'provider']);
            
            // Filter by status if provided
            if ($request->has('status')) {
                $query->byStatus($request->status);
            }
            
            // Paginate results
            $bookings = $query->orderBy('created_at', 'desc')
                ->paginate(15);
            
            Log::info('Customer bookings retrieved', [
                'customer_id' => $customerId,
                'count' => $bookings->count()
            ]);
            
            return $this->paginated($bookings, 'Bookings retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error retrieving customer bookings', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve bookings', 500);
        }
    }

    /**
     * Create new booking
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function store(Request $request): JsonResponse
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'service_id' => 'required|exists:services,id',
                'scheduled_at' => 'required|date|after:now',
                'notes' => 'nullable|string|max:500',
            ]);
            
            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }
            
            $customerId = auth()->user()->id;
            
            // Load service and verify it's active
            $service = Service::find($request->service_id);
            
            if (!$service) {
                return $this->error('Service not found', 404);
            }
            
            if ($service->status !== 'active') {
                return $this->error('Service is not available for booking', 400);
            }
            
            // Create booking
            $booking = Booking::create([
                'customer_id' => $customerId,
                'service_id' => $service->id,
                'provider_id' => $service->provider_id,
                'scheduled_at' => $request->scheduled_at,
                'total_price' => $service->price,
                'currency' => $service->currency,
                'status' => 'pending',
            ]);
            
            // Load relationships
            $booking->load(['customer', 'service', 'provider']);
            
            Log::info('Booking created', [
                'booking_id' => $booking->id,
                'customer_id' => $customerId,
                'service_id' => $service->id
            ]);
            
            return $this->success($booking, 'Booking created successfully', 201);
            
        } catch (\Exception $e) {
            Log::error('Error creating booking', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to create booking', 500);
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
            $customerId = auth()->user()->id;
            
            // Load booking with relationships
            $booking = Booking::with(['customer', 'service', 'provider'])
                ->find($id);
            
            if (!$booking) {
                return $this->error('Booking not found', 404);
            }
            
            // Verify ownership
            if ($booking->customer_id !== $customerId) {
                Log::warning('Unauthorized booking access attempt', [
                    'booking_id' => $id,
                    'customer_id' => $customerId,
                    'booking_owner' => $booking->customer_id
                ]);
                
                return $this->error('Unauthorized access to booking', 403);
            }
            
            Log::info('Booking details retrieved', [
                'booking_id' => $id,
                'customer_id' => $customerId
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
     * Cancel booking
     * 
     * @param Request $request
     * @param string $id
     * @return JsonResponse
     */
    public function cancel(Request $request, string $id): JsonResponse
    {
        try {
            $customerId = auth()->user()->id;
            
            // Find booking
            $booking = Booking::find($id);
            
            if (!$booking) {
                return $this->error('Booking not found', 404);
            }
            
            // Verify ownership
            if ($booking->customer_id !== $customerId) {
                Log::warning('Unauthorized booking cancellation attempt', [
                    'booking_id' => $id,
                    'customer_id' => $customerId,
                    'booking_owner' => $booking->customer_id
                ]);
                
                return $this->error('Unauthorized access to booking', 403);
            }
            
            // Check if status is cancellable
            if (!in_array($booking->status, ['pending', 'confirmed'])) {
                return $this->error(
                    'Booking cannot be cancelled. Only pending or confirmed bookings can be cancelled.',
                    400
                );
            }
            
            // Update status to cancelled
            $booking->status = 'cancelled';
            
            // Save cancellation reason if provided
            if ($request->has('cancellation_reason')) {
                $booking->cancellation_reason = $request->cancellation_reason;
            }
            
            $booking->save();
            
            // Load relationships
            $booking->load(['customer', 'service', 'provider']);
            
            Log::info('Booking cancelled', [
                'booking_id' => $id,
                'customer_id' => $customerId,
                'reason' => $request->cancellation_reason
            ]);
            
            return $this->success($booking, 'Booking cancelled successfully');
            
        } catch (\Exception $e) {
            Log::error('Error cancelling booking', [
                'booking_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to cancel booking', 500);
        }
    }

    /**
     * Check service availability (placeholder)
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function checkAvailability(Request $request): JsonResponse
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'service_id' => 'required|exists:services,id',
                'date' => 'required|date',
            ]);
            
            if ($validator->fails()) {
                return $this->error('Validation failed', 422, $validator->errors());
            }
            
            // Placeholder response - will be enhanced later with actual availability logic
            $availabilityData = [
                'service_id' => $request->service_id,
                'date' => $request->date,
                'available' => true,
                'available_slots' => [
                    '09:00', '10:00', '11:00', '14:00', '15:00', '16:00'
                ],
                'message' => 'This is placeholder data. Actual availability logic will be implemented later.'
            ];
            
            Log::info('Availability check requested', [
                'service_id' => $request->service_id,
                'date' => $request->date
            ]);
            
            return $this->success($availabilityData, 'Availability data retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error checking availability', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to check availability', 500);
        }
    }
}
