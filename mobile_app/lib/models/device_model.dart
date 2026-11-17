import 'health_model.dart';
import 'telemetry_model.dart';

class DeviceModel {
  final String deviceId;
  final HealthModel health;
  final TelemetryModel telemetry;

  const DeviceModel({
    required this.deviceId,
    required this.health,
    required this.telemetry,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['device_id'] ?? '',
      health: HealthModel.fromJson(
        json['health'] as Map<String, dynamic>? ?? {},
      ),
      telemetry: TelemetryModel.fromJson(
        json['telemetry'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}