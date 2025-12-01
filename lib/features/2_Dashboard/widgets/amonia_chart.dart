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
  double _maxY = 20;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  void _processData() {
    final List<FlSpot> spots = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;

    const double padding = 3.0;

    if (widget.sensorData.isEmpty) {
      setState(() => _spots = []);
      return;
    }

    for (int i = 0; i < widget.sensorData.length; i++) {
      final item = widget.sensorData[i] as Map<String, dynamic>? ?? {};
      final rawValue = item['amonia'];

      if (rawValue != null) {
        final double value = (rawValue as num).toDouble();
        spots.add(FlSpot(i.toDouble(), value));
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }
    }

    if (minY == double.maxFinite) minY = 0;
    if (maxY == double.minPositive) maxY = 30;

    setState(() {
      _spots = spots;
      _minY = (minY - padding).clamp(0, double.maxFinite);
      _maxY = (maxY + padding);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_spots.length < 2) {
      return Card(
        color: AppColors.card,
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: const Text(
            'Data amonia tidak cukup untuk menampilkan grafik.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tren Amonia (PPM)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                _mainChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: (_maxY - _minY) / 3,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (_maxY - _minY) / 3,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.textSecondary.withOpacity(0.1),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.textSecondary.withOpacity(0.1),
          strokeWidth: 1,
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
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.statusDanger.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}