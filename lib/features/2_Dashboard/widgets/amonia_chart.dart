import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class AmmoniaChart extends StatelessWidget {
  final List<dynamic> sensorData;

  const AmmoniaChart({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    if (sensorData.isEmpty) {
      return _buildEmptyState("Belum ada data history.");
    }

    // Data points untuk 3 garis
    final List<FlSpot> gasSpots = [];
    final List<FlSpot> tempSpots = [];
    final List<FlSpot> humSpots = [];

    double maxY = 0;

    for (int i = 0; i < sensorData.length; i++) {
      final item = sensorData[i];

      double gas = double.tryParse(item['gas'].toString()) ?? 0;
      double temp = double.tryParse(item['temp'].toString()) ?? 0;
      double hum = double.tryParse(item['hum'].toString()) ?? 0;

      gasSpots.add(FlSpot(i.toDouble(), gas));
      tempSpots.add(FlSpot(i.toDouble(), temp));
      humSpots.add(FlSpot(i.toDouble(), hum));

      // Cari nilai tertinggi agar grafik tidak kepotong
      if (gas > maxY) maxY = gas;
      if (temp > maxY) maxY = temp;
      if (hum > maxY) maxY = hum;
    }

    // Tambah buffer atas sedikit
    maxY = maxY + 10;

    return Container(
      height: 320, // Agak tinggi biar muat legend
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Rata-rata 7 Hari Terakhir",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),

          // --- CHART ---
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < sensorData.length) {
                          try {
                            // Format tanggal: "25 Oct"
                            DateTime date = DateTime.parse(
                              sensorData[index]['date'],
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('d MMM').format(date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sensorData.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // GARIS 1: GAS (Merah)
                  LineChartBarData(
                    spots: gasSpots,
                    isCurved: true,
                    color: AppColors.statusDanger,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  // GARIS 2: SUHU (Kuning/Orange)
                  LineChartBarData(
                    spots: tempSpots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  // GARIS 3: LEMBAP (Biru)
                  LineChartBarData(
                    spots: humSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- LEGEND (Keterangan Warna) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.statusDanger, "Gas (PPM)"),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.orange, "Suhu (°C)"),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.blue, "Lembap (%)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
