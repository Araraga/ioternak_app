import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/navigation_tab_switcher.dart';
import '../../../5_kandang_management/cubit/barn_cubit.dart';
import '../../../5_kandang_management/cubit/barn_state.dart';
import '../../../5_kandang_management/view/kandang_management_page.dart';
import 'concentric_radial_chart.dart';

class HomeSummaryBarnCard extends StatelessWidget {
  const HomeSummaryBarnCard({super.key});

  void _navigateToBarnManagement(BuildContext context) {
    if (NavigationTabSwitcher.switchTab != null) {
      NavigationTabSwitcher.switchTab!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KandangManagementPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarnCubit, BarnState>(
      builder: (context, state) {
        if (state is BarnLoading) {
          return _buildLoadingSkeleton();
        }

        if (state is BarnLoaded) {
          if (state.barns.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildContentCard(context, state);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToBarnManagement(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.warehouse_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum Ada Kandang Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap untuk menambahkan kandang dan pantau operasional ternak Anda.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, BarnLoaded state) {
    final summary = state.dashboardSummary;
    int totalBarns = state.barns.length;
    int totalCapacity = 0;
    int totalActiveBirds = 0;
    double mortalityRate = 0.0;

    if (summary != null) {
      totalBarns = int.tryParse(summary['total_barns']?.toString() ?? '$totalBarns') ?? totalBarns;
      totalCapacity = int.tryParse(summary['total_capacity']?.toString() ?? '0') ?? 0;
      totalActiveBirds = int.tryParse(summary['total_active_birds']?.toString() ?? '0') ?? 0;
      mortalityRate = double.tryParse(summary['mortality_rate']?.toString() ?? '0') ?? 0.0;
    } else {
      for (var b in state.barns) {
        totalCapacity += int.tryParse(b['capacity']?.toString() ?? '0') ?? 0;
        totalActiveBirds += int.tryParse(b['active_birds_count']?.toString() ?? '0') ?? 0;
      }
    }

    final double occupancyProgress = totalCapacity > 0
        ? (totalActiveBirds / totalCapacity).clamp(0.0, 1.0)
        : 0.0;

    final double survivalProgress = ((100.0 - mortalityRate) / 100.0).clamp(0.0, 1.0);
    final double survivalPercent = survivalProgress * 100.0;

    // Hitung Stok Pakan Gudang + Alat
    double totalFeedStock = 0.0;
    if (summary != null) {
      totalFeedStock = double.tryParse(
            summary['total_feed_stock']?.toString() ??
                summary['feed_stock']?.toString() ??
                '0',
          ) ??
          0.0;
    }
    if (totalFeedStock == 0.0) {
      try {
        final storage = context.read<StorageService>();
        for (var b in state.barns) {
          final bId = b['id']?.toString() ?? '';
          if (bId.isNotEmpty) {
            totalFeedStock +=
                storage.getFeedStockGudang(bId) + storage.getFeedStockAlat(bId);
          }
        }
      } catch (_) {}
    }

    final double feedProgress = totalFeedStock > 0
        ? (totalFeedStock /
                (totalActiveBirds > 0
                    ? (totalActiveBirds * 0.12 * 3).clamp(50.0, 500.0)
                    : 100.0))
            .clamp(0.08, 1.0)
        : 0.04;

    final String feedStockStr = totalFeedStock > 0
        ? (totalFeedStock >= 1000
            ? '${(totalFeedStock / 1000).toStringAsFixed(1)} ton'
            : '${totalFeedStock.toStringAsFixed(totalFeedStock % 1 == 0 ? 0 : 1)} kg Tersedia')
        : '0 kg (Perlu Isi)';

    const colorOccupancy = Color(0xFF10B981);
    const colorSurvival = Color(0xFF0EA5E9);
    const colorFeed = Color(0xFFF59E0B);

    final numberFmt = NumberFormat('#,###', 'id_ID');

    return GestureDetector(
      onTap: () => _navigateToBarnManagement(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 22,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(totalBarns),
            const SizedBox(height: 16),
            _buildRingsAndStats(
              occupancyProgress: occupancyProgress,
              survivalProgress: survivalProgress,
              feedProgress: feedProgress,
              colorOccupancy: colorOccupancy,
              colorSurvival: colorSurvival,
              colorFeed: colorFeed,
              totalActiveBirds: totalActiveBirds,
              totalCapacity: totalCapacity,
              survivalPercent: survivalPercent,
              feedStockStr: feedStockStr,
              numberFmt: numberFmt,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCardHeader(int totalBarns) {
    return Row(
      children: [
        Text(
          'Ringkasan Kandang',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$totalBarns Unit Aktif',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRingsAndStats({
    required double occupancyProgress,
    required double survivalProgress,
    required double feedProgress,
    required Color colorOccupancy,
    required Color colorSurvival,
    required Color colorFeed,
    required int totalActiveBirds,
    required int totalCapacity,
    required double survivalPercent,
    required String feedStockStr,
    required NumberFormat numberFmt,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConcentricRadialChart(
          size: 94,
          strokeWidth: 8.0,
          ringSpacing: 3.5,
          rings: [
            ConcentricRingData(progress: occupancyProgress, color: colorOccupancy),
            ConcentricRingData(progress: survivalProgress, color: colorSurvival),
            ConcentricRingData(progress: feedProgress, color: colorFeed),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            children: [
              _buildMetricRow(
                color: colorOccupancy,
                title: 'Populasi Terisi',
                value: '${numberFmt.format(totalActiveBirds)} / ${numberFmt.format(totalCapacity)} ekor',
              ),
              const SizedBox(height: 7),
              _buildMetricRow(
                color: colorSurvival,
                title: 'Survival Rate',
                value: '${survivalPercent.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 7),
              _buildMetricRow(
                color: colorFeed,
                title: 'Stok Pakan',
                value: feedStockStr,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
