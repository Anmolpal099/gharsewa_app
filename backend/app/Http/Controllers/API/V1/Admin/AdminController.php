<?php

namespace App\Http\Controllers\API\V1\Admin;

use App\Http\Controllers\API\V1\BaseController;
use App\Models\Booking;
use App\Models\Service;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends BaseController
{
    public function dashboard(Request $request): JsonResponse
    {
        $totalUsers = User::count();
        $totalCustomers = User::where('role', 'customer')
            ->orWhereJsonContains('roles', 'customer')
            ->count();
        $totalProviders = User::where('role', 'serviceProvider')
            ->orWhereJsonContains('roles', 'serviceProvider')
            ->count();
        $totalAdmins = User::where('role', 'admin')
            ->orWhereJsonContains('roles', 'admin')
            ->count();

        $bookingCounts = Booking::selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        $totalBookings = Booking::count();
        $totalRevenue = (float) Booking::where('status', 'completed')->sum('total_price');
        $monthRevenue = (float) Booking::where('status', 'completed')
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('total_price');

        $recentBookings = Booking::with(['customer', 'service', 'provider'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $recentUsers = User::orderByDesc('created_at')->limit(3)->get();

        $activities = [];
        foreach ($recentUsers as $user) {
            $activities[] = [
                'type' => 'new_user',
                'message' => "New user registered: {$user->name}",
                'timestamp' => $user->created_at?->toDateTimeString(),
            ];
        }
        foreach ($recentBookings as $booking) {
            $activities[] = [
                'type' => 'new_booking',
                'message' => 'New booking #' . substr($booking->id, 0, 8),
                'timestamp' => $booking->created_at?->toDateTimeString(),
            ];
        }
        usort($activities, fn ($a, $b) => strcmp($b['timestamp'] ?? '', $a['timestamp'] ?? ''));
        $activities = array_slice($activities, 0, 8);

        return $this->success([
            'total_users' => $totalUsers,
            'total_customers' => $totalCustomers,
            'total_providers' => $totalProviders,
            'total_admins' => $totalAdmins,
            'total_bookings' => $totalBookings,
            'pending_bookings' => (int) ($bookingCounts['pending'] ?? 0),
            'confirmed_bookings' => (int) ($bookingCounts['confirmed'] ?? 0),
            'completed_bookings' => (int) ($bookingCounts['completed'] ?? 0),
            'cancelled_bookings' => (int) ($bookingCounts['cancelled'] ?? 0),
            'total_revenue' => $totalRevenue,
            'current_month_revenue' => $monthRevenue,
            'active_services' => Service::where('status', 'active')->count(),
            'platform_rating' => 4.6,
            'recent_activities' => $activities,
        ]);
    }

    public function analytics(Request $request): JsonResponse
    {
        $request->validate([
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);

        $months = collect(range(2, 0))->map(function ($i) {
            $date = Carbon::now()->subMonths($i);
            return [
                'month' => $date->format('M'),
                'year' => $date->year,
                'month_num' => $date->month,
            ];
        });

        $userGrowth = $months->map(function ($m) {
            $customers = User::whereMonth('created_at', $m['month_num'])
                ->whereYear('created_at', $m['year'])
                ->where(function ($q) {
                    $q->where('role', 'customer')->orWhereJsonContains('roles', 'customer');
                })
                ->count();
            $providers = User::whereMonth('created_at', $m['month_num'])
                ->whereYear('created_at', $m['year'])
                ->where(function ($q) {
                    $q->where('role', 'serviceProvider')->orWhereJsonContains('roles', 'serviceProvider');
                })
                ->count();

            return [
                'month' => $m['month'],
                'customers' => $customers,
                'providers' => $providers,
            ];
        });

        $bookingTrends = $months->map(function ($m) {
            return [
                'month' => $m['month'],
                'count' => Booking::whereMonth('created_at', $m['month_num'])
                    ->whereYear('created_at', $m['year'])
                    ->count(),
            ];
        });

        $revenueTrends = $months->map(function ($m) {
            return [
                'month' => $m['month'],
                'amount' => (float) Booking::where('status', 'completed')
                    ->whereMonth('created_at', $m['month_num'])
                    ->whereYear('created_at', $m['year'])
                    ->sum('total_price'),
            ];
        });

        $topCategories = Service::select('category', DB::raw('COUNT(*) as bookings'))
            ->groupBy('category')
            ->orderByDesc('bookings')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'name' => $row->category,
                'bookings' => (int) $row->bookings,
            ]);

        return $this->success([
            'user_growth' => $userGrowth,
            'booking_trends' => $bookingTrends,
            'revenue_trends' => $revenueTrends,
            'top_categories' => $topCategories,
        ]);
    }

    public function reports(Request $request): JsonResponse
    {
        $request->validate([
            'type' => 'required|in:users,bookings,revenue,services',
            'format' => 'required|in:json,csv,pdf',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
        ]);

        $start = Carbon::parse($request->start_date)->startOfDay();
        $end = Carbon::parse($request->end_date)->endOfDay();

        $rows = match ($request->type) {
            'users' => User::whereBetween('created_at', [$start, $end])
                ->get(['id', 'name', 'email', 'role', 'is_active', 'created_at']),
            'bookings' => Booking::whereBetween('created_at', [$start, $end])
                ->get(['id', 'customer_id', 'provider_id', 'status', 'total_price', 'scheduled_at', 'created_at']),
            'services' => Service::whereBetween('created_at', [$start, $end])
                ->get(['id', 'name', 'category', 'price', 'status', 'created_at']),
            default => Booking::where('status', 'completed')
                ->whereBetween('created_at', [$start, $end])
                ->get(['id', 'total_price', 'currency', 'created_at']),
        };

        return $this->success([
            'type' => $request->type,
            'format' => $request->format,
            'period' => [
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ],
            'row_count' => $rows->count(),
            'rows' => $rows,
            'generated_at' => now()->toIso8601String(),
        ]);
    }
}
