import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../providers/device_provider.dart';
import '../../widgets/charts/telemetry_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _refreshInterval = 5;
  Duration _selectedRange = const Duration(hours: 1);
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRefreshSettings();

      if (!mounted) return;

      await _loadDashboardData();

      _startRefreshTimer();
    });
  }

  Future<void> _loadRefreshSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _refreshInterval = prefs.getInt('refresh_interval') ?? 5;
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (
      timer,
    ) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices;
    final telemetryHistory = deviceProvider.telemetryHistory;
    final cutoffTime = DateTime.now().subtract(_selectedRange);

    final filteredTelemetryHistory = telemetryHistory.where((record) {
      return record.createdAt != null && record.createdAt!.isAfter(cutoffTime);
    }).toList();
    final totalDevices = devices.length;

    final onlineDevices = devices.where((device) {
      final telemetry = device.telemetry;
      final lastSeen = telemetry.createdAt;

      if (lastSeen == null || !telemetry.wifiConnected) {
        return false;
      }

      final secondsAgo = DateTime.now().difference(lastSeen).inSeconds;

      return secondsAgo >= 0 && secondsAgo <= 15;
    }).length;

    final offlineDevices = totalDevices - onlineDevices;

    final criticalDevices = devices
        .where((device) => device.health.healthStatus == 'Critical')
        .length;

    final healthyDevices = devices
        .where((device) => device.health.healthStatus == 'Healthy')
        .length;

    final warningDevices = devices
        .where((device) => device.health.healthStatus == 'Warning')
        .length;

    final unusualDevices = devices
        .where((device) => device.health.mlStatus.toLowerCase() == 'anomaly')
        .length;

    final telemetry = devices.isNotEmpty ? devices.first.telemetry : null;

    String formatUptime(int seconds) {
      final duration = Duration(seconds: seconds);

      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');

      return '$hours:$minutes:$remainingSeconds';
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              if (deviceProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),

              if (deviceProvider.errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.critical.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.critical.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.critical,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Backend connection error: ${deviceProvider.errorMessage}',
                          style: const TextStyle(
                            color: AppColors.critical,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              const Text(
                'Device Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  int columns = constraints.maxWidth > 1000
                      ? 4
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      SummaryCard(
                        title: 'Total Devices',
                        value: totalDevices.toString().padLeft(2, '0'),
                        icon: Icons.devices,
                        color: AppColors.primary,
                      ),
                      SummaryCard(
                        title: 'Online Devices',
                        value: onlineDevices.toString().padLeft(2, '0'),
                        icon: Icons.wifi,
                        color: AppColors.healthy,
                      ),
                      SummaryCard(
                        title: 'Offline Devices',
                        value: offlineDevices.toString().padLeft(2, '0'),
                        icon: Icons.wifi_off,
                        color: AppColors.warning,
                      ),
                      SummaryCard(
                        title: 'Critical Devices',
                        value: criticalDevices.toString().padLeft(2, '0'),
                        icon: Icons.warning_amber,
                        color: AppColors.critical,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              const Text(
                'Device Health',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HealthRow(
                      title: 'Healthy',
                      count: healthyDevices.toString().padLeft(2, '0'),
                      color: AppColors.healthy,
                    ),
                    const SizedBox(height: 18),

                    HealthRow(
                      title: 'Warning',
                      count: warningDevices.toString().padLeft(2, '0'),
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 18),

                    HealthRow(
                      title: 'Critical',
                      count: criticalDevices.toString().padLeft(2, '0'),
                      color: AppColors.critical,
                    ),
                    const SizedBox(height: 18),

                    HealthRow(
                      title: 'Unusual Behaviour',
                      count: unusualDevices.toString().padLeft(2, '0'),
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Live Telemetry',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  int columns = constraints.maxWidth > 1100
                      ? 3
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      TelemetryCard(
                        title: 'Free Heap',
                        value: telemetry == null
                            ? '--'
                            : '${(telemetry.freeHeap / 1024).toStringAsFixed(1)} KB',
                        subtitle: 'Currently available RAM',
                        icon: Icons.memory,
                      ),

                      TelemetryCard(
                        title: 'Minimum Free Heap',
                        value: telemetry == null
                            ? '--'
                            : '${(telemetry.minimumFreeHeap / 1024).toStringAsFixed(1)} KB',
                        subtitle: 'Lowest recorded free RAM',
                        icon: Icons.storage,
                      ),

                      TelemetryCard(
                        title: 'Largest Free Block',
                        value: telemetry == null
                            ? '--'
                            : '${(telemetry.largestFreeBlock / 1024).toStringAsFixed(1)} KB',
                        subtitle: 'Largest contiguous memory block',
                        icon: Icons.developer_board,
                      ),

                      TelemetryCard(
                        title: 'Wi-Fi RSSI',
                        value: telemetry == null
                            ? '--'
                            : '${telemetry.rssi} dBm',
                        subtitle: 'Wireless signal strength',
                        icon: Icons.network_wifi,
                      ),

                      TelemetryCard(
                        title: 'Uptime',
                        value: telemetry == null
                            ? '--'
                            : formatUptime(telemetry.uptimeSeconds),
                        subtitle: 'Device running time',
                        icon: Icons.timer_outlined,
                      ),

                      TelemetryCard(
                        title: 'Reconnect Count',
                        value: telemetry == null
                            ? '--'
                            : telemetry.reconnectCount.toString(),
                        subtitle: 'Wi-Fi reconnections',
                        icon: Icons.sync,
                      ),

                      TelemetryCard(
                        title: 'Reset Reason',
                        value: telemetry == null ? '--' : telemetry.resetReason,
                        subtitle: 'Last device reset reason',
                        icon: Icons.restart_alt,
                      ),

                      TelemetryCard(
                        title: 'Wi-Fi SSID',
                        value: telemetry == null || telemetry.ssid.isEmpty
                            ? '--'
                            : telemetry.ssid,
                        subtitle: 'Connected network',
                        icon: Icons.wifi,
                      ),

                      TelemetryCard(
                        title: 'Wi-Fi Status',
                        value: telemetry == null
                            ? '--'
                            : telemetry.wifiConnected
                            ? 'Connected'
                            : 'Disconnected',
                        subtitle: 'Network connection state',
                        icon: Icons.router,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              // DEVICE INFORMATION
              const Text(
                'Device Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 900 ? 2 : 1;

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.5,
                    children: [
                      TelemetryCard(
                        title: 'Device ID',
                        value: telemetry?.deviceId ?? '--',
                        subtitle: 'Unique device identifier',
                        icon: Icons.developer_board,
                      ),
                      TelemetryCard(
                        title: 'Reset Reason',
                        value: telemetry?.resetReason ?? '--',
                        subtitle: 'Last device reset reason',
                        icon: Icons.restart_alt,
                      ),
                      TelemetryCard(
                        title: 'Wi-Fi Network',
                        value: telemetry?.ssid.isNotEmpty == true
                            ? telemetry!.ssid
                            : '--',
                        subtitle: 'Connected network name',
                        icon: Icons.wifi,
                      ),
                      TelemetryCard(
                        title: 'Reconnect Count',
                        value: telemetry?.reconnectCount.toString() ?? '--',
                        subtitle: 'Total Wi-Fi reconnections',
                        icon: Icons.sync,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // LAST COMMUNICATION
              const Text(
                'Last Communication',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              Builder(
                builder: (context) {
                  final lastRecord = telemetry;

                  final lastTime = lastRecord?.createdAt;

                  final secondsAgo = lastTime == null
                      ? null
                      : DateTime.now().difference(lastTime).inSeconds;

                  final isOnline =
                      lastRecord != null &&
                      lastRecord.wifiConnected &&
                      secondsAgo != null &&
                      secondsAgo >= 0 &&
                      secondsAgo <= 15;

                  final lastSeen = secondsAgo == null
                      ? 'No data available'
                      : secondsAgo < 60
                      ? '$secondsAgo seconds ago'
                      : '${secondsAgo ~/ 60} minutes ago';

                  return TelemetryCard(
                    title: 'Device Communication',
                    value: lastRecord == null
                        ? 'Unknown'
                        : isOnline
                        ? 'Online'
                        : 'Offline',
                    subtitle: lastSeen,
                    icon: Icons.access_time,
                  );
                },
              ),

              const SizedBox(height: 30),
              const Text(
                'Telemetry Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 10,
                children: [
                  _buildTimeFilter('1H', const Duration(hours: 1)),
                  _buildTimeFilter('6H', const Duration(hours: 6)),
                  _buildTimeFilter('24H', const Duration(hours: 24)),
                  _buildTimeFilter('7D', const Duration(days: 7)),
                ],
              ),

              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  final charts = [
                    TelemetryChart(
                      title: 'Free Heap History',
                      subtitle: 'Available memory over time',
                      records: filteredTelemetryHistory,
                      getValue: (record) => record.freeHeap / 1024,
                      lineColor: AppColors.primary,
                      unit: 'KB',
                    ),
                    TelemetryChart(
                      title: 'Minimum Free Heap History',
                      subtitle: 'Minimum available memory over time',
                      records: filteredTelemetryHistory,
                      getValue: (record) => record.minimumFreeHeap / 1024,
                      lineColor: AppColors.warning,
                      unit: 'KB',
                    ),
                    TelemetryChart(
                      title: 'Largest Free Block History',
                      subtitle: 'Largest contiguous memory block',
                      records: filteredTelemetryHistory,
                      getValue: (record) => record.largestFreeBlock / 1024,
                      lineColor: AppColors.healthy,
                      unit: 'KB',
                    ),
                    TelemetryChart(
                      title: 'Wi-Fi RSSI History',
                      subtitle: 'Wireless signal strength over time',
                      records: filteredTelemetryHistory,
                      getValue: (record) => record.rssi.toDouble(),
                      lineColor: Colors.purpleAccent,
                      unit: 'dBm',
                    ),
                  ];

                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: charts[0]),
                            const SizedBox(width: 16),
                            Expanded(child: charts[1]),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: charts[2]),
                            const SizedBox(width: 16),
                            Expanded(child: charts[3]),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < charts.length; i++) ...[
                        charts[i],
                        if (i != charts.length - 1) const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    if (_isRefreshing || !mounted) return;

    _isRefreshing = true;

    try {
      final provider = context.read<DeviceProvider>();

      // Fetch latest device information.
      await provider.fetchDevices(showLoader: false);
      if (!mounted) return;

      // Fetch historical telemetry.
      if (provider.devices.isNotEmpty) {
        final deviceId = provider.devices.first.deviceId;

        await provider.fetchDeviceHistory(
          deviceId,
          limit: 500,
          showLoader: false,
        );
      }
    } catch (error) {
      debugPrint('Dashboard refresh error: $error');
    } finally {
      _isRefreshing = false;
    }
  }

  Widget _buildTimeFilter(String label, Duration duration) {
    final isSelected = _selectedRange == duration;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRange = duration;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final provider = context.watch<DeviceProvider>();

    String status = 'Unknown';
    Color statusColor = AppColors.textSecondary;

    if (provider.devices.isNotEmpty) {
      final telemetry = provider.devices.first.telemetry;
      final lastSeen = telemetry.createdAt;

      if (lastSeen != null) {
        final secondsAgo = DateTime.now().difference(lastSeen).inSeconds;

        if (telemetry.wifiConnected && secondsAgo >= 0 && secondsAgo <= 15) {
          status = 'Connected';
          statusColor = AppColors.healthy;
        } else {
          status = 'Disconnected';
          statusColor = AppColors.critical;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESP32 AI Monitor',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Monitor your device health and performance',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        );

        final statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: statusColor, size: 10),
              const SizedBox(width: 8),
              Text(
                status,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), statusBadge],
          );
        }

        return Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(flex: 3, child: title),
            statusBadge,
          ],
        );
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 23),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthRow extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const HealthRow({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 11),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class TelemetryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const TelemetryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
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
