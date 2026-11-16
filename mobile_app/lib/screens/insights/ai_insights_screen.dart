import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/device_provider.dart';
import '../../models/device_model.dart';
import '../../models/health_history_model.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsights();
    });
  }

  Future<void> _loadInsights() async {
    final provider = context.read<DeviceProvider>();

    await provider.fetchDevices();

    if (!mounted) return;

    await provider.fetchAllDeviceHealthHistory(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            final devices = provider.devices;

            final healthy = devices
                .where((d) => d.health.healthStatus.toLowerCase() == 'healthy')
                .length;

            final warning = devices
                .where((d) => d.health.healthStatus.toLowerCase() == 'warning')
                .length;

            final critical = devices
                .where((d) => d.health.healthStatus.toLowerCase() == 'critical')
                .length;

            final unusual = devices
                .where(
                  (d) =>
                      d.health.healthStatus.toLowerCase() ==
                      'unusual behaviour',
                )
                .length;

            final anomalies = devices
                .where((d) => d.health.mlStatus.toLowerCase() == 'anomaly')
                .length;

            final total = devices.length;

            return RefreshIndicator(
              onRefresh: _loadInsights,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),

                    const SizedBox(height: 26),

                    _modelCard(),

                    const SizedBox(height: 28),

                    _sectionTitle('Health Overview'),

                    const SizedBox(height: 16),

                    if (provider.isLoading && devices.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (provider.errorMessage != null && devices.isEmpty)
                      _errorCard(provider.errorMessage!, _loadInsights)
                    else if (devices.isEmpty)
                      _emptyCard('No device data available yet.')
                    else ...[
                      _overviewGrid(total, healthy, warning, critical, unusual),
                      const SizedBox(height: 20),

                      _healthDistributionChart(
                        healthy,
                        warning,
                        critical,
                        unusual,
                      ),
                      const SizedBox(height: 28),

                      _sectionTitle('Anomaly Detection'),

                      const SizedBox(height: 16),

                      _anomalyCard(anomalies, total),

                      const SizedBox(height: 28),

                      _sectionTitle('Device-wise AI Analysis'),

                      const SizedBox(height: 16),

                      ...devices.map(
                        (device) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _deviceAnalysisCard(device),
                        ),
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle('AI Recommendations'),

                      const SizedBox(height: 16),

                      ..._buildRecommendations(devices),

                      const SizedBox(height: 28),

                      _sectionTitle('Historical Health Analysis'),

                      const SizedBox(height: 8),

                      const Text(
                        'Latest historical predictions from the ML and rule-based detector.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 16),

                      ...devices.map(
                        (device) => _historySection(provider, device),
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Health Insights',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Machine learning based device health intelligence',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _modelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Detection Engine',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Isolation Forest',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.settings_suggest_outlined,
                color: AppColors.primary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(color: AppColors.border),

          const SizedBox(height: 12),

          _infoRow('Algorithm', 'Isolation Forest'),

          _infoRow('Estimators', '100'),

          _infoRow('Contamination', '0.02'),

          _infoRow('Feature Scaling', 'StandardScaler'),

          _infoRow('Detection Method', 'Hybrid ML + Health Rules'),
          _infoRow('Model Verification', 'Not exposed by API'),
          const SizedBox(height: 12),

          const Text(
            'The system combines unsupervised anomaly detection '
            'with rule-based hardware and network health checks.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  Widget _overviewGrid(
    int total,
    int healthy,
    int warning,
    int critical,
    int unusual,
  ) {
    final items = [
      _OverviewItem('Total Devices', total, AppColors.primary, Icons.devices),
      _OverviewItem(
        'Healthy',
        healthy,
        AppColors.healthy,
        Icons.check_circle_outline,
      ),
      _OverviewItem('Warning', warning, AppColors.warning, Icons.warning_amber),
      _OverviewItem(
        'Critical',
        critical,
        AppColors.critical,
        Icons.error_outline,
      ),
      _OverviewItem(
        'Unusual',
        unusual,
        Colors.purpleAccent,
        Icons.psychology_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 850
            ? 5
            : constraints.maxWidth > 500
            ? 3
            : 2;

        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: item.color, size: 23),
                    const SizedBox(height: 14),
                    Text(
                      item.count.toString(),
                      style: TextStyle(
                        color: item.color,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _healthDistributionChart(
    int healthy,
    int warning,
    int critical,
    int unusual,
  ) {
    final total = healthy + warning + critical + unusual;

    if (total == 0) {
      return _emptyCard('No health classification data available.');
    }

    final sections = <PieChartSectionData>[];

    void addSection(int count, Color color) {
      if (count == 0) return;

      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: color,
          radius: 45,
          title: '$count',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    addSection(healthy, AppColors.healthy);
    addSection(warning, AppColors.warning);
    addSection(critical, AppColors.critical);
    addSection(unusual, Colors.purpleAccent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Distribution',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 48,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _legendItem('Healthy', AppColors.healthy, healthy),
          _legendItem('Warning', AppColors.warning, warning),
          _legendItem('Critical', AppColors.critical, critical),
          _legendItem('Unusual Behaviour', Colors.purpleAccent, unusual),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _anomalyCard(int anomalies, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_graph, color: Colors.purpleAccent, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ML Anomaly Predictions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$anomalies of $total latest device readings classified as anomalous.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            anomalies.toString(),
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceAnalysisCard(DeviceModel device) {
    final health = device.health;
    final telemetry = device.telemetry;

    final color = _healthColor(health.healthStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.deviceId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _statusBadge(health.healthStatus, color),
            ],
          ),

          const SizedBox(height: 18),

          _infoRow('ML Prediction', health.mlStatus),

          _infoRow(
            'Anomaly Score',
            health.anomalyScore?.toStringAsFixed(5) ?? 'Unavailable',
          ),

          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 10),
            child: Text(
              'Isolation Forest decision-function score; this is not '
              'a probability or percentage. Negative values indicate '
              'anomaly-side predictions, while positive values indicate '
              'normal-side predictions.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),

          _infoRow('Free Heap', '${telemetry.freeHeap} bytes'),

          _infoRow('Minimum Free Heap', '${telemetry.minimumFreeHeap} bytes'),

          _infoRow('Largest Free Block', '${telemetry.largestFreeBlock} bytes'),

          _infoRow('Wi-Fi RSSI', '${telemetry.rssi} dBm'),

          _infoRow('Wi-Fi Reconnects', telemetry.reconnectCount.toString()),

          _infoRow(
            'Wi-Fi Connection',
            telemetry.wifiConnected ? 'Connected' : 'Disconnected',
          ),

          const SizedBox(height: 12),

          const Divider(color: AppColors.border),

          const SizedBox(height: 10),

          const Text(
            'Detected Issues',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          if (health.issues.isEmpty)
            _issueTile(
              'No rule-based health issues detected.',
              AppColors.healthy,
            )
          else
            ...health.issues.map(
              (issue) => _issueTile(
                issue,
                issue.startsWith('Critical')
                    ? AppColors.critical
                    : AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _issueTile(String issue, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 10),
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
    );
  }

  List<Widget> _buildRecommendations(List<DeviceModel> devices) {
    final recommendations = <Widget>[];

    for (final device in devices) {
      final telemetry = device.telemetry;
      final health = device.health;

      final deviceRecommendations = <String>[];

      if (telemetry.freeHeap < 20000) {
        deviceRecommendations.add(
          'Critical: Very low free heap. Investigate memory usage '
          'and possible memory leaks.',
        );
      } else if (telemetry.freeHeap < 40000) {
        deviceRecommendations.add('Low free heap. Monitor memory consumption.');
      }

      if (telemetry.rssi < -85) {
        deviceRecommendations.add(
          'Very weak Wi-Fi signal. Improve router proximity '
          'or network coverage.',
        );
      } else if (telemetry.rssi < -70) {
        deviceRecommendations.add(
          'Weak Wi-Fi signal. Monitor network stability.',
        );
      }

      if (telemetry.reconnectCount >= 5) {
        deviceRecommendations.add(
          'Excessive Wi-Fi reconnections. Investigate network stability.',
        );
      }

      if (health.mlStatus.toLowerCase() == 'anomaly') {
        deviceRecommendations.add(
          'ML detected unusual behaviour. Review historical telemetry '
          'and investigate the underlying metrics.',
        );
      }

      if (deviceRecommendations.isNotEmpty) {
        recommendations.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceId,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...deviceRecommendations.map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (recommendations.isEmpty) {
      return [
        _recommendationCard(
          'No immediate recommendations',
          'Current readings do not trigger the configured '
              'health rules or ML anomaly detection.',
          AppColors.healthy,
        ),
      ];
    }

    return recommendations;
  }

  Widget _recommendationCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: color, size: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historySection(DeviceProvider provider, DeviceModel device) {
    final deviceId = device.deviceId;
    final history = provider.healthHistory[deviceId] ?? [];
    final isLoading = provider.healthHistoryLoading[deviceId] ?? false;
    final error = provider.healthHistoryErrors[deviceId];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deviceId,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (isLoading && history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null && history.isEmpty)
            _errorCard(error, () => provider.fetchDeviceHealthHistory(deviceId))
          else if (history.isEmpty)
            const Text(
              'No health history available.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          else ...[
            _buildTrendChart(
              history,
              'Free Heap Trend',
              (item) => item.telemetry.freeHeap.toDouble(),
              AppColors.primary,
            ),

            const SizedBox(height: 22),

            _buildTrendChart(
              history,
              'Wi-Fi RSSI Trend',
              (item) => item.telemetry.rssi.toDouble(),
              AppColors.warning,
            ),
            const SizedBox(height: 22),

            _buildTrendChart(
              history,
              'Largest Free Block Trend',
              (item) => item.telemetry.largestFreeBlock.toDouble(),
              AppColors.healthy,
            ),

            const SizedBox(height: 22),

            _buildTrendChart(
              history,
              'Wi-Fi Reconnection Trend',
              (item) => item.telemetry.reconnectCount.toDouble(),
              AppColors.warning,
            ),
            const SizedBox(height: 20),

            const Text(
              'Recent Health Timeline',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            ...history.take(10).map(_timelineItem),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(
    List<HealthHistoryModel> history,
    String title,
    double Function(HealthHistoryModel) getValue,
    Color color,
  ) {
    final points = history.reversed.toList();

    final spots = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      final value = getValue(points[i]);

      if (value.isFinite) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 170,
          child: LineChart(
            LineChartData(
              minX: spots.first.x,
              maxX: spots.last.x == spots.first.x
                  ? spots.first.x + 1
                  : spots.last.x,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.border, strokeWidth: 0.7),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${spots.length} historical readings',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _timelineItem(HealthHistoryModel item) {
    final status = item.health.healthStatus;
    final color = _healthColor(status);

    final time = item.createdAt != null
        ? item.createdAt!.toLocal().toString().substring(0, 16)
        : 'Unknown time';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ML: ${item.health.mlStatus}  •  '
                  'Score: ${item.health.anomalyScore?.toStringAsFixed(5) ?? 'N/A'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (item.health.issues.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.health.issues.join(', '),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _healthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return AppColors.healthy;
      case 'warning':
        return AppColors.warning;
      case 'critical':
        return AppColors.critical;
      case 'unusual behaviour':
        return Colors.purpleAccent;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _errorCard(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 30),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _OverviewItem {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _OverviewItem(this.title, this.count, this.color, this.icon);
}