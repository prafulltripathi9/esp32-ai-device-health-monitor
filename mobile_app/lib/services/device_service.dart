import '../core/constants/api_constants.dart';
import '../models/device_model.dart';
import '../models/telemetry_model.dart';
import '../models/health_history_model.dart';
import 'api_service.dart';

class DeviceService {
  final ApiService _apiService = ApiService();

  // Fetch all registered devices
  Future<List<DeviceModel>> getDevices() async {
    final response = await _apiService.get(
      ApiConstants.devices,
    );

    final List<dynamic> deviceList = response['devices'] ?? [];

    return deviceList.map((device) {
      return DeviceModel.fromJson(
        device as Map<String, dynamic>,
      );
    }).toList();
  }

  // Fetch historical telemetry
  Future<List<TelemetryModel>> getDeviceHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    final response = await _apiService.get(
      '${ApiConstants.telemetryHistory(deviceId)}?limit=$limit',
    );

    final List<dynamic> historyList = response['history'] ?? [];

    return historyList.map((record) {
      return TelemetryModel.fromJson(
        record as Map<String, dynamic>,
      );
    }).toList();
  }

  // Fetch historical AI health analysis
  Future<List<HealthHistoryModel>> getDeviceHealthHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    final response = await _apiService.get(
      '${ApiConstants.healthHistory(deviceId)}?limit=$limit',
    );

    final List<dynamic> historyList = response['history'] ?? [];

    return historyList.map((record) {
      return HealthHistoryModel.fromJson(
        record as Map<String, dynamic>,
      );
    }).toList();
  }
}