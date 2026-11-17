import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../widgets/charts/telemetry_chart.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailsScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<DeviceProvider>().fetchDeviceHistory(
            widget.device.deviceId,
            limit: 500,
          );
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<DeviceProvider>();

    await provider.fetchDevices(showLoader: false);

    if (!mounted) return;

    await provider.fetchDeviceHistory(
      widget.device.deviceId,
      limit: 500,
      showLoader: false,
    );
  }

  bool _isOnline(DeviceModel device) {
    final telemetry = device.telemetry;
    final lastSeen = telemetry.createdAt;

    if (!telemetry.wifiConnected || lastSeen == null) {
      return false;
    }

    final secondsAgo = DateTime.now().difference(lastSeen).inSeconds;

    return secondsAgo >= 0 && secondsAgo <= 15;
  }

  String _formatUptime(int seconds) {
    final duration = Duration(seconds: seconds);

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final remainingSeconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }

    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        final currentDevice = provider.devices.firstWhere(
          (item) => item.deviceId == widget.device.deviceId,
          orElse: () => widget.device,
        );

        final telemetry = currentDevice.telemetry;
        final health = currentDevice.health;
        final isOnline = _isOnline(currentDevice);
        final history = provider.telemetryHistory;

        final statusColor = isOnline
            ? AppColors.healthy
            : AppColors.critical;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Device Details',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildDeviceHeader(
                      currentDevice.deviceId,
                      isOnline,
                      statusColor,
                    ),

                    const SizedBox(height: 28),

                    _sectionTitle('Health Overview'),

                    const SizedBox(height: 14),

                    _buildHealthOverview(
                      health.healthStatus,
                      health.mlStatus,
                      health.anomalyScore,
                      health.issues,
                    ),

                    const SizedBox(height: 28),

                    _sectionTitle('Hardware Telemetry'),

                    const SizedBox(height: 14),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 800
                            ? 3
                            : constraints.maxWidth > 450
                                ? 2
                                : 1;

                        final items = [
                          _MetricData(
                            'Free Heap',
                            '${(telemetry.freeHeap / 1024).toStringAsFixed(1)} KB',
                            Icons.memory,
                          ),
                          _MetricData(
                            'Minimum Free Heap',
                            '${(telemetry.minimumFreeHeap / 1024).toStringAsFixed(1)} KB',
                            Icons.storage,
                          ),
                          _MetricData(
                            'Largest Free Block',
                            '${(telemetry.largestFreeBlock / 1024).toStringAsFixed(1)} KB',
                            Icons.developer_board,
                          ),
                          _MetricData(
                            'Device Uptime',
                            _formatUptime(telemetry.uptimeSeconds),
                            Icons.timer_outlined,
                          ),
                          _MetricData(
                            'Reset Reason',
                            telemetry.resetReason,
                            Icons.restart_alt,
                          ),
                          _MetricData(
                            'Reconnect Count',
                            telemetry.reconnectCount.toString(),
                            Icons.sync,
                          ),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 115,
                          ),
                          itemBuilder: (context, index) {
                            return _MetricCard(data: items[index]);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    _sectionTitle('Network Information'),

                    const SizedBox(height: 14),

                    _buildNetworkCard(
                      connected: telemetry.wifiConnected,
                      ssid: telemetry.ssid,
                      rssi: telemetry.rssi,
                      reconnectCount: telemetry.reconnectCount,
                    ),

                    const SizedBox(height: 28),

                    _sectionTitle('Telemetry History'),

                    const SizedBox(height: 8),

                    const Text(
                      'Historical hardware and network readings',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (provider.isHistoryLoading && history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (provider.historyErrorMessage != null &&
                        history.isEmpty)
                      _buildHistoryError(provider.historyErrorMessage!)
                    else if (history.isEmpty)
                      _buildNoHistory()
                    else
                      ...[
                        TelemetryChart(
                          title: 'Free Heap History',
                          subtitle: 'Available memory over time',
                          records: history,
                          getValue: (record) => record.freeHeap / 1024,
                          lineColor: AppColors.primary,
                          unit: 'KB',
                        ),
                        const SizedBox(height: 16),
                        TelemetryChart(
                          title: 'Minimum Free Heap History',
                          subtitle: 'Minimum available memory',
                          records: history,
                          getValue: (record) =>
                              record.minimumFreeHeap / 1024,
                          lineColor: AppColors.warning,
                          unit: 'KB',
                        ),
                        const SizedBox(height: 16),
                        TelemetryChart(
                          title: 'Largest Free Block History',
                          subtitle: 'Contiguous memory block',
                          records: history,
                          getValue: (record) =>
                              record.largestFreeBlock / 1024,
                          lineColor: AppColors.healthy,
                          unit: 'KB',
                        ),
                        const SizedBox(height: 16),
                        TelemetryChart(
                          title: 'Wi-Fi RSSI History',
                          subtitle: 'Wireless signal strength',
                          records: history,
                          getValue: (record) => record.rssi.toDouble(),
                          lineColor: Colors.purpleAccent,
                          unit: 'dBm',
                        ),
                      ],

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceHeader(
    String deviceId,
    bool isOnline,
    Color statusColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.memory,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'ESP32 Device',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthOverview(
    String healthStatus,
    String mlStatus,
    double? anomalyScore,
    List<String> issues,
  ) {
    final healthColor = switch (healthStatus.toLowerCase()) {
      'healthy' => AppColors.healthy,
      'warning' => AppColors.warning,
      'critical' => AppColors.critical,
      _ => AppColors.textSecondary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Health Status', healthStatus, healthColor),
          const SizedBox(height: 16),
          _detailRow('ML Analysis', mlStatus),
          const SizedBox(height: 16),
          _detailRow(
            'Anomaly Score',
            anomalyScore?.toStringAsFixed(4) ?? 'Not available',
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          const Text(
            'Detected Issues',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (issues.isEmpty)
            const Text(
              'No issues detected.',
              style: TextStyle(
                color: AppColors.healthy,
                fontSize: 12,
              ),
            )
          else
            ...issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard({
    required bool connected,
    required String ssid,
    required int rssi,
    required int reconnectCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _detailRow('Connection', connected ? 'Connected' : 'Disconnected'),
          const SizedBox(height: 16),
          _detailRow('Wi-Fi Network', ssid.isEmpty ? '--' : ssid),
          const SizedBox(height: 16),
          _detailRow('Signal Strength', connected ? '$rssi dBm' : '--'),
          const SizedBox(height: 16),
          _detailRow('Reconnect Count', reconnectCount.toString()),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value, [Color? valueColor]) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHistoryError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Unable to load telemetry history: $message',
        style: const TextStyle(
          color: AppColors.critical,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNoHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.show_chart,
            color: AppColors.textSecondary,
            size: 35,
          ),
          SizedBox(height: 12),
          Text(
            'No telemetry history available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;

  const _MetricData(this.title, this.value, this.icon);
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}