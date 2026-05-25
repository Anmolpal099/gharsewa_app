<?php

namespace App\Http\Controllers\API\V1\Admin;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Booking;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserManagementController extends BaseController
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'role' => 'nullable|in:customer,serviceProvider,admin',
            'status' => 'nullable|in:active,inactive',
            'search' => 'nullable|string|max:100',
        ]);

        $query = User::query();

        if ($request->filled('role')) {
            $role = $request->role;
            $query->where(function ($q) use ($role) {
                $q->where('role', $role)->orWhereJsonContains('roles', $role);
            });
        }

        if ($request->status === 'active') {
            $query->where('is_active', true);
        } elseif ($request->status === 'inactive') {
            $query->where('is_active', false);
        }

        if ($request->filled('search')) {
            $search = '%' . $request->search . '%';
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', $search)
                    ->orWhere('email', 'like', $search)
                    ->orWhere('phone_number', 'like', $search);
            });
        }

        $paginated = $query->orderByDesc('created_at')->paginate(20);

        $users = $paginated->getCollection()->map(function (User $user) {
            $bookingCount = Booking::where('customer_id', $user->id)
                ->orWhere('provider_id', $user->id)
                ->count();

            return [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'roles' => $user->roles ?? [$user->role],
                'phone' => $user->phone_number,
                'phone_number' => $user->phone_number,
                'is_active' => (bool) $user->is_active,
                'total_bookings' => $bookingCount,
                'created_at' => $user->created_at?->toDateTimeString(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $users,
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $asCustomer = Booking::where('customer_id', $user->id)->count();
        $asProvider = Booking::where('provider_id', $user->id)->count();
        $totalSpent = (float) Booking::where('customer_id', $user->id)
            ->where('status', 'completed')
            ->sum('total_price');

        $recentBookings = Booking::with(['service'])
            ->where(function ($q) use ($user) {
                $q->where('customer_id', $user->id)->orWhere('provider_id', $user->id);
            })
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->map(fn ($b) => [
                'id' => $b->id,
                'status' => $b->status,
                'scheduled_at' => $b->scheduled_at?->toDateTimeString(),
                'total_price' => (float) $b->total_price,
                'service_name' => $b->service?->name,
            ]);

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'roles' => $user->roles ?? [$user->role],
            'phone' => $user->phone_number,
            'phone_number' => $user->phone_number,
            'is_active' => (bool) $user->is_active,
            'profile_image_url' => $user->profile_image_url,
            'total_bookings' => $asCustomer + $asProvider,
            'total_spent' => $totalSpent,
            'created_at' => $user->created_at?->toDateTimeString(),
            'last_login_at' => $user->last_login_at?->toDateTimeString(),
            'recent_bookings' => $recentBookings,
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'phone_number' => 'sometimes|string|max:20',
        ]);

        $data = ['name' => $request->input('name', $user->name)];
        if ($request->has('phone_number')) {
            $data['phone_number'] = $request->phone_number;
        } elseif ($request->has('phone')) {
            $data['phone_number'] = $request->phone;
        }
        $user->update($data);

        return $this->success($user->only(['id', 'name', 'email', 'phone_number']), 'User updated successfully');
    }

    public function activate(Request $request, string $id): JsonResponse
    {
        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $user->update(['is_active' => true]);

        return $this->success(null, 'User activated successfully');
    }

    public function deactivate(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $user->update(['is_active' => false]);

        return $this->success(null, 'User deactivated successfully');
    }

    public function passwordReset(Request $request, string $id): JsonResponse
    {
        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $tempPassword = Str::random(12);
        $user->update(['password' => Hash::make($tempPassword)]);

        return $this->success([
            'message' => 'Temporary password generated. Share securely with the user.',
            'temporary_password' => $tempPassword,
        ], 'Password reset successfully');
    }

    public function setRole(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'role' => 'required|in:customer,serviceProvider,admin',
        ]);

        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $user->update([
            'role' => $request->role,
            'roles' => array_values(array_unique(array_merge($user->roles ?? [], [$request->role]))),
        ]);

        return $this->success(null, 'User role updated successfully');
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = User::find($id);
        if (!$user) {
            return $this->error('User not found', 404);
        }

        $user->delete();

        return $this->success(null, 'User deleted successfully');
    }
}
