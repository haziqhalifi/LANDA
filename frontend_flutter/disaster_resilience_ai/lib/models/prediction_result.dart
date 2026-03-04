/// Simple data class representing a risk prediction response.
class PredictionResult {
  final double riskScore;
  final String model;
  final String modelVersion;

  PredictionResult({
    required this.riskScore,
    required this.model,
    required this.modelVersion,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      riskScore: (json['risk_score'] as num).toDouble(),
      model: json['model'] as String,
      modelVersion: json['model_version'] as String,
    );
  }
}
