<?php

namespace App\Http\Controllers\API\V1\Provider;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Service;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class ServiceController extends BaseController
{
    /**
     * List provider's services with filtering and pagination
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $providerId = auth()->user()->id;
            
            $query = Service::where('provider_id', $providerId)
                ->withCount('bookings')
                ->with('provider');
            
            // Filter by status if provided
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }
            
            // Filter by category if provided
            if ($request->has('category')) {
                $query->where('category', $request->category);
            }
            
            // Paginate results (15 per page)
            $services = $query->paginate(15);
            
            Log::info('Provider services listed', [
                'provider_id' => $providerId,
                'count' => $services->total()
            ]);
            
            return $this->paginated($services, 'Services retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error listing provider services', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve services', 500);
        }
    }

    /**
     * Create a new service
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'category' => 'required|string',
                'price' => 'required|numeric|min:0',
                'duration_minutes' => 'required|integer|min:15',
                'currency' => 'string|in:NPR,USD',
            ]);
            
            // Set provider_id from authenticated user
            $validated['provider_id'] = auth()->user()->id;
            
            // Set default status to active
            $validated['status'] = 'active';
            
            // Set default currency if not provided
            if (!isset($validated['currency'])) {
                $validated['currency'] = 'NPR';
            }
            
            $service = Service::create($validated);
            
            Log::info('Service created', [
                'service_id' => $service->id,
                'provider_id' => $validated['provider_id']
            ]);
            
            return $this->success($service, 'Service created successfully', 201);
            
        } catch (ValidationException $e) {
            return $this->error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Error creating service', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to create service', 500);
        }
    }

    /**
     * Get service details with bookings count
     * 
     * @param string $id
     * @return JsonResponse
     */
    public function show(string $id): JsonResponse
    {
        try {
            $service = Service::withCount('bookings')->find($id);
            
            if (!$service) {
                return $this->error('Service not found', 404);
            }
            
            // Verify ownership
            if ($service->provider_id !== auth()->user()->id) {
                Log::warning('Unauthorized service access attempt', [
                    'service_id' => $id,
                    'provider_id' => auth()->user()->id,
                    'owner_id' => $service->provider_id
                ]);
                
                return $this->error('Unauthorized access', 403);
            }
            
            return $this->success($service, 'Service retrieved successfully');
            
        } catch (\Exception $e) {
            Log::error('Error retrieving service', [
                'service_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to retrieve service', 500);
        }
    }

    /**
     * Update service information
     * 
     * @param Request $request
     * @param string $id
     * @return JsonResponse
     */
    public function update(Request $request, string $id): JsonResponse
    {
        try {
            $service = Service::find($id);
            
            if (!$service) {
                return $this->error('Service not found', 404);
            }
            
            // Verify ownership
            if ($service->provider_id !== auth()->user()->id) {
                Log::warning('Unauthorized service update attempt', [
                    'service_id' => $id,
                    'provider_id' => auth()->user()->id,
                    'owner_id' => $service->provider_id
                ]);
                
                return $this->error('Unauthorized access', 403);
            }
            
            $validated = $request->validate([
                'name' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'category' => 'sometimes|string',
                'price' => 'sometimes|numeric|min:0',
                'duration_minutes' => 'sometimes|integer|min:15',
                'currency' => 'sometimes|string|in:NPR,USD',
            ]);
            
            $service->update($validated);
            
            Log::info('Service updated', [
                'service_id' => $id,
                'provider_id' => auth()->user()->id
            ]);
            
            return $this->success($service, 'Service updated successfully');
            
        } catch (ValidationException $e) {
            return $this->error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Error updating service', [
                'service_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to update service', 500);
        }
    }

    /**
     * Soft delete service (check for active bookings first)
     * 
     * @param string $id
     * @return JsonResponse
     */
    public function destroy(string $id): JsonResponse
    {
        try {
            $service = Service::find($id);
            
            if (!$service) {
                return $this->error('Service not found', 404);
            }
            
            // Verify ownership
            if ($service->provider_id !== auth()->user()->id) {
                Log::warning('Unauthorized service deletion attempt', [
                    'service_id' => $id,
                    'provider_id' => auth()->user()->id,
                    'owner_id' => $service->provider_id
                ]);
                
                return $this->error('Unauthorized access', 403);
            }
            
            // Check for active bookings (pending or confirmed)
            $activeBookingsCount = $service->bookings()
                ->whereIn('status', ['pending', 'confirmed'])
                ->count();
            
            if ($activeBookingsCount > 0) {
                return $this->error(
                    'Cannot delete service with active bookings. Please complete or cancel all pending and confirmed bookings first.',
                    400,
                    ['active_bookings_count' => $activeBookingsCount]
                );
            }
            
            // Soft delete the service
            $service->delete();
            
            Log::info('Service deleted', [
                'service_id' => $id,
                'provider_id' => auth()->user()->id
            ]);
            
            return $this->success(null, 'Service deleted successfully');
            
        } catch (\Exception $e) {
            Log::error('Error deleting service', [
                'service_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to delete service', 500);
        }
    }

    /**
     * Activate or deactivate service
     * 
     * @param Request $request
     * @param string $id
     * @return JsonResponse
     */
    public function updateStatus(Request $request, string $id): JsonResponse
    {
        try {
            $service = Service::find($id);
            
            if (!$service) {
                return $this->error('Service not found', 404);
            }
            
            // Verify ownership
            if ($service->provider_id !== auth()->user()->id) {
                Log::warning('Unauthorized service status update attempt', [
                    'service_id' => $id,
                    'provider_id' => auth()->user()->id,
                    'owner_id' => $service->provider_id
                ]);
                
                return $this->error('Unauthorized access', 403);
            }
            
            $validated = $request->validate([
                'status' => 'required|in:active,inactive',
            ]);
            
            $service->update(['status' => $validated['status']]);
            
            Log::info('Service status updated', [
                'service_id' => $id,
                'provider_id' => auth()->user()->id,
                'new_status' => $validated['status']
            ]);
            
            return $this->success($service, 'Service status updated successfully');
            
        } catch (ValidationException $e) {
            return $this->error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Error updating service status', [
                'service_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->error('Failed to update service status', 500);
        }
    }
}
