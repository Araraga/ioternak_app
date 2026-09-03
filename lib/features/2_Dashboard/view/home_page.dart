import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../6_weather/cubit/weather_cubit.dart';
import '../../6_weather/cubit/weather_state.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../cubit/sensor_data_cubit.dart';
import '../cubit/sensor_data_state.dart';
import '../view/notifications_page.dart';
import '../view/sensor_detail_page.dart';
import '../../5_kandang_management/view/kandang_management_page.dart';
import '../../6_weather/view/weather_detail_page.dart';
import '../../../core/utils/navigation_tab_switcher.dart';
import '../../0_splash/view/onboarding_page.dart';
import '../../1_provisioning/view/provision_page.dart';
import '../../3_schedule/view/schedule_page.dart';
import '../../3_schedule/cubit/schedule_cubit.dart';
import '../../3_schedule/cubit/schedule_state.dart';
import '../../5_kandang_management/cubit/barn_cubit.dart';
import '../../5_kandang_management/cubit/barn_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              DashboardCubit(storageService: context.read<StorageService>())
                ..checkDevices(),
        ),
        BlocProvider(
          create: (context) => WeatherCubit(
            apiService: context.read<ApiService>(),
            storage: context.read<StorageService>(),
          )..fetchWeather(),
        ),
        BlocProvider(
          create: (context) => NotificationCubit(
            api: context.read<ApiService>(),
            storage: context.read<StorageService>(),
          )..fetchNotifications(),
        ),
        BlocProvider(
          create: (context) => SensorDataCubit(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          )..fetchSensorData(),
        ),
        BlocProvider(
          create: (context) => ScheduleCubit(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          )..fetchSchedule(),
        ),
        BlocProvider(
          create: (context) => BarnCubit(
            api: context.read<ApiService>(),
            storage: context.read<StorageService>(),
          )..fetchBarns(),
        ),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    _syncDevices();
  }

  Future<void> _syncDevices() async {
    try {
      final storage = context.read<StorageService>();
      final api = context.read<ApiService>();
      final dashboardCubit = context.read<DashboardCubit>();
      final sensorCubit = context.read<SensorDataCubit>();
      final userId = storage.getUserIdFromDB();

      if (userId != null) {
        final devices = await api.getMyDevices(userId);
        bool dataChanged = false;
        for (var device in devices) {
          final type = device['type']?.toString().toLowerCase();
          if (type == 'sensor' || type == 'iopeka') {
            await storage.saveSensorId(device['device_id']);
            dataChanged = true;
          } else if (type == 'feeder' || type == 'iopakan') {
            await storage.savePakanId(device['device_id']);
            dataChanged = true;
          }
        }
        if (dataChanged && mounted) {
          dashboardCubit.checkDevices();
          sensorCubit.fetchSensorData();
        }
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  // ══════════════════ HELPERS ══════════════════

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _weatherDescription(int code) {
    if (code == 0) return 'Cerah';
    if ([1, 2, 3].contains(code)) return 'Cerah Berawan';
    if ([45, 48].contains(code)) return 'Kabut';
    if ([51, 53, 55].contains(code)) return 'Hujan Gerimis';
    if ([61, 63, 65, 80, 81, 82].contains(code)) return 'Hujan';
    if ([95, 96, 99].contains(code)) return 'Petir';
    return 'Berawan';
  }

  /// Pilih PNG asset sesuai kondisi cuaca
  String _weatherAsset(int code) {
    if (code == 0) return 'assets/icon/sunny.png';
    if ([1, 2, 3].contains(code)) return 'assets/icon/sunny.png';
    if ([45, 48].contains(code)) return 'assets/icon/windy.png';
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) {
      return 'assets/icon/rain.png';
    }
    if ([95, 96, 99].contains(code)) return 'assets/icon/thunder.png';
    return 'assets/icon/sunny.png';
  }

  Color _tempColor(double? t) {
    if (t == null) return AppColors.textSecondary;
    if (t > 35) return AppColors.statusDanger;
    if (t > 32) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  Color _gasColor(double? g) {
    if (g == null) return AppColors.textSecondary;
    if (g > 25) return AppColors.statusDanger;
    if (g > 15) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Aplikasi?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Semua data lokal akan dihapus.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final storage = context.read<StorageService>();
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              await storage.clearAllData();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.statusDanger),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════ WIDGETS ══════════════════

  /// ── Header: "Halo, [Name]" + Notif Bell ──
  Widget _buildHeader(BuildContext context, DashboardLoaded state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onLongPress: () => _showResetDialog(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${state.userName.split(' ').first}',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Notification bell
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, notifState) {
            int unread = 0;
            if (notifState is NotificationLoaded) unread = notifState.unreadCount;
            final notifCubit = context.read<NotificationCubit>();
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ).then((_) => notifCubit.fetchNotifications());
              },
              child: Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.statusDanger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// ── Weather Card — clickable → KandangManagementPage ──
  Widget _buildWeatherCard() {
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        if (state is! WeatherLoaded) {
          return _weatherShimmer();
        }

        final storage = context.read<StorageService>();
        final city = storage.getUserCity() ?? '';
        final province = storage.getUserProvince() ?? '';
        final locationText = city.isNotEmpty ? city : province;

        final temp = _toDouble(state.current['temperature']) ?? 0.0;
        final weatherCode =
            state.current['weathercode'] is num
            ? (state.current['weathercode'] as num).toInt()
            : int.tryParse(state.current['weathercode']?.toString() ?? '0') ?? 0;

        final maxTemp = state.forecast.isNotEmpty
            ? _toDouble(state.forecast[0]['max'])
            : null;
        final minTemp = state.forecast.isNotEmpty
            ? _toDouble(state.forecast[0]['min'])
            : null;

        final desc = _weatherDescription(weatherCode);
        final asset = _weatherAsset(weatherCode);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeatherDetailPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Weather image
                Image.asset(
                  asset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.wb_sunny_rounded,
                    size: 40,
                    color: AppColors.statusWarning,
                  ),
                ),
                const SizedBox(width: 12),

                // Location + desc
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (locationText.isNotEmpty)
                        Text(
                          locationText,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Temp
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${temp.toStringAsFixed(0)}°',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (maxTemp != null && minTemp != null)
                      Text(
                        '↑${maxTemp.toStringAsFixed(0)}° ↓${minTemp.toStringAsFixed(0)}°',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _weatherShimmer() {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 12, width: 80, color: Colors.grey.shade200),
                const SizedBox(height: 6),
                Container(height: 10, width: 120, color: Colors.grey.shade100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ── Ringkasan Kandang: combined donut (pakan) + bar (keuangan) ──
  Widget _buildSummaryCard() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final financeData = [45.0, 72.0, 38.0, 90.0, 55.0, 68.0, 82.0];
    final double maxFinance = financeData.reduce((a, b) => a > b ? a : b);

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, schedState) {
        // Hitung pakan hari ini dari jadwal yang ada
        List<String> schedules = [];
        if (schedState is ScheduleLoaded) schedules = schedState.schedules;
        final int feedCount = schedules.length;
        
        double todayFeedKg = 0;
        List<double> feedParts = [];
        for (var sched in schedules) {
          String portion = 'sedang';
          if (sched.contains('|')) {
            final split = sched.split('|');
            if (split.length > 1) portion = split[1];
          }
          double kg = 2.5;
          if (portion == 'sedikit') kg = 2.5 * 0.6;
          if (portion == 'banyak') kg = 2.5 * 1.6;
          todayFeedKg += kg;
          feedParts.add(kg);
        }
        
        if (feedCount == 0) {
          feedParts = [1.0];
        }
        
        final List<Color> feedColors = [
          AppColors.statusWarning,
          const Color(0xFFFF7043),
          const Color(0xFFFFB300),
          const Color(0xFFFFC107),
          const Color(0xFFFF8F00),
        ];

        return GestureDetector(
          onTap: () {
            // Switch ke tab Kandang (index 1) agar navbar tetap muncul.
            // Dicari lewat NavigationTabSwitcher callback yang diset dari main_navigation_page.
            if (NavigationTabSwitcher.switchTab != null) {
              NavigationTabSwitcher.switchTab!(1);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const KandangManagementPage()),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Text(
                      'Ringkasan Kandang',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '7 hari ini',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── TOP ROW: Donut kiri + Stats kanan ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Donut chart pakan
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 24,
                              startDegreeOffset: -90,
                              sections: feedCount > 0
                                  ? List.generate(
                                      feedParts.length,
                                      (i) => PieChartSectionData(
                                        value: feedParts[i],
                                        color: feedColors[i % feedColors.length],
                                        radius: 14,
                                        showTitle: false,
                                      ),
                                    )
                                  : [
                                      PieChartSectionData(
                                        value: 1,
                                        color: Colors.grey.shade200,
                                        radius: 14,
                                        showTitle: false,
                                      ),
                                    ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${todayFeedKg.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'kg',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Stats info pakan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocBuilder<BarnCubit, BarnState>(
                            builder: (context, barnState) {
                              int totalAyam = 0;
                              double stockGudang = 0;
                              if (barnState is BarnLoaded && barnState.barns.isNotEmpty) {
                                final barnId = barnState.barns.first['id'].toString();
                                totalAyam = int.tryParse(barnState.barns.first['capacity']?.toString() ?? '0') ?? 0;
                                stockGudang = context.read<BarnCubit>().getFeedStockGudang(barnId);
                              }
                              return Column(
                                children: [
                                  _statRow(
                                    label: 'Total Ayam Saat Ini',
                                    value: '$totalAyam ekor',
                                    color: AppColors.primary,
                                    icon: Icons.pets_rounded,
                                  ),
                                  const SizedBox(height: 8),
                                  _statRow(
                                    label: 'Stok Pakan',
                                    value: '${stockGudang.toStringAsFixed(1)} kg',
                                    color: AppColors.statusWarning,
                                    icon: Icons.warehouse_rounded,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                          _statRow(
                            label: 'Keuangan Hari Ini',
                            value: 'Rp ${(financeData.last * 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                            color: AppColors.statusInfo,
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }


  /// ── Perangkat Section Header ──
  Widget _buildDevicesHeader(BuildContext context, DashboardLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Perangkat Saat Ini',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () {
            final dashCubit = context.read<DashboardCubit>();
            final sensorCubit = context.read<SensorDataCubit>();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProvisionPage()),
            ).then((_) {
              dashCubit.checkDevices();
              _syncDevices();
              sensorCubit.fetchSensorData();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Tambah',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ── IoPeka Card (sensor) ──
  Widget _buildIoPekaCard() {
    return BlocBuilder<SensorDataCubit, SensorDataState>(
      builder: (context, state) {
        Map<String, dynamic> data = {};
        if (state is SensorDataLoaded && state.sensorDataList.isNotEmpty) {
          data = state.sensorDataList.first as Map<String, dynamic>? ?? {};
        }

        double? temp = _toDouble(data['temperature']);
        double? gas = _toDouble(data['amonia'] ?? data['gas_ppm']);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SensorDetailPage()),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Info kiri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IoPeka',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 Perangkat',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status chip ringkas
                      Row(
                        children: [
                          _sensorStatusDot(_tempColor(temp)),
                          const SizedBox(width: 5),
                          Text(
                            state is SensorDataLoading || state is SensorDataInitial
                                ? 'Memuat...'
                                : temp != null
                                    ? '${temp.toStringAsFixed(0)}° · ${gas != null ? '${gas.toStringAsFixed(0)} PPM' : '--'}'
                                    : 'Tidak ada data',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // IoPeka image — margin lebih besar dari card
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                  child: SizedBox(
                    width: 110,
                    height: 88,
                    child: Image.asset(
                      'assets/icon/iopeka.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sensors_rounded,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ── IoPakan Card (feeder) ──
  Widget _buildIoPakanCard() {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        List<String> schedules = [];
        if (state is ScheduleLoaded) schedules = state.schedules;

        return GestureDetector(
          onTap: () {
            final cubit = context.read<ScheduleCubit>();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchedulePage()),
            ).then((_) => cubit.fetchSchedule());
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Info kiri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IoPakan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2 Perangkat',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (state is ScheduleLoading || state is ScheduleInitial)
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.statusWarning,
                          ),
                        )
                      else if (schedules.isEmpty)
                        Text(
                          'Belum ada jadwal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: schedules
                              .take(4)
                              .map((t) => _timeChip(t))
                              .toList(),
                        ),
                    ],
                  ),
                ),

                // IoPakan image di kanan
                SizedBox(
                  width: 110,
                  height: 90,
                  child: Image.asset(
                    'assets/icon/iopakan.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_rounded,
                      size: 60,
                      color: AppColors.statusWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sensorStatusDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }


  Widget _timeChip(String time) {
    // Ambil hanya bagian jam (sebelum '|') agar tidak tampil "10:15 | Banyak"
    final displayTime = time.contains('|') ? time.split('|').first.trim() : time;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        displayTime,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ══════════════════ BUILD ══════════════════

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.homeBackground),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is DashboardLoaded) {
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  topPad + 20,
                  20,
                  bottomPad + 110,
                ),
                children: [
                  // ── Greeting ──
                  _buildHeader(context, state),
                  const SizedBox(height: 20),

                  // ── Weather ──
                  _buildWeatherCard(),
                  const SizedBox(height: 16),

                  // ── Ringkasan Minimalis ──
                  _buildSummaryCard(),
                  const SizedBox(height: 28),

                  // ── Perangkat Section ──
                  _buildDevicesHeader(context, state),
                  const SizedBox(height: 14),

                  if (!state.hasSensorDevice && !state.hasPakanDevice)
                    _buildEmptyDevices(context)
                  else ...[
                    if (state.hasSensorDevice) ...[
                      _buildIoPekaCard(),
                      const SizedBox(height: 12),
                    ],
                    if (state.hasPakanDevice)
                      _buildIoPakanCard(),
                  ],
                ],
              );
            }

            return Center(
              child: Text(
                'Gagal memuat data',
                style: GoogleFonts.inter(color: AppColors.statusDanger),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyDevices(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.device_hub_outlined,
            size: 48,
            color: AppColors.textSecondary.withAlpha(80),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada perangkat',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Tambah" untuk menghubungkan\nIoPeka atau IoPakan Anda',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
