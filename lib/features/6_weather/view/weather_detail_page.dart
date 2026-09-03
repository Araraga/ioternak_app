import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../cubit/weather_cubit.dart';
import '../cubit/weather_state.dart';

class WeatherDetailPage extends StatelessWidget {
  const WeatherDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WeatherCubit(
        apiService: context.read<ApiService>(),
        storage: context.read<StorageService>(),
      )..fetchWeather(),
      child: const _WeatherDetailView(),
    );
  }
}

class _WeatherDetailView extends StatefulWidget {
  const _WeatherDetailView();

  @override
  State<_WeatherDetailView> createState() => _WeatherDetailViewState();
}

class _WeatherDetailViewState extends State<_WeatherDetailView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────── HELPERS ────────────────────────

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if ([1, 2, 3].contains(code)) return '⛅';
    if ([45, 48].contains(code)) return '🌫️';
    if ([51, 53, 55].contains(code)) return '🌦️';
    if ([61, 63, 65, 80, 81, 82].contains(code)) return '🌧️';
    if ([95, 96, 99].contains(code)) return '⛈️';
    return '☁️';
  }

  String _weatherDesc(int code) {
    if (code == 0) return 'Cerah Sempurna';
    if ([1, 2, 3].contains(code)) return 'Cerah Berawan';
    if ([45, 48].contains(code)) return 'Kabut';
    if ([51, 53, 55].contains(code)) return 'Hujan Gerimis';
    if ([61, 63, 65].contains(code)) return 'Hujan';
    if ([80, 81, 82].contains(code)) return 'Hujan Lebat';
    if ([95, 96, 99].contains(code)) return 'Petir & Badai';
    return 'Berawan';
  }

  Color _tempToColor(double t) {
    if (t >= 36) return const Color(0xFFE53935);
    if (t >= 33) return const Color(0xFFFF7043);
    if (t >= 30) return const Color(0xFFFFA726);
    if (t >= 27) return const Color(0xFF66BB6A);
    return const Color(0xFF42A5F5);
  }

  LinearGradient _bgGradient(int code) {
    if (code == 0) {
      // Cerah — orange-kuning
      return const LinearGradient(
        colors: [Color(0xFFFF7043), Color(0xFFFFB300), Color(0xFFFFD54F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    if ([61, 63, 65, 80, 81, 82].contains(code)) {
      // Hujan — biru gelap
      return const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    if ([95, 96, 99].contains(code)) {
      // Badai — ungu gelap
      return const LinearGradient(
        colors: [Color(0xFF1A0733), Color(0xFF311B92), Color(0xFF4527A0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    // Default — hijau-biru (tema app)
    return const LinearGradient(
      colors: [Color(0xFF0A3D2E), Color(0xFF1A6B4A), Color(0xFF2ECC71)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  String _dayName(String dateStr, int index) {
    try {
      final dt = DateTime.parse(dateStr);
      if (index == 0) return 'Hari Ini';
      if (index == 1) return 'Besok';
      return DateFormat('EEEE', 'id_ID').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _dayShort(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM', 'id_ID').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  // ──────────────────────── WIDGETS ────────────────────────

  Widget _buildHeroSection(WeatherLoaded state, int code, double temp) {
    final storage = context.read<StorageService>();
    final city = storage.getUserCity() ?? storage.getUserProvince() ?? 'Lokasi Anda';
    final wind = _toDouble(state.current['windspeed']) ?? 0;
    final gradient = _bgGradient(code);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            children: [
              // Lingkaran dekor background
              Positioned(
                top: -40,
                right: -60,
                child: Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Weather emoji + temp
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${temp.toStringAsFixed(0)}°C',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 72,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _weatherDesc(code),
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                      .format(DateTime.now()),
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _weatherEmoji(code),
                            style: const TextStyle(fontSize: 80),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick stats row
                      Row(
                        children: [
                          _heroStat(Icons.air, '${wind.toStringAsFixed(0)} km/j', 'Angin'),
                          _heroDivider(),
                          if (state.forecast.isNotEmpty) ...[
                            _heroStat(
                              Icons.thermostat,
                              '${_toDouble(state.forecast[0]['max'])?.toStringAsFixed(0) ?? '--'}°',
                              'Maks',
                            ),
                            _heroDivider(),
                            _heroStat(
                              Icons.thermostat_outlined,
                              '${_toDouble(state.forecast[0]['min'])?.toStringAsFixed(0) ?? '--'}°',
                              'Min',
                            ),
                            _heroDivider(),
                            _heroStat(
                              Icons.water_drop_outlined,
                              '${_toDouble(state.forecast[0]['precipitation'])?.toStringAsFixed(0) ?? '0'} mm',
                              'Hujan',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // ── 7-Day Forecast ──
  Widget _build7DayForecast(List<Map<String, dynamic>> forecast) {
    return _sectionCard(
      title: '7 Hari ke Depan',
      icon: Icons.date_range_rounded,
      child: Column(
        children: List.generate(forecast.length, (i) {
          final day = forecast[i];
          final code = (day['code'] is num)
              ? (day['code'] as num).toInt()
              : 0;
          final max = _toDouble(day['max']) ?? 0;
          final min = _toDouble(day['min']) ?? 0;
          final precip = _toDouble(day['precipitation']) ?? 0;
          final dateStr = day['date']?.toString() ?? '';
          final isToday = i == 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withOpacity(0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Hari
                SizedBox(
                  width: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayName(dateStr, i),
                        style: GoogleFonts.inter(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _dayShort(dateStr),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Emoji
                Text(_weatherEmoji(code),
                    style: const TextStyle(fontSize: 22)),

                const SizedBox(width: 10),

                // Hujan
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop,
                          size: 13, color: Color(0xFF42A5F5)),
                      const SizedBox(width: 2),
                      Text(
                        '${precip.toStringAsFixed(0)} mm',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Temp bar
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Text(
                        '${min.toStringAsFixed(0)}°',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF42A5F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                _tempToColor(min),
                                _tempToColor(max),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${max.toStringAsFixed(0)}°',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _tempToColor(max),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Temperature Chart ──
  Widget _buildTempChart(List<Map<String, dynamic>> forecast) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    final temps = forecast.map((d) => _toDouble(d['max']) ?? 0).toList();
    final minTemps = forecast.map((d) => _toDouble(d['min']) ?? 0).toList();
    final days = forecast.map((d) {
      try {
        final dt = DateTime.parse(d['date'].toString());
        return DateFormat('E', 'id_ID').format(dt);
      } catch (_) {
        return '';
      }
    }).toList();

    final maxY = (temps.reduce((a, b) => a > b ? a : b) + 3);
    final minY = (minTemps.reduce((a, b) => a < b ? a : b) - 3);

    return _sectionCard(
      title: 'Grafik Suhu 7 Hari',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.12),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}°',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        days[i],
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              // Max temp line
              LineChartBarData(
                spots: List.generate(
                    temps.length, (i) => FlSpot(i.toDouble(), temps[i])),
                isCurved: true,
                curveSmoothness: 0.35,
                color: const Color(0xFFFF7043),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFFF7043),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF7043).withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Min temp line
              LineChartBarData(
                spots: List.generate(
                    minTemps.length,
                    (i) => FlSpot(i.toDouble(), minTemps[i])),
                isCurved: true,
                curveSmoothness: 0.35,
                color: const Color(0xFF42A5F5),
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF42A5F5),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rekomendasi ternak berdasarkan cuaca ──
  Widget _buildFarmRecommendation(int code, double temp) {
    final tips = _getTips(code, temp);

    return _sectionCard(
      title: 'Rekomendasi untuk Peternakan',
      icon: Icons.tips_and_updates_rounded,
      iconColor: AppColors.statusWarning,
      child: Column(
        children: tips
            .map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tip['color'].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          tip['emoji'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip['title'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tip['desc'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _getTips(int code, double temp) {
    final tips = <Map<String, dynamic>>[];

    if (temp > 33) {
      tips.add({
        'emoji': '🌡️',
        'title': 'Suhu Kandang Kritis',
        'desc': 'Pastikan ventilasi optimal dan sediakan air minum ekstra. Hindari aktivitas berat pada ternak.',
        'color': AppColors.statusDanger,
      });
    } else if (temp > 30) {
      tips.add({
        'emoji': '🌬️',
        'title': 'Cek Ventilasi Kandang',
        'desc': 'Suhu cukup tinggi. Buka jendela dan kipas agar kandang tetap sejuk.',
        'color': AppColors.statusWarning,
      });
    } else {
      tips.add({
        'emoji': '✅',
        'title': 'Suhu Nyaman',
        'desc': 'Kondisi suhu ideal untuk ternak. Pertahankan kondisi kandang saat ini.',
        'color': AppColors.statusGood,
      });
    }

    if ([61, 63, 65, 80, 81, 82, 95, 96, 99].contains(code)) {
      tips.add({
        'emoji': '🌧️',
        'title': 'Waspadai Hujan',
        'desc': 'Pastikan atap kandang tidak bocor dan drainase lancar. Kandang harus tetap kering.',
        'color': const Color(0xFF42A5F5),
      });
      tips.add({
        'emoji': '🦠',
        'title': 'Risiko Penyakit Meningkat',
        'desc': 'Cuaca lembap meningkatkan risiko infeksi. Periksa kesehatan ternak secara rutin.',
        'color': AppColors.statusDanger,
      });
    }

    if ([1, 2, 3, 45, 48].contains(code)) {
      tips.add({
        'emoji': '🌫️',
        'title': 'Waspadai Kelembapan',
        'desc': 'Cuaca mendung meningkatkan kelembapan. Pastikan sirkulasi udara baik di dalam kandang.',
        'color': AppColors.textSecondary,
      });
    }

    if (code == 0) {
      tips.add({
        'emoji': '☀️',
        'title': 'Hari Cerah',
        'desc': 'Manfaatkan hari cerah untuk pembersihan kandang dan penjemuran peralatan.',
        'color': AppColors.statusWarning,
      });
    }

    tips.add({
      'emoji': '💧',
      'title': 'Kebutuhan Air',
      'desc': temp > 30
          ? 'Suhu tinggi → tingkatkan porsi minum 20–30% dari biasa.'
          : 'Pastikan ketersediaan air bersih setiap saat.',
      'color': const Color(0xFF42A5F5),
    });

    return tips;
  }

  // ── Precipitation Chart ──
  Widget _buildPrecipChart(List<Map<String, dynamic>> forecast) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    final precipData = forecast
        .map((d) => _toDouble(d['precipitation']) ?? 0)
        .toList();
    final maxPrecip =
        precipData.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final days = forecast.map((d) {
      try {
        final dt = DateTime.parse(d['date'].toString());
        return DateFormat('E', 'id_ID').format(dt);
      } catch (_) {
        return '';
      }
    }).toList();

    return _sectionCard(
      title: 'Curah Hujan 7 Hari (mm)',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF42A5F5),
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
            maxY: maxPrecip + 2,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (spot) =>
                    AppColors.textPrimary.withOpacity(0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} mm',
                  GoogleFonts.inter(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        days[i],
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.12),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(precipData.length, (i) {
              final isHigh = precipData[i] > 10;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: precipData[i] == 0 ? 0.2 : precipData[i],
                    color: isHigh
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF42A5F5),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Source info ──
  Widget _buildDataSource() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.satellite_alt_rounded,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data cuaca dari Open-Meteo API • Diperbarui otomatis',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color iconColor = AppColors.primary,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ──────────────────────── BUILD ────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: BlocBuilder<WeatherCubit, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoading || state is WeatherInitial) {
            return Container(
              decoration: const BoxDecoration(
                gradient: AppColors.homeBackground,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (state is WeatherError) {
            return Container(
              decoration: const BoxDecoration(gradient: AppColors.homeBackground),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Colors.white70, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data cuaca',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<WeatherCubit>().fetchWeather(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is WeatherLoaded) {
            final code =
                state.current['weathercode'] is num
                ? (state.current['weathercode'] as num).toInt()
                : int.tryParse(
                        state.current['weathercode']?.toString() ?? '0') ??
                    0;
            final temp = _toDouble(state.current['temperature']) ?? 28.0;

            return CustomScrollView(
              slivers: [
                // Hero section sebagai SliverToBoxAdapter
                SliverToBoxAdapter(
                  child: _buildHeroSection(state, code, temp),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7F9),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _build7DayForecast(state.forecast),
                        _buildTempChart(state.forecast),
                        _buildPrecipChart(state.forecast),
                        _buildFarmRecommendation(code, temp),
                        _buildDataSource(),
                        SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
