import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../cubit/barn_state.dart';
import '../finance_page.dart';
import '../task_page.dart';

class ExecutiveDashboardKpi extends StatefulWidget {
  final BarnState barnState;
  const ExecutiveDashboardKpi({super.key, required this.barnState});

  @override
  State<ExecutiveDashboardKpi> createState() => _ExecutiveDashboardKpiState();
}

class _ExecutiveDashboardKpiState extends State<ExecutiveDashboardKpi> {
  Map<String, dynamic>? _overallFinance;
  bool _isLoadingFinance = true;

  @override
  void initState() {
    super.initState();
    _fetchOverallFinance();
  }

  @override
  void didUpdateWidget(covariant ExecutiveDashboardKpi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barnState != widget.barnState) {
      _fetchOverallFinance();
    }
  }

  Future<void> _fetchOverallFinance() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getFinancialSummary()));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (mounted) {
          setState(() {
            _overallFinance = data;
            _isLoadingFinance = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingFinance = false);
    }
  }

  String _fmtCurrency(num n) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(n);

  @override
  Widget build(BuildContext context) {
    int totalBarns = 0;
    int totalCapacity = 0;
    int totalActiveBirds = 0;
    double mortalityRate = 0.0;
    int pendingTasks = 0;

    if (widget.barnState is BarnLoaded) {
      final state = widget.barnState as BarnLoaded;
      totalBarns = state.barns.length;
      final summary = state.dashboardSummary;

      if (summary != null) {
        totalCapacity =
            int.tryParse(summary['total_capacity']?.toString() ?? '0') ?? 0;
        totalActiveBirds =
            int.tryParse(summary['total_active_birds']?.toString() ?? '0') ?? 0;
        mortalityRate =
            double.tryParse(summary['mortality_rate']?.toString() ?? '0') ??
            0.0;
        pendingTasks =
            int.tryParse(summary['pending_tasks_today']?.toString() ?? '0') ??
            0;
      } else {
        for (var b in state.barns) {
          totalCapacity += int.tryParse(b['capacity']?.toString() ?? '0') ?? 0;
          totalActiveBirds +=
              int.tryParse(b['active_birds_count']?.toString() ?? '0') ?? 0;
        }
      }
    }

    final double occupancy = totalCapacity > 0
        ? ((totalActiveBirds / totalCapacity) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dashboard Ringkas',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$totalBarns Kandang Aktif',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOverallFinanceCard(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Populasi Aktif',
                value: NumberFormat('#,###', 'id_ID').format(totalActiveBirds),
                unit: 'Ekor',
                subtitle: 'Kapasitas: $totalCapacity Ekor',
                progress: occupancy / 100.0,
                progressLabel: '${occupancy.toStringAsFixed(1)}% terisi',
                color: const Color(0xFF2ECC71),
                icon: Icons.pets_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Mortalitas',
                value: '${mortalityRate.toStringAsFixed(1)}%',
                unit: '',
                subtitle: mortalityRate <= 5.0
                    ? 'Kondisi Aman (<5%)'
                    : 'Perlu Diperhatikan',
                progress: (mortalityRate / 15.0).clamp(0.0, 1.0),
                progressLabel: mortalityRate <= 5.0 ? 'Optimal' : 'Waspada',
                color: mortalityRate <= 5.0
                    ? const Color(0xFF3498DB)
                    : const Color(0xFFE74C3C),
                icon: Icons.health_and_safety_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSimpleKpi(
                icon: Icons.domain_rounded,
                title: 'Unit Kandang',
                value: '$totalBarns Unit',
                color: const Color(0xFF8E44AD),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleKpi(
                icon: Icons.notifications_active_rounded,
                title: 'Jadwal Pengingat',
                value: '$pendingTasks Terjadwal',
                color: const Color(0xFFF39C12),
                onTap: () {
                  if (widget.barnState is BarnLoaded &&
                      (widget.barnState as BarnLoaded).barns.isNotEmpty) {
                    final firstBarnId =
                        int.tryParse(
                          (widget.barnState as BarnLoaded).barns[0]['id']
                              .toString(),
                        ) ??
                        0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskPage(barnId: firstBarnId),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallFinanceCard() {
    final inc =
        num.tryParse(_overallFinance?['total_income']?.toString() ?? '0') ?? 0;
    final exp =
        num.tryParse(_overallFinance?['total_expense']?.toString() ?? '0') ?? 0;
    final profit =
        num.tryParse(_overallFinance?['net_profit']?.toString() ?? '0') ??
        (inc - exp);
    final isProfit = profit >= 0;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinancePage()),
        );
        _fetchOverallFinance();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinanceHeader(isProfit),
            const SizedBox(height: 12),
            _buildFinanceBody(isProfit, profit, inc, exp),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceHeader(bool isProfit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:
                    (isProfit
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFE74C3C))
                        .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: isProfit
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Keuangan Peternakan',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'Detail Kas',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceBody(bool isProfit, num profit, num inc, num exp) {
    if (_isLoadingFinance) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _fmtCurrency(profit),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isProfit
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isProfit ? 'Surplus Kas' : 'Defisit Kas',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isProfit ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemasukan',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _fmtCurrency(inc),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 24, width: 1, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengeluaran',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _fmtCurrency(exp),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required double progress,
    required String progressLabel,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              progressLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleKpi({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
}
