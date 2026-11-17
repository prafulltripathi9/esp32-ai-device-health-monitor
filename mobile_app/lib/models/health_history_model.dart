import 'health_model.dart';
import 'telemetry_model.dart';

class HealthHistoryModel {
  final int telemetryId;
  final DateTime? createdAt;
  final HealthModel health;
  final TelemetryModel telemetry;

  const HealthHistoryModel({
    required this.telemetryId,
    required this.createdAt,
    required this.health,
    required this.telemetry,
  });

  factory HealthHistoryModel.fromJson(Map<String, dynamic> json) {
    return HealthHistoryModel(
      telemetryId: json['telemetry_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      health: HealthModel.fromJson(
        json['health'] as Map<String, dynamic>? ?? {},
      ),
      telemetry: TelemetryModel.fromJson(
        json['telemetry'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}