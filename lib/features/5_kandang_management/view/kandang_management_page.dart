import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/indonesian_cities.dart';
import '../../../core/widgets/glass_container.dart';
import '../cubit/barn_cubit.dart';
import '../cubit/barn_state.dart';
import '../../3_schedule/cubit/schedule_cubit.dart';
import '../../3_schedule/cubit/schedule_state.dart';
import '../../5_ai_chat/view/ai_assistant_page.dart';

class KandangManagementPage extends StatelessWidget {
  const KandangManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BarnCubit(
            api: context.read<ApiService>(),
            storage: context.read<StorageService>(),
          )..fetchBarns(),
        ),
        BlocProvider(
          create: (context) => ScheduleCubit(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          )..fetchSchedule(),
        ),
      ],
      child: const KandangManagementView(),
    );
  }
}

class KandangManagementView extends StatefulWidget {
  const KandangManagementView({super.key});

  @override
  State<KandangManagementView> createState() => _KandangManagementViewState();
}

class _KandangManagementViewState extends State<KandangManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>>? _financesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _loadFinances() {
    final barnState = context.read<BarnCubit>().state;
    if (barnState is BarnLoaded && barnState.barns.isNotEmpty) {
      final barnId = barnState.barns.first['id'].toString();
      setState(() {
        _financesFuture = context.read<ApiService>().getBarnFinances(barnId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =================== SECTIONS ===================

  Widget _buildGreetingHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Manajemen Kandang',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementSummary() {
    // Dummy 7-day data
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final financeData = [45.0, 72.0, 38.0, 90.0, 55.0, 68.0, 82.0];

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, schedState) {
        List<String> schedules = [];
        if (schedState is ScheduleLoaded) schedules = schedState.schedules;
        final int feedCount = schedules.length;
        
        double todayFeedKg = 0;
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
        }

        // Feed data 7 hari berdasarkan jadwal (otomatis)
        final feedData = List.generate(
          7,
          (i) => i == 6 ? todayFeedKg : (todayFeedKg * (0.8 + (i % 3) * 0.15)),
        );

        return GlassContainer(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ringkasan Kandang',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '7 hari terakhir',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stats row singkat
              BlocBuilder<BarnCubit, BarnState>(
                builder: (context, barnState) {
                  double stockGudang = 0;
                  if (barnState is BarnLoaded && barnState.barns.isNotEmpty) {
                    final barnId = barnState.barns.first['id'].toString();
                    stockGudang = context.read<BarnCubit>().getFeedStockGudang(barnId);
                  }
                  return Row(
                    children: [
                      _summaryStatChip(
                        icon: Icons.warehouse_rounded,
                        label: 'Stok Pakan',
                        value: '${stockGudang.toStringAsFixed(1)} kg',
                        color: AppColors.statusWarning,
                      ),
                      const SizedBox(width: 8),
                      _summaryStatChip(
                        icon: Icons.schedule_rounded,
                        label: 'Jadwal aktif',
                        value: '$feedCount jadwal',
                        color: AppColors.primary,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // ── Chart bawah: Bar gabungan keuangan & pakan ──
              SizedBox(
                height: 120,
                child: _mgmtCombinedBarChart(
                  financeData: financeData,
                  feedData: feedData,
                  days: days,
                  financeColor: AppColors.primary,
                  feedColor: AppColors.statusWarning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mgmtCombinedBarChart({
    required List<double> financeData,
    required List<double> feedData,
    required List<String> days,
    required Color financeColor,
    required Color feedColor,
  }) {
    final double maxFinance = financeData.reduce((a, b) => a > b ? a : b);
    final double maxFeed = feedData.reduce((a, b) => a > b ? a : b);
    // Normalize feed to finance scale so they fit well
    final double ratio = maxFinance > 0 ? maxFeed / maxFinance : 1;
    final double safeRatio = ratio == 0 ? 1 : ratio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: financeColor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Keuangan', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Container(width: 7, height: 7, decoration: BoxDecoration(color: feedColor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Pakan', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxFinance * 1.1,
              minY: 0,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(days[i], style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary)),
                      );
                    },
                    reservedSize: 14,
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(financeData.length, (i) {
                final isLast = i == financeData.length - 1;
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: financeData[i],
                      color: isLast ? financeColor : financeColor.withOpacity(0.3),
                      width: 6,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: feedData[i] / safeRatio,
                      color: isLast ? feedColor : feedColor.withOpacity(0.3),
                      width: 6,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

  Widget _buildTabSection() {
    return Column(
      children: [
        // Tab bar
        GlassContainer(
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(20),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1ABC9C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Kandang'),
              Tab(text: 'Pakan'),
              Tab(text: 'Keuangan'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: [
                _buildBarnTab(),
                _buildFeedTab(),
                _buildFinanceTab(),
              ][_tabController.index],
            );
          },
        ),
      ],
    );
  }

  // ============= KANDANG TAB — Direct form (1 akun = 1 kandang) =============

  Widget _buildBarnTab() {
    return BlocBuilder<BarnCubit, BarnState>(
      builder: (context, state) {
        if (state is BarnLoading || state is BarnInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Ambil data kandang pertama jika ada
        Map<String, dynamic>? barn;
        if (state is BarnLoaded && state.barns.isNotEmpty) {
          barn = state.barns.first as Map<String, dynamic>?;
        }

        return _buildBarnDirectForm(barn);
      },
    );
  }

  Widget _buildBarnDirectForm(Map<String, dynamic>? barn) {
    return _BarnDirectFormWidget(barn: barn);
  }

  // ============= PAKAN TAB — Otomatis dari jadwal =============

  Widget _buildFeedTab() {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        List<String> schedules = [];
        if (state is ScheduleLoaded) schedules = state.schedules;
        if (state is ScheduleUpdating) schedules = state.schedules;

        // Hitung pakan otomatis per jadwal (2.5 kg per pemberian)
        const double kgPerFeed = 2.5;

        // Log pakan otomatis: jadwal yang sudah lewat hari ini otomatis tercatat
        final now = TimeOfDay.now();
        final feedLogs = schedules.map((scheduleRaw) {
          // Parse waktu jadwal
          String scheduleTime = scheduleRaw;
          String portion = 'sedang';
          if (scheduleRaw.contains('|')) {
            final split = scheduleRaw.split('|');
            scheduleTime = split[0];
            portion = split.length > 1 ? split[1] : 'sedang';
          }

          int hour = 0;
          int minute = 0;
          try {
            final parts = scheduleTime.split(':');
            hour = int.parse(parts[0]);
            minute = int.parse(parts[1]);
          } catch (_) {}

          double logKg = kgPerFeed;
          if (portion == 'sedikit') logKg = kgPerFeed * 0.6;
          if (portion == 'banyak') logKg = kgPerFeed * 1.6;

          // Cek apakah jadwal sudah terlewat (otomatis tercatat)
          final schedHour = hour;
          final schedMin = minute;
          final hasExecuted = (schedHour < now.hour) ||
              (schedHour == now.hour && schedMin <= now.minute);

          return {
            'time': scheduleTime,
            'kg': logKg.toStringAsFixed(1),
            'status': hasExecuted ? 'selesai' : 'menunggu',
          };
        }).toList();

        final totalKgHariIni = feedLogs
            .where((l) => l['status'] == 'selesai')
            .fold<double>(0, (sum, l) => sum + double.parse(l['kg']!));

        final barnState = context.read<BarnCubit>().state;
        int? barnId;
        if (barnState is BarnLoaded && barnState.barns.isNotEmpty) {
          barnId = barnState.barns.first['id'] as int?;
        }

        double stockGudang = 0;
        double stockAlat = 0;
        if (barnId != null) {
          final cubit = context.read<BarnCubit>();
          stockGudang = cubit.getFeedStockGudang(barnId.toString());
          stockAlat = cubit.getFeedStockAlat(barnId.toString());
          
          // Lakukan deduksi visual untuk jadwal hari ini yang sudah selesai
          stockAlat = stockAlat - totalKgHariIni;
          if (stockAlat < 0) stockAlat = 0;
        }

        return Column(
          children: [
            // Row stok pakan
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warehouse_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('Stok Gudang', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${stockGudang.toStringAsFixed(1)} kg', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showAddStockDialog(context, barnId!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Tambah Stok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.statusWarning),
                            const SizedBox(width: 6),
                            Text('Dalam Alat', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${stockAlat.toStringAsFixed(1)} kg', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (stockGudang > 0) {
                                final qty = stockGudang < 10.0 ? stockGudang : 10.0;
                                await context.read<BarnCubit>().transferFeedStockToAlat(barnId.toString(), qty);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Pakan berhasil diisikan $qty kg ke alat')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Stok gudang habis')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusWarning.withOpacity(0.1),
                              foregroundColor: AppColors.statusWarning,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Isi Ulang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Info pakan otomatis
            GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.statusWarning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_mode_rounded,
                        color: AppColors.statusWarning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pakan Otomatis Aktif',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tercatat ${kgPerFeed.toStringAsFixed(1)} kg per jadwal secara otomatis',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tanggal
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hari Ini — ${DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.now())}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Feed logs dari jadwal
            if (schedules.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_rounded,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada jadwal pakan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Atur jadwal di halaman IoPakan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ...feedLogs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _feedLogItem(log),
              )),
              const SizedBox(height: 10),
              // Total
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pakan Hari Ini',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${feedLogs.where((l) => l['status'] == 'selesai').length} dari ${feedLogs.length} jadwal selesai',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${totalKgHariIni.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.statusWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _feedLogItem(Map<String, dynamic> log) {
    final isDone = log['status'] == 'selesai';
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.statusWarning.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              log['time']!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDone ? AppColors.statusWarning : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone ? 'Pakan Diberikan ✓' : 'Menunggu Jadwal',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${log['kg']} kg (otomatis)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.statusGood.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isDone ? 'Selesai' : 'Pending',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDone ? AppColors.statusGood : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, int barnId) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Stok Gudang (kg)'),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Contoh: 50'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              if (qty > 0) {
                await context.read<BarnCubit>().addFeedStockGudang(barnId.toString(), qty);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok gudang berhasil ditambahkan')));
                  setState(() {}); // trigger rebuild
                }
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _showTransferStockDialog(BuildContext context, int barnId, double maxGudang) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Isi Pakan ke Alat (kg)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Maksimal dari gudang: ${maxGudang.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Contoh: 10'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              if (qty > 0 && qty <= maxGudang) {
                await context.read<BarnCubit>().transferFeedStockToAlat(barnId.toString(), qty);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pakan berhasil diisikan ke alat')));
                  setState(() {}); // trigger rebuild
                }
              } else if (qty > maxGudang) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok gudang tidak cukup')));
              }
            },
            child: const Text('Isi'),
          )
        ],
      ),
    );
  }

  // ============= FINANSIAL TAB =============

  Widget _buildFinanceTab() {
    if (_financesFuture == null) {
      _loadFinances();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _financesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        
        final totalThisMonth = double.tryParse(summary['total_this_month']?.toString() ?? '0') ?? 0.0;
        final byCategory = summary['by_category'] as List<dynamic>? ?? [];

        final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

        final standardCats = [
          {'key': 'pakan', 'label': 'Pakan', 'icon': Icons.set_meal_outlined, 'color': AppColors.statusWarning},
          {'key': 'obat', 'label': 'Obat', 'icon': Icons.medical_services_outlined, 'color': AppColors.statusDanger},
          {'key': 'listrik', 'label': 'Listrik', 'icon': Icons.bolt_outlined, 'color': AppColors.statusInfo},
          {'key': 'lainnya', 'label': 'Lainnya', 'icon': Icons.more_horiz_rounded, 'color': AppColors.textSecondary},
        ];

        List<Map<String, dynamic>> categories = [];
        for (var sc in standardCats) {
          final found = byCategory.firstWhere((e) => e['category'] == sc['key'], orElse: () => null);
          final amount = found != null ? (double.tryParse(found['total']?.toString() ?? '0') ?? 0.0) : 0.0;
          final pct = totalThisMonth > 0 ? (amount / totalThisMonth) : 0.0;
          categories.add({
            'label': sc['label'],
            'amount': fmt.format(amount),
            'icon': sc['icon'],
            'color': sc['color'],
            'pct': pct,
          });
        }

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran Bulan Ini',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fmt.format(totalThisMonth),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _financeItem(cat),
            )),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showAddFinanceDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Catat Pengeluaran',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
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
    );
  }

  Widget _financeItem(Map<String, dynamic> cat) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (cat['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat['label'] as String,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cat['pct'] as double,
                    backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                    color: cat['color'] as Color,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            cat['amount'] as String,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFinanceDialog(BuildContext context) {
    final barnState = context.read<BarnCubit>().state;
    if (barnState is BarnLoaded && barnState.barns.isNotEmpty) {
      final barnId = barnState.barns.first['id'] as int;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AddFinanceSheet(barnId: barnId),
      ).then((res) {
        if (res == true) {
          _loadFinances();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Icon(Icons.check_circle_rounded, color: AppColors.statusGood, size: 48),
              content: Text('Catatan pengeluaran berhasil disimpan!', textAlign: TextAlign.center, style: GoogleFonts.inter()),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kandang belum ada. Buat kandang terlebih dahulu.')),
      );
    }
  }


  // ============= AI SECTION =============

  Widget _buildAiSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1ABC9C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/icon/ai.png', width: 52, height: 52, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanya Prof. Jago',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Analisis kandang, pakan, dan tips beternak',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // =================== BUILD ===================

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, bottomPad + 100),
          children: [
            _buildGreetingHeader(),
            const SizedBox(height: 16),
            _buildManagementSummary(),
            const SizedBox(height: 16),
            _buildTabSection(),
            const SizedBox(height: 16),
            _buildAiSection(),
          ],
        ),
      ),
    );
  }
}

// =================== BARN DIRECT FORM (1 Akun = 1 Kandang) ===================

class _BarnDirectFormWidget extends StatefulWidget {
  final Map<String, dynamic>? barn;
  const _BarnDirectFormWidget({this.barn});

  @override
  State<_BarnDirectFormWidget> createState() => _BarnDirectFormWidgetState();
}

class _BarnDirectFormWidgetState extends State<_BarnDirectFormWidget> {
  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _capCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _descCtrl;
  bool _loading = false;
  bool _saved = false;
  late bool _isEditing;



  @override
  void initState() {
    super.initState();
    final b = widget.barn;
    _nameCtrl = TextEditingController(text: b?['barn_name'] ?? '');
    _typeCtrl = TextEditingController(text: b?['animal_type'] ?? '');
    _capCtrl = TextEditingController(text: b?['capacity']?.toString() ?? '');
    _locCtrl = TextEditingController(text: b?['location'] ?? '');
    _descCtrl = TextEditingController(text: b?['description'] ?? '');
    _isEditing = b == null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _capCtrl.dispose();
    _locCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _saved = false; });
    try {
      final updates = {
        'barn_name': _nameCtrl.text.trim(),
        'animal_type': _typeCtrl.text.trim().isEmpty ? 'Umum' : _typeCtrl.text.trim(),
        'capacity': int.tryParse(_capCtrl.text),
        'location': _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      };
      
      if (widget.barn == null) {
        await context.read<BarnCubit>().createBarn(
          barnName: updates['barn_name'] as String,
          animalType: updates['animal_type'] as String,
          capacity: updates['capacity'] as int?,
          location: updates['location'] as String?,
          description: updates['description'] as String?,
        );
      } else {
        await context.read<BarnCubit>().updateBarn(
          barnId: widget.barn!['id'].toString(),
          updates: updates,
        );
      }
      if (mounted) {
        setState(() { _loading = false; _saved = true; _isEditing = false; });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle_rounded, color: AppColors.statusGood, size: 48),
            content: Text('Data kandang berhasil disimpan!', textAlign: TextAlign.center, style: GoogleFonts.inter()),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickSaveCapacity() async {
    if (widget.barn == null) return;
    final cap = int.tryParse(_capCtrl.text);
    if (cap == null) return;
    
    await context.read<BarnCubit>().updateBarn(
      barnId: widget.barn!['id'].toString(),
      updates: {'capacity': cap},
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kapasitas berhasil diupdate!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing && widget.barn != null) {
      return _buildInfoView();
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.warehouse_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Info Kandang Saya',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Isi dan perbarui data kandang di bawah',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Form fields
          _formField(
            controller: _nameCtrl,
            label: 'Nama Kandang',
            hint: 'cth: Kandang Utama',
            icon: Icons.warehouse_outlined,
          ),
          const SizedBox(height: 12),
          _formField(
            controller: _typeCtrl,
            label: 'Jenis Ternak',
            hint: 'cth: Ayam Broiler',
            icon: Icons.pets_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _formField(
                  controller: _capCtrl,
                  label: 'Kapasitas (ekor)',
                  hint: 'cth: 500',
                  icon: Icons.format_list_numbered_rounded,
                  isNum: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _locationAutocomplete(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _formField(
            controller: _descCtrl,
            label: 'Catatan',
            hint: 'Catatan tambahan tentang kandang...',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Simpan button
          GestureDetector(
            onTap: _loading ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: _saved
                    ? const LinearGradient(
                        colors: [AppColors.statusGood, Color(0xFF1ABC9C)])
                    : const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1ABC9C)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _saved ? Icons.check_rounded : Icons.save_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _saved ? 'Tersimpan!' : 'Simpan Perubahan',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (widget.barn != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: Text('Batal Edit', style: GoogleFonts.inter(color: AppColors.statusDanger)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _locCtrl.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return IndonesianCities.cities.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _locCtrl.text = selection;
          },
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            // Sinkronkan controller Autocomplete dengan controller Lokasi
            controller.addListener(() {
              _locCtrl.text = controller.text;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(option, style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.barn!['barn_name'] ?? 'Kandang Utama',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                      onPressed: () => setState(() => _isEditing = true),
                      tooltip: 'Edit Data Kandang',
                    ),
                  ],
                ),
                const Divider(),
                _infoRow(Icons.pets_rounded, 'Total Ayam Saat Ini', '${widget.barn!['capacity'] ?? 0} ekor'),
                const SizedBox(height: 12),
                _infoRow(Icons.pets_outlined, 'Jenis Ternak', widget.barn!['animal_type'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.location_on_outlined, 'Lokasi', widget.barn!['location'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.notes_rounded, 'Catatan', widget.barn!['description'] ?? '-', maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.statusWarning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.format_list_numbered_rounded, color: AppColors.statusWarning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jumlah Ayam / Kapasitas', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      TextField(
                        controller: _capCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save_rounded, color: AppColors.primary),
                  onPressed: _quickSaveCapacity,
                  tooltip: 'Simpan Kapasitas',
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), maxLines: maxLines, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNum = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            hintStyle: GoogleFonts.inter(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =================== BOTTOM SHEETS ===================
class _AddFinanceSheet extends StatefulWidget {
  final int barnId;
  const _AddFinanceSheet({required this.barnId});

  @override
  State<_AddFinanceSheet> createState() => _AddFinanceSheetState();
}

class _AddFinanceSheetState extends State<_AddFinanceSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'pakan';
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveFinance() async {
    final amountText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    try {
      final storage = context.read<StorageService>();
      final userId = storage.getUserIdFromDB();
      if (userId != null) {
        await context.read<ApiService>().addBarnFinance({
          'barn_id': widget.barnId,
          'user_id': int.parse(userId),
          'category': _category,
          'description': _descCtrl.text.trim(),
          'amount': amount,
        });

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['pakan', 'obat', 'listrik', 'lainnya'];
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5FAF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 18),
          Text('Catat Pengeluaran', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Text('Kategori', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: categories.map((c) => ChoiceChip(
            label: Text(c.toUpperCase()),
            selected: _category == c,
            onSelected: (_) => setState(() => _category = c),
            selectedColor: AppColors.primary.withOpacity(0.2),
          )).toList()),
          const SizedBox(height: 12),
          _buildInput(_descCtrl, 'Deskripsi', 'cth: Beli pakan 50kg'),
          const SizedBox(height: 12),
          _buildInput(_amountCtrl, 'Jumlah (Rp)', '150000', isNum: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _saveFinance,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Simpan Pengeluaran', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      );
  }

  Widget _buildInput(TextEditingController ctrl, String label, String hint, {bool isNum = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
