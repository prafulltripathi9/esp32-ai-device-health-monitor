class TelemetryModel {
  final String deviceId;
  final int uptimeSeconds;
  final int freeHeap;
  final int minimumFreeHeap;
  final int largestFreeBlock;
  final String resetReason;
  final bool wifiConnected;
  final String ssid;
  final int rssi;
  final int reconnectCount;
  final DateTime? createdAt;

  const TelemetryModel({
    required this.deviceId,
    required this.uptimeSeconds,
    required this.freeHeap,
    required this.minimumFreeHeap,
    required this.largestFreeBlock,
    required this.resetReason,
    required this.wifiConnected,
    required this.ssid,
    required this.rssi,
    required this.reconnectCount,
    required this.createdAt,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    final wifi = json['wifi'] as Map<String, dynamic>? ?? {};

    return TelemetryModel(
      deviceId: json['device_id'] ?? '',
      uptimeSeconds: json['uptime_seconds'] ?? 0,
      freeHeap: json['free_heap'] ?? 0,
      minimumFreeHeap: json['minimum_free_heap'] ?? 0,
      largestFreeBlock: json['largest_free_block'] ?? 0,
      resetReason: json['reset_reason'] ?? 'Unknown',
      wifiConnected: wifi['connected'] ?? false,
      ssid: wifi['ssid'] ?? '',
      rssi: wifi['rssi'] ?? 0,
      reconnectCount: wifi['reconnect_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
