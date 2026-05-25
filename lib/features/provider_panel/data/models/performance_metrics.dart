/// Performance metrics for a service provider
library;

class PerformanceMetrics {
  final double rating; // 0.0 to 5.0
  final int totalReviews;
  final int jobsCompleted;
  final Duration averageResponseTime;
  final bool isTopPerformer; // top 10%
  final double percentile;

  const PerformanceMetrics({
    required this.rating,
    required this.totalReviews,
    required this.jobsCompleted,
    required this.averageResponseTime,
    required this.isTopPerformer,
    required this.percentile,
  });

  /// Format rating with one decimal place
  String get formattedRating => rating.toStringAsFixed(1);

  /// Get star count (rounded to nearest 0.5)
  double get starCount {
    return (rating * 2).round() / 2;
  }

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      rating: (json['rating'] as num).toDouble(),
      totalReviews: json['total_reviews'] as int,
      jobsCompleted: json['jobs_completed'] as int,
      averageResponseTime:
          Duration(minutes: json['average_response_time_minutes'] as int),
      isTopPerformer: json['is_top_performer'] as bool? ?? false,
      percentile: (json['percentile'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'total_reviews': totalReviews,
      'jobs_completed': jobsCompleted,
      'average_response_time_minutes': averageResponseTime.inMinutes,
      'is_top_performer': isTopPerformer,
      'percentile': percentile,
    };
  }

  PerformanceMetrics copyWith({
    double? rating,
    int? totalReviews,
    int? jobsCompleted,
    Duration? averageResponseTime,
    bool? isTopPerformer,
    double? percentile,
  }) {
    return PerformanceMetrics(
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      isTopPerformer: isTopPerformer ?? this.isTopPerformer,
      percentile: percentile ?? this.percentile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PerformanceMetrics &&
        other.rating == rating &&
        other.totalReviews == totalReviews &&
        other.jobsCompleted == jobsCompleted &&
        other.averageResponseTime == averageResponseTime &&
        other.isTopPerformer == isTopPerformer &&
        other.percentile == percentile;
  }

  @override
  int get hashCode {
    return Object.hash(
      rating,
      totalReviews,
      jobsCompleted,
      averageResponseTime,
      isTopPerformer,
      percentile,
    );
  }
}
