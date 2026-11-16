class HealthModel {
  final String healthStatus;
  final String mlStatus;
  final double? anomalyScore;
  final List<String> issues;

  const HealthModel({
    required this.healthStatus,
    required this.mlStatus,
    required this.anomalyScore,
    required this.issues,
  });

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    return HealthModel(
      healthStatus: json['health_status'] ?? 'Unknown',
      mlStatus: json['ml_status'] ?? 'Unknown',
      anomalyScore: (json['anomaly_score'] as num?)?.toDouble(),
      issues: List<String>.from(json['issues'] ?? []),
    );
  }
}