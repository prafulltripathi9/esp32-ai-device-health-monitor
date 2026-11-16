import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  int refreshInterval = 5;

  bool isSaving = false;
  bool isTesting = false;
  bool isLoading = true;

  String connectionStatus = 'Not tested';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUrl = prefs.getString('backend_url');
    final savedInterval = prefs.getInt('refresh_interval') ?? 5;

    if (!mounted) return;

    setState(() {
      _urlController.text = savedUrl ?? ApiConstants.baseUrl;
      ApiConstants.baseUrl = savedUrl ?? ApiConstants.baseUrl;
      refreshInterval = savedInterval;
      isLoading = false;
    });
  }

  // Save backend URL
  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      _showMessage('Please enter a valid HTTP or HTTPS URL.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('backend_url', url);

      ApiConstants.baseUrl = url.replaceFirst(RegExp(r'/+$'), '');

      if (!mounted) return;



      _showMessage('Backend URL saved successfully.');
    } catch (error) {
      _showMessage('Failed to save URL: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Test backend connection
  Future<void> _testConnection() async {
    final url = _urlController.text.trim();

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      _showMessage('Please enter a valid backend URL.');
      return;
    }

    setState(() {
      isTesting = true;
      connectionStatus = 'Testing...';
    });

    try {
      final response = await http
          .get(Uri.parse('${url.replaceFirst(RegExp(r'/+$'), '')}/health'))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          connectionStatus = 'Connected';
        });

        _showMessage('Backend connection successful!');
      } else {
        setState(() {
          connectionStatus = 'Failed';
        });

        _showMessage('Backend returned status ${response.statusCode}');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        connectionStatus = 'Disconnected';
      });

      _showMessage('Cannot connect to backend.');
    } finally {
      if (mounted) {
        setState(() {
          isTesting = false;
        });
      }
    }
  }

  // Save refresh interval
  Future<void> _saveRefreshInterval(int value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('refresh_interval', value);

    if (!mounted) return;

    setState(() {
      refreshInterval = value;
    });

    _showMessage('Refresh interval saved: $value seconds');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Configure your application preferences',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Backend Configuration'),

              _settingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Server URL',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter backend URL',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveUrl,
                        child: isSaving
                            ? const CircularProgressIndicator()
                            : const Text('Save URL'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isTesting ? null : _testConnection,
                        icon: isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.wifi),
                        label: const Text('Test Connection'),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Text(
                          'Connection Status: ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          connectionStatus,
                          style: TextStyle(
                            color: connectionStatus == 'Connected'
                                ? AppColors.healthy
                                : connectionStatus == 'Disconnected' ||
                                        connectionStatus == 'Failed'
                                    ? AppColors.critical
                                    : AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Monitoring Preferences'),

              _settingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Refresh Interval',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Choose how frequently device data should refresh.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: refreshInterval,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [5, 10, 15, 30, 60]
                          .map(
                            (seconds) => DropdownMenuItem(
                              value: seconds,
                              child: Text('$seconds seconds'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _saveRefreshInterval(value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Application Information'),

              _settingsCard(
                child: const Column(
                  children: [
                    _InfoRow(
                      title: 'Application',
                      value: 'ESP32 AI Device Health Monitor',
                    ),
                    _InfoRow(title: 'Version', value: '1.0.0'),
                    _InfoRow(title: 'Framework', value: 'Flutter'),
                    _InfoRow(title: 'Backend', value: 'FastAPI'),
                    _InfoRow(
                      title: 'Machine Learning',
                      value: 'Isolation Forest',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}