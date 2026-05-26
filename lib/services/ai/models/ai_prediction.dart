/// Model class for AI-generated predictions
class AIPrediction {
  final BookingVolumePrediction? bookingVolume;
  final RevenueForecast? revenueForecast;
  final ChurnRisk? churnRisk;
  final TrendPrediction? trend;
  final bool cached;

  AIPrediction({
    this.bookingVolume,
    this.revenueForecast,
    this.churnRisk,
    this.trend,
    required this.cached,
  });

  factory AIPrediction.fromJson(Map<String, dynamic> json) {
    return AIPrediction(
      bookingVolume: json['booking_volume'] != null
          ? BookingVolumePrediction.fromJson(json['booking_volume'] as Map<String, dynamic>)
          : null,
      revenueForecast: json['revenue_forecast'] != null
          ? RevenueForecast.fromJson(json['revenue_forecast'] as Map<String, dynamic>)
          : null,
      churnRisk: json['churn_risk'] != null
          ? ChurnRisk.fromJson(json['churn_risk'] as Map<String, dynamic>)
          : null,
      trend: json['trend'] != null
          ? TrendPrediction.fromJson(json['trend'] as Map<String, dynamic>)
          : null,
      cached: json['cached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_volume': bookingVolume?.toJson(),
      'revenue_forecast': revenueForecast?.toJson(),
      'churn_risk': churnRisk?.toJson(),
      'trend': trend?.toJson(),
      'cached': cached,
    };
  }
}

/// Booking volume prediction
class BookingVolumePrediction {
  final List<PredictionPoint> predictions;
  final String insights;
  final double confidenceScore;
  final List<String> factors;

  BookingVolumePrediction({
    required this.predictions,
    required this.insights,
    required this.confidenceScore,
    required this.factors,
  });

  factory BookingVolumePrediction.fromJson(Map<String, dynamic> json) {
    return BookingVolumePrediction(
      predictions: (json['predictions'] as List)
          .map((e) => PredictionPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: json['insights'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      factors: (json['factors'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions.map((e) => e.toJson()).toList(),
      'insights': insights,
      'confidence_score': confidenceScore,
      'factors': factors,
    };
  }
}

/// Revenue forecast prediction
class RevenueForecast {
  final List<PredictionPoint> predictions;
  final String insights;
  final double confidenceScore;
  final List<String> factors;

  RevenueForecast({
    required this.predictions,
    required this.insights,
    required this.confidenceScore,
    required this.factors,
  });

  factory RevenueForecast.fromJson(Map<String, dynamic> json) {
    return RevenueForecast(
      predictions: (json['predictions'] as List)
          .map((e) => PredictionPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: json['insights'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      factors: (json['factors'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions.map((e) => e.toJson()).toList(),
      'insights': insights,
      'confidence_score': confidenceScore,
      'factors': factors,
    };
  }
}

/// Churn risk prediction
class ChurnRisk {
  final List<Map<String, dynamic>> predictions;
  final String insights;
  final double confidenceScore;
  final List<String> factors;

  ChurnRisk({
    required this.predictions,
    required this.insights,
    required this.confidenceScore,
    required this.factors,
  });

  factory ChurnRisk.fromJson(Map<String, dynamic> json) {
    return ChurnRisk(
      predictions: (json['predictions'] as List).cast<Map<String, dynamic>>(),
      insights: json['insights'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      factors: (json['factors'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions,
      'insights': insights,
      'confidence_score': confidenceScore,
      'factors': factors,
    };
  }
}

/// Trend prediction
class TrendPrediction {
  final List<Map<String, dynamic>> predictions;
  final String insights;
  final double confidenceScore;
  final List<String> factors;

  TrendPrediction({
    required this.predictions,
    required this.insights,
    required this.confidenceScore,
    required this.factors,
  });

  factory TrendPrediction.fromJson(Map<String, dynamic> json) {
    return TrendPrediction(
      predictions: (json['predictions'] as List).cast<Map<String, dynamic>>(),
      insights: json['insights'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      factors: (json['factors'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions,
      'insights': insights,
      'confidence_score': confidenceScore,
      'factors': factors,
    };
  }
}

/// Individual prediction point (date + value + confidence)
class PredictionPoint {
  final String date;
  final double value;
  final double confidence;

  PredictionPoint({
    required this.date,
    required this.value,
    required this.confidence,
  });

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      date: json['date'] as String,
      value: (json['value'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'value': value,
      'confidence': confidence,
    };
  }
}
