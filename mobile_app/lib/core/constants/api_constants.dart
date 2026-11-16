class ApiConstants {
  ApiConstants._();

  // Default backend URL
  static String baseUrl = 'http://127.0.0.1:8000';

  static const String health = '/health';

  static const String devices = '/api/v1/devices';

  static String deviceDetails(String deviceId) {
    return '$devices/$deviceId';
  }

  static String deviceHealth(String deviceId) {
    return '$devices/$deviceId/health';
  }

  static String telemetryHistory(String deviceId) {
    return '$devices/$deviceId/history';
  }

  static String healthHistory(String deviceId) {
    return '$devices/$deviceId/health/history';
  }
}