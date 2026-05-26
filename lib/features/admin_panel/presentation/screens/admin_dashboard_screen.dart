import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/admin_providers.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_trend_chart.dart';
import '../widgets/ai_analytics_section.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return dashAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () {
          ref.invalidate(adminDashboardProvider);
          ref.invalidate(adminAnalyticsProvider);
        },
      ),
      data: (dash) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminDashboardProvider);
            ref.invalidate(adminAnalyticsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatCard(
                  label: 'Total Revenue',
                  value: 'NPR ${dash.totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.payments,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  'This month: NPR ${dash.currentMonthRevenue.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = isWide ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 2.2 : 1.6,
                      children: [
                        AdminStatCard(
                          label: 'Total Users',
                          value: '${dash.totalUsers}',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        AdminStatCard(
                          label: 'Customers',
                          value: '${dash.totalCustomers}',
                          icon: Icons.person,
                          color: Colors.indigo,
                        ),
                        AdminStatCard(
                          label: 'Providers',
                          value: '${dash.totalProviders}',
                          icon: Icons.engineering,
                          color: Colors.green,
                        ),
                        AdminStatCard(
                          label: 'Total Bookings',
                          value: '${dash.totalBookings}',
                          icon: Icons.book_online,
                          color: Colors.deepPurple,
                        ),
                        AdminStatCard(
                          label: 'Pending',
                          value: '${dash.pendingBookings}',
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                        AdminStatCard(
                          label: 'Completed',
                          value: '${dash.completedBookings}',
                          icon: Icons.check_circle,
                          color: Colors.teal,
                        ),
                        AdminStatCard(
                          label: 'Active Services',
                          value: '${dash.activeServices}',
                          icon: Icons.home_repair_service,
                          color: Colors.brown,
                        ),
                        AdminStatCard(
                          label: 'Platform Rating',
                          value: dash.platformRating.toStringAsFixed(1),
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                analyticsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (analytics) => Column(
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AdminTrendChart(
                                title: 'User Growth',
                                points: analytics.userGrowthCustomers,
                                secondaryPoints: analytics.userGrowthProviders,
                                primaryColor: Colors.blue,
                                secondaryColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AdminTrendChart(
                                title: 'Booking Trends',
                                points: analytics.bookingTrends,
                                primaryColor: Colors.deepPurple,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        AdminTrendChart(
                          title: 'User Growth (Customers)',
                          points: analytics.userGrowthCustomers,
                          primaryColor: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        AdminTrendChart(
                          title: 'Booking Trends',
                          points: analytics.bookingTrends,
                          primaryColor: Colors.deepPurple,
                        ),
                      ],
                      const SizedBox(height: 16),
                      AdminTrendChart(
                        title: 'Revenue Trends (NPR)',
                        points: analytics.revenueTrends,
                        primaryColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const AIAnalyticsSection(),
                const SizedBox(height: 24),
                ActivityTimeline(activities: dash.recentActivities),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
