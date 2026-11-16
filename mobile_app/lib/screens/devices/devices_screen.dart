import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import 'device_details_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';
  String _healthFilter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DeviceProvider>().fetchDevices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatLastSeen(DateTime? dateTime) {
    if (dateTime == null) return 'No data available';

    final seconds = DateTime.now().difference(dateTime).inSeconds;

    if (seconds < 0) return 'Just now';
    if (seconds < 60) return '$seconds sec ago';

    final minutes = seconds ~/ 60;

    if (minutes < 60) return '$minutes min ago';

    final hours = minutes ~/ 60;

    if (hours < 24) return '$hours hr ago';

    return '${hours ~/ 24} days ago';
  }

  List<DeviceModel> _filterDevices(List<DeviceModel> devices) {
    return devices.where((device) {
      final matchesSearch = device.deviceId
          .toLowerCase()
          .contains(_searchController.text.trim().toLowerCase());

      final online = _isOnline(device);

      final matchesStatus = switch (_statusFilter) {
        'Online' => online,
        'Offline' => !online,
        _ => true,
      };

      final health = device.health.healthStatus.toLowerCase();

      final matchesHealth = switch (_healthFilter) {
        'Healthy' => health == 'healthy',
        'Warning' => health == 'warning',
        'Critical' => health == 'critical',
        _ => true,
      };

      return matchesSearch && matchesStatus && matchesHealth;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            final devices = provider.devices;
            final filteredDevices = _filterDevices(devices);

            final onlineCount = devices.where(_isOnline).length;
            final offlineCount = devices.length - onlineCount;

            return RefreshIndicator(
              onRefresh: () => provider.fetchDevices(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildOverview(
                      total: devices.length,
                      online: onlineCount,
                      offline: offlineCount,
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Registered Devices',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildSearchField(),

                    const SizedBox(height: 16),

                    _buildFilters(),

                    const SizedBox(height: 20),

                    if (provider.isLoading && devices.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (provider.errorMessage != null &&
                        devices.isEmpty)
                      _buildError(provider)
                    else if (devices.isEmpty)
                      _buildEmptyState(
                        Icons.devices_other,
                        'No devices registered',
                        'Your ESP32 devices will appear here.',
                      )
                    else if (filteredDevices.isEmpty)
                      _buildEmptyState(
                        Icons.search_off,
                        'No matching devices',
                        'Try changing your search or filters.',
                      )
                    else ...[
                      Row(
                        children: [
                          Text(
                            '${filteredDevices.length} device(s) found',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (provider.isLoading)
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          final columns = isWide ? 2 : 1;

                          if (columns == 1) {
                            return Column(
                              children: filteredDevices.map((device) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DeviceCard(
                                    device: device,
                                    isOnline: _isOnline(device),
                                    lastSeen: _formatLastSeen(
                                      device.telemetry.createdAt,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 205,
                            ),
                            itemCount: filteredDevices.length,
                            itemBuilder: (context, index) {
                              final device = filteredDevices[index];

                              return DeviceCard(
                                device: device,
                                isOnline: _isOnline(device),
                                lastSeen: _formatLastSeen(
                                  device.telemetry.createdAt,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    if (provider.errorMessage != null &&
                        devices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(provider.errorMessage!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Devices',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Monitor and manage your ESP32 devices',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        );

        final refreshButton = OutlinedButton.icon(
          onPressed: () => context.read<DeviceProvider>().fetchDevices(),
          icon: const Icon(Icons.refresh, size: 17),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
        );

        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              refreshButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            refreshButton,
          ],
        );
      },
    );
  }

  Widget _buildOverview({
    required int total,
    required int online,
    required int offline,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700
            ? 3
            : constraints.maxWidth > 400
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: [
            _OverviewCard(
              title: 'Total Devices',
              value: total,
              icon: Icons.memory,
              color: AppColors.primary,
            ),
            _OverviewCard(
              title: 'Online Devices',
              value: online,
              icon: Icons.wifi,
              color: AppColors.healthy,
            ),
            _OverviewCard(
              title: 'Offline Devices',
              value: offline,
              icon: Icons.wifi_off,
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search by device ID...',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connection Status',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _filterChip('All', _statusFilter, (value) {
              setState(() => _statusFilter = value);
            }),
            _filterChip('Online', _statusFilter, (value) {
              setState(() => _statusFilter = value);
            }),
            _filterChip('Offline', _statusFilter, (value) {
              setState(() => _statusFilter = value);
            }),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Health Status',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _filterChip('All', _healthFilter, (value) {
              setState(() => _healthFilter = value);
            }),
            _filterChip('Healthy', _healthFilter, (value) {
              setState(() => _healthFilter = value);
            }),
            _filterChip('Warning', _healthFilter, (value) {
              setState(() => _healthFilter = value);
            }),
            _filterChip('Critical', _healthFilter, (value) {
              setState(() => _healthFilter = value);
            }),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(
    String label,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = label == selected;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.background : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 42),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(DeviceProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.critical,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchDevices(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.critical.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.critical),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Refresh failed: $message',
              style: const TextStyle(
                color: AppColors.critical,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final bool isOnline;
  final String lastSeen;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isOnline,
    required this.lastSeen,
  });

  Color _healthColor(String health) {
    switch (health.toLowerCase()) {
      case 'healthy':
        return AppColors.healthy;
      case 'warning':
        return AppColors.warning;
      case 'critical':
        return AppColors.critical;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = device.telemetry;
    final statusColor = isOnline ? AppColors.healthy : AppColors.critical;
    final healthColor = _healthColor(device.health.healthStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeviceDetailsScreen(device: device),
          ),
        );
      },
      child: Container(
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
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.memory,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        telemetry.ssid.isEmpty
                            ? 'ESP32 device'
                            : telemetry.ssid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: isOnline ? 'Online' : 'Offline',
                  color: statusColor,
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(color: AppColors.border),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _DeviceInfo(
                    title: 'Health',
                    value: device.health.healthStatus,
                    color: healthColor,
                  ),
                ),
                Expanded(
                  child: _DeviceInfo(
                    title: 'Wi-Fi Signal',
                    value: telemetry.wifiConnected
                        ? '${telemetry.rssi} dBm'
                        : '--',
                  ),
                ),
                Expanded(
                  child: _DeviceInfo(
                    title: 'Last Seen',
                    value: lastSeen,
                  ),
                ),
              ],
            ),

            const Spacer(),

            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 7),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfo extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _DeviceInfo({
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}