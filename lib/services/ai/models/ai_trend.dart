/// Model class for AI-identified trends and patterns
class AITrend {
  final List<TrendingService> trendingServices;
  final List<DecliningService> decliningServices;
  final List<PeakHour> peakHours;
  final String insights;
  final bool cached;

  AITrend({
    required this.trendingServices,
    required this.decliningServices,
    required this.peakHours,
    required this.insights,
    required this.cached,
  });

  factory AITrend.fromJson(Map<String, dynamic> json) {
    return AITrend(
      trendingServices: (json['trending_services'] as List)
          .map((e) => TrendingService.fromJson(e as Map<String, dynamic>))
          .toList(),
      decliningServices: (json['declining_services'] as List)
          .map((e) => DecliningService.fromJson(e as Map<String, dynamic>))
          .toList(),
      peakHours: (json['peak_hours'] as List)
          .map((e) => PeakHour.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: json['insights'] as String,
      cached: json['cached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trending_services': trendingServices.map((e) => e.toJson()).toList(),
      'declining_services': decliningServices.map((e) => e.toJson()).toList(),
      'peak_hours': peakHours.map((e) => e.toJson()).toList(),
      'insights': insights,
      'cached': cached,
    };
  }
}

/// Trending service information
class TrendingService {
  final String serviceName;
  final String category;
  final double growthRate;
  final int currentBookings;
  final int previousBookings;

  TrendingService({
    required this.serviceName,
    required this.category,
    required this.growthRate,
    required this.currentBookings,
    required this.previousBookings,
  });

  factory TrendingService.fromJson(Map<String, dynamic> json) {
    return TrendingService(
      serviceName: json['service_name'] as String,
      category: json['category'] as String,
      growthRate: (json['growth_rate'] as num).toDouble(),
      currentBookings: json['current_bookings'] as int,
      previousBookings: json['previous_bookings'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'category': category,
      'growth_rate': growthRate,
      'current_bookings': currentBookings,
      'previous_bookings': previousBookings,
    };
  }
}

/// Declining service information
class DecliningService {
  final String serviceName;
  final String category;
  final double declineRate;
  final int currentBookings;
  final int previousBookings;

  DecliningService({
    required this.serviceName,
    required this.category,
    required this.declineRate,
    required this.currentBookings,
    required this.previousBookings,
  });

  factory DecliningService.fromJson(Map<String, dynamic> json) {
    return DecliningService(
      serviceName: json['service_name'] as String,
      category: json['category'] as String,
      declineRate: (json['decline_rate'] as num).toDouble(),
      currentBookings: json['current_bookings'] as int,
      previousBookings: json['previous_bookings'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'category': category,
      'decline_rate': declineRate,
      'current_bookings': currentBookings,
      'previous_bookings': previousBookings,
    };
  }
}

/// Peak hour information
class PeakHour {
  final int hour;
  final int bookingCount;

  PeakHour({
    required this.hour,
    required this.bookingCount,
  });

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: json['hour'] as int,
      bookingCount: json['booking_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'booking_count': bookingCount,
    };
  }
}
