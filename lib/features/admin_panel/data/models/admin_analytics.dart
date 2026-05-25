class TrendPoint {
  final String month;
  final double value;
  final double? secondary;

  const TrendPoint({
    required this.month,
    required this.value,
    this.secondary,
  });
}

class AdminAnalytics {
  final List<TrendPoint> userGrowthCustomers;
  final List<TrendPoint> userGrowthProviders;
  final List<TrendPoint> bookingTrends;
  final List<TrendPoint> revenueTrends;
  final List<({String name, int bookings})> topCategories;

  const AdminAnalytics({
    required this.userGrowthCustomers,
    required this.userGrowthProviders,
    required this.bookingTrends,
    required this.revenueTrends,
    required this.topCategories,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    final userGrowth = json['user_growth'] as List? ?? [];
    final customers = <TrendPoint>[];
    final providers = <TrendPoint>[];
    for (final item in userGrowth) {
      final m = item as Map<String, dynamic>;
      final month = m['month'] as String? ?? '';
      customers.add(TrendPoint(
        month: month,
        value: (m['customers'] as num?)?.toDouble() ?? 0,
      ));
      providers.add(TrendPoint(
        month: month,
        value: (m['providers'] as num?)?.toDouble() ?? 0,
      ));
    }

    final bookingTrends = (json['booking_trends'] as List? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return TrendPoint(
            month: m['month'] as String? ?? '',
            value: (m['count'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();

    final revenueTrends = (json['revenue_trends'] as List? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return TrendPoint(
            month: m['month'] as String? ?? '',
            value: (m['amount'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();

    final topCategories = (json['top_categories'] as List? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return (
            name: m['name'] as String? ?? 'Other',
            bookings: m['bookings'] as int? ?? 0,
          );
        })
        .toList();

    return AdminAnalytics(
      userGrowthCustomers: customers,
      userGrowthProviders: providers,
      bookingTrends: bookingTrends,
      revenueTrends: revenueTrends,
      topCategories: topCategories,
    );
  }
}
