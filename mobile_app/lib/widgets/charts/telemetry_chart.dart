import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/telemetry_model.dart';

class TelemetryChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<TelemetryModel> records;
  final Color lineColor;
  final String unit;
  final double Function(TelemetryModel) getValue;

  const TelemetryChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.records,
    required this.lineColor,
    required this.unit,
    required this.getValue,
  });

  @override
  Widget build(BuildContext context) {
    final sortedRecords = records.where((record) {
      if (record.createdAt == null) return false;
      return getValue(record).isFinite;
    }).toList()
      ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));

    final spots = sortedRecords.map((record) {
      return FlSpot(
        record.createdAt!.millisecondsSinceEpoch / 1000,
        getValue(record),
      );
    }).toList();

    final hasData = spots.isNotEmpty;
    final hasSinglePoint = spots.length == 1;

    final minX = hasData
        ? (hasSinglePoint ? spots.first.x - 30 : spots.first.x)
        : 0.0;

    final maxX = hasData
        ? (hasSinglePoint ? spots.first.x + 30 : spots.last.x)
        : 1.0;

    double minY = 0;
    double maxY = 1;
    double yInterval = 1;

    if (hasData) {
      final values = spots.map((spot) => spot.y).toList();

      final lowest = values.reduce((a, b) => a < b ? a : b);
      final highest = values.reduce((a, b) => a > b ? a : b);

      final difference = highest - lowest;
      final padding = difference == 0
          ? (lowest.abs() * 0.1).clamp(1.0, double.infinity)
          : difference * 0.15;

      minY = lowest - padding;
      maxY = highest + padding;
      yInterval = ((maxY - minY) / 4).clamp(0.1, double.infinity);
    }

    final timeDifference = maxX - minX;

    final useDateLabels = timeDifference >= const Duration(hours: 24).inSeconds;

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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 210,
            child: !hasData
                ? const Center(
                    child: Text(
                      'No telemetry history available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: timeDifference / 4,
                            getTitlesWidget: (value, meta) {
                              final date =
                                  DateTime.fromMillisecondsSinceEpoch(
                                (value * 1000).round(),
                              );

                              final label = useDateLabels
                                  ? DateFormat('dd MMM').format(date)
                                  : DateFormat('HH:mm').format(date);

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: spots.length > 2,
                          curveSmoothness: 0.2,
                          color: lineColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: hasSinglePoint,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: lineColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Unit: $unit',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${spots.length} readings',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
