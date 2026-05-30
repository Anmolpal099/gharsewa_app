<?php

namespace App\Http\Controllers\API\V1\Admin;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Booking;
use App\Events\BookingStatusChanged;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingManagementController extends BaseController
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'status' => 'nullable|in:pending,confirmed,completed,cancelled,inProgress',
            'customer_id' => 'nullable|string',
            'provider_id' => 'nullable|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'search' => 'nullable|string|max:100',
        ]);

        $query = Booking::with(['customer', 'service', 'provider']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }
        if ($request->filled('provider_id')) {
            $query->where('provider_id', $request->provider_id);
        }
        if ($request->filled('start_date')) {
            $query->whereDate('scheduled_at', '>=', $request->start_date);
        }
        if ($request->filled('end_date')) {
            $query->whereDate('scheduled_at', '<=', $request->end_date);
        }
        if ($request->filled('search')) {
            $search = '%' . $request->search . '%';
            $query->where(function ($q) use ($search) {
                $q->where('id', 'like', $search)
                    ->orWhereHas('customer', fn ($c) => $c->where('name', 'like', $search)->orWhere('email', 'like', $search))
                    ->orWhereHas('provider', fn ($p) => $p->where('name', 'like', $search))
                    ->orWhereHas('service', fn ($s) => $s->where('name', 'like', $search));
            });
        }

        $paginated = $query->orderByDesc('scheduled_at')->paginate(20);

        $bookings = $paginated->getCollection()->map(fn (Booking $b) => [
            'id' => $b->id,
            'customer_id' => $b->customer_id,
            'provider_id' => $b->provider_id,
            'service_id' => $b->service_id,
            'customer_name' => $b->customer?->name,
            'customer_email' => $b->customer?->email,
            'provider_name' => $b->provider?->name,
            'service_name' => $b->service?->name,
            'scheduled_at' => $b->scheduled_at?->toDateTimeString(),
            'status' => $b->status,
            'total_price' => (float) $b->total_price,
            'currency' => $b->currency ?? 'NPR',
            'cancellation_reason' => $b->cancellation_reason,
            'admin_notes' => $b->metadata['admin_notes'] ?? [],
            'created_at' => $b->created_at?->toDateTimeString(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $bookings,
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }

    public function cancel(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'reason' => 'required|string|max:500',
            'refund' => 'sometimes|boolean',
        ]);

        $booking = Booking::find($id);
        if (!$booking) {
            return $this->error('Booking not found', 404);
        }

        // Store old status for event
        $oldStatus = $booking->status;

        $booking->update([
            'status' => 'cancelled',
            'cancellation_reason' => $request->reason,
        ]);

        // Dispatch BookingStatusChanged event
        event(new BookingStatusChanged($booking, $oldStatus, 'cancelled'));

        return $this->success(null, 'Booking cancelled successfully');
    }

    public function addNote(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'note' => 'required|string|max:1000',
        ]);

        $booking = Booking::find($id);
        if (!$booking) {
            return $this->error('Booking not found', 404);
        }

        $metadata = $booking->metadata ?? [];
        $notes = $metadata['admin_notes'] ?? [];
        $notes[] = [
            'note' => $request->note,
            'admin_id' => auth()->id(),
            'created_at' => now()->toDateTimeString(),
        ];
        $metadata['admin_notes'] = $notes;
        $booking->update(['metadata' => $metadata]);

        return $this->success(['admin_notes' => $notes], 'Note added successfully');
    }
}
