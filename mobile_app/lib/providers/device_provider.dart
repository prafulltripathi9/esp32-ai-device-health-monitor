import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../models/telemetry_model.dart';
import '../models/health_history_model.dart';
import '../services/device_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();

  // Current devices
  List<DeviceModel> devices = [];

  bool isLoading = false;
  String? errorMessage;

  // Telemetry history
  List<TelemetryModel> telemetryHistory = [];

  bool isHistoryLoading = false;
  String? historyErrorMessage;

  // AI health history for each device
  final Map<String, List<HealthHistoryModel>> healthHistory = {};

  final Map<String, bool> healthHistoryLoading = {};

  final Map<String, String?> healthHistoryErrors = {};

  // Fetch all devices
  Future<void> fetchDevices({bool showLoader = true}) async {
    if (showLoader) {
      isLoading = true;
      notifyListeners();
    }

    errorMessage = null;

    try {
      devices = await _deviceService.getDevices();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch telemetry history
  Future<void> fetchDeviceHistory(
    String deviceId, {
    int limit = 50,
    bool showLoader = true,
  }) async {
    if (showLoader) {
      isHistoryLoading = true;
      notifyListeners();
    }

    historyErrorMessage = null;

    try {
      telemetryHistory = await _deviceService.getDeviceHistory(
        deviceId,
        limit: limit,
      );
    } catch (error) {
      historyErrorMessage = error.toString();
    } finally {
      isHistoryLoading = false;
      notifyListeners();
    }
  }

  // Fetch AI health history for a device
  Future<void> fetchDeviceHealthHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    healthHistoryLoading[deviceId] = true;
    healthHistoryErrors[deviceId] = null;
    notifyListeners();

    try {
      healthHistory[deviceId] =
          await _deviceService.getDeviceHealthHistory(
        deviceId,
        limit: limit,
      );
    } catch (error) {
      healthHistoryErrors[deviceId] = error.toString();
    } finally {
      healthHistoryLoading[deviceId] = false;
      notifyListeners();
    }
  }

  // Fetch health history for all registered devices
  Future<void> fetchAllDeviceHealthHistory({
    int limit = 50,
  }) async {
    await Future.wait(
      devices.map(
        (device) => fetchDeviceHealthHistory(
          device.deviceId,
          limit: limit,
        ),
      ),
    );
  }
}