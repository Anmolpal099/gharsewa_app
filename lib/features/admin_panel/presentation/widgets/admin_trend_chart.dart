import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/admin_analytics.dart';

class AdminTrendChart extends StatelessWidget {
  const AdminTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.secondaryPoints,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.green,
  });

  final String title;
  final List<TrendPoint> points;
  final List<TrendPoint>? secondaryPoints;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Card(
        child: SizedBox(
          height: 220,
          child: Center(child: Text('No data for $title')),
        ),
      );
    }

    final maxY = [
      ...points.map((p) => p.value),
      if (secondaryPoints != null) ...secondaryPoints!.map((p) => p.value),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: points.length <= 1
                      ? 0
                      : (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY <= 0 ? 10 : maxY * 1.2,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
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
                              points[i].month,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].value),
                      ],
                      isCurved: true,
                      color: primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    if (secondaryPoints != null && secondaryPoints!.isNotEmpty)
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < secondaryPoints!.length; i++)
                            FlSpot(
                              i.toDouble(),
                              secondaryPoints![i].value,
                            ),
                        ],
                        isCurved: true,
                        color: secondaryColor,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
