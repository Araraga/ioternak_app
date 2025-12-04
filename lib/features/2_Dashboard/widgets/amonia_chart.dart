import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class AmmoniaChart extends StatefulWidget {
  final List<dynamic> sensorData;

  const AmmoniaChart({super.key, required this.sensorData});

  @override
  State<AmmoniaChart> createState() => _AmmoniaChartState();
}

class _AmmoniaChartState extends State<AmmoniaChart> {
  List<FlSpot> _spots = [];
  double _minY = 0;
  double _maxY = 10;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(covariant AmmoniaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sensorData != oldWidget.sensorData) {
      _processData();
    }
  }

  void _processData() {
    if (!mounted) return;

    if (widget.sensorData.isEmpty) {
      setState(() => _spots = []);
      return;
    }

    final List<FlSpot> tempSpots = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;

    final List<dynamic> sortedData = List.from(widget.sensorData.reversed);

    for (int i = 0; i < sortedData.length; i++) {
      final item = sortedData[i] as Map<String, dynamic>? ?? {};
      final dynamic rawValue = item['amonia'] ?? item['gas_ppm'];

      double? value;
      if (rawValue != null) {
        value = double.tryParse(rawValue.toString());
      }

      if (value != null && !value.isNaN && !value.isInfinite) {
        tempSpots.add(FlSpot(i.toDouble(), value));
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }
    }

    if (tempSpots.isEmpty) {
      if (mounted) setState(() => _spots = []);
      return;
    }

    if (minY == double.maxFinite) minY = 0;
    if (maxY == double.minPositive) maxY = 10;

    if (minY >= maxY) {
      maxY = minY + 10;
      minY = (minY - 10).clamp(0, double.maxFinite);
    } else {
      double diff = maxY - minY;
      if (diff < 1) diff = 1;

      maxY += (diff * 0.2);
      minY = (minY - (diff * 0.2)).clamp(0, double.maxFinite);
    }

    maxY = (maxY / 5).ceil() * 5.0;
    if (maxY == 0) maxY = 5;

    if (mounted) {
      setState(() {
        _spots = tempSpots;
        _minY = minY;
        _maxY = maxY;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_spots.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Text(
          'Data belum cukup untuk menampilkan tren.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    double range = _maxY - _minY;
    if (range <= 0) range = 1; // Cegah 0
    double interval = range / 4;
    if (interval <= 0) interval = 1;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),

          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if ((value - value.round()).abs() > 0.1)
                    return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
          ),

          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_spots.length - 1).toDouble(),
          minY: _minY,
          maxY: _maxY,

          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: AppColors.statusDanger,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.statusDanger.withOpacity(0.2),
                    AppColors.statusDanger.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
