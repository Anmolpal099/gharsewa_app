import 'enums.dart';

/// Single data point for earnings chart
class EarningsDataPoint {
  final DateTime date;
  final double amount;
  final String label; // e.g., "Mon", "Week 1"

  const EarningsDataPoint({
    required this.date,
    required this.amount,
    required this.label,
  });

  factory EarningsDataPoint.fromJson(Map<String, dynamic> json) {
    return EarningsDataPoint(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'label': label,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EarningsDataPoint &&
        other.date == date &&
        other.amount == amount &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(date, amount, label);
}

/// Date range for earnings queries
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  /// Calculate the number of days in this range
  int get daysDifference => endDate.difference(startDate).inDays;

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DateRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

/// Earnings data with trend analysis
class EarningsData {
  final double totalEarnings;
  final double previousPeriodEarnings;
  final List<EarningsDataPoint> dataPoints;
  final DateRange dateRange;
  final EarningsViewType viewType;

  const EarningsData({
    required this.totalEarnings,
    required this.previousPeriodEarnings,
    required this.dataPoints,
    required this.dateRange,
    required this.viewType,
  });

  /// Calculate percentage change from previous period
  double get percentageChange {
    if (previousPeriodEarnings == 0) return 0;
    return ((totalEarnings - previousPeriodEarnings) / previousPeriodEarnings) *
        100;
  }

  /// Check if earnings increased
  bool get isPositiveChange => percentageChange > 0;

  /// Check if earnings decreased
  bool get isNegativeChange => percentageChange < 0;

  /// Check if earnings stayed the same
  bool get isNoChange => percentageChange == 0;

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      previousPeriodEarnings:
          (json['previous_period_earnings'] as num).toDouble(),
      dataPoints: (json['data_points'] as List<dynamic>)
          .map((e) => EarningsDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      dateRange: DateRange.fromJson(json['date_range'] as Map<String, dynamic>),
      viewType: EarningsViewType.values.firstWhere(
        (e) => e.name == json['view_type'],
        orElse: () => EarningsViewType.daily,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'previous_period_earnings': previousPeriodEarnings,
      'data_points': dataPoints.map((d) => d.toJson()).toList(),
      'date_range': dateRange.toJson(),
      'view_type': viewType.name,
    };
  }

  EarningsData copyWith({
    double? totalEarnings,
    double? previousPeriodEarnings,
    List<EarningsDataPoint>? dataPoints,
    DateRange? dateRange,
    EarningsViewType? viewType,
  }) {
    return EarningsData(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      previousPeriodEarnings:
          previousPeriodEarnings ?? this.previousPeriodEarnings,
      dataPoints: dataPoints ?? this.dataPoints,
      dateRange: dateRange ?? this.dateRange,
      viewType: viewType ?? this.viewType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EarningsData &&
        other.totalEarnings == totalEarnings &&
        other.previousPeriodEarnings == previousPeriodEarnings &&
        _listEquals(other.dataPoints, dataPoints) &&
        other.dateRange == dateRange &&
        other.viewType == viewType;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalEarnings,
      previousPeriodEarnings,
      Object.hashAll(dataPoints),
      dateRange,
      viewType,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
