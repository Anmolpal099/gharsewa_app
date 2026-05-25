import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/chart_config.dart';
import '../../data/models/earnings_data.dart';
import '../../data/models/enums.dart';
import '../../../../core/theme/app_theme.dart';

class EarningsChart extends StatelessWidget {
  final EarningsData data;
  final EarningsViewType viewType;
  final ValueChanged<EarningsViewType> onViewTypeChanged;
  final String Function(double) formatCurrency;
  final String Function(double) formatPercentage;

  const EarningsChart({
    super.key,
    required this.data,
    required this.viewType,
    required this.onViewTypeChanged,
    required this.formatCurrency,
    required this.formatPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final change = data.percentageChange;
    final changeColor =
        change >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed;
    final config = ChartConfig.earnings();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency(data.totalEarnings),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatPercentage(change),
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<EarningsViewType>(
                  segments: const [
                    ButtonSegment(
                      value: EarningsViewType.daily,
                      label: Text('Daily'),
                    ),
                    ButtonSegment(
                      value: EarningsViewType.weekly,
                      label: Text('Weekly'),
                    ),
                  ],
                  selected: {viewType},
                  onSelectionChanged: (s) => onViewTypeChanged(s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: data.dataPoints.isEmpty
                  ? const Center(child: Text('No earnings data available'))
                  : _ChartRenderer(
                      points: data.dataPoints,
                      config: config,
                      formatValue: formatCurrency,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartRenderer extends StatefulWidget {
  final List<EarningsDataPoint> points;
  final ChartConfig config;
  final String Function(double) formatValue;

  const _ChartRenderer({
    required this.points,
    required this.config,
    required this.formatValue,
  });

  @override
  State<_ChartRenderer> createState() => _ChartRendererState();
}

class _ChartRendererState extends State<_ChartRenderer> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final maxY = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final safeMax = maxY <= 0 ? 1.0 : maxY * 1.2;

    return Column(
      children: [
        if (_touchedIndex != null && _touchedIndex! < points.length)
          Text(
            '${points[_touchedIndex!].label}: ${widget.formatValue(points[_touchedIndex!].amount)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: safeMax,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: widget.config.enableTouch,
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.spot?.touchedBarGroupIndex;
                  });
                },
              ),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          points[i].label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(points.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: points[i].amount,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          widget.config.gradientStartColor,
                          widget.config.gradientEndColor,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
