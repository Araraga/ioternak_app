import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../../3_schedule/cubit/schedule_cubit.dart';
import '../../3_schedule/cubit/schedule_state.dart';
import '../../3_schedule/view/schedule_page.dart';

class PakanCard extends StatelessWidget {
  const PakanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleCubit(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      )..fetchSchedule(),
      child: const _PakanCardView(),
    );
  }
}

class _PakanCardView extends StatelessWidget {
  const _PakanCardView();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final cubit = context.read<ScheduleCubit>();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        ).then((_) => cubit.fetchSchedule());
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.statusWarning.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.statusWarning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IoPakan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Jadwal Pakan Otomatis',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Schedule content
            BlocBuilder<ScheduleCubit, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading || state is ScheduleInitial) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.statusWarning),
                      ),
                    ),
                  );
                }

                if (state is ScheduleError) {
                  return Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.statusWarning, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Gagal memuat jadwal',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  );
                }

                if (state is ScheduleLoaded) {
                  final schedules = state.schedules;

                  if (schedules.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.statusWarning.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.statusWarning.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.schedule_rounded,
                              color: AppColors.statusWarning.withAlpha(120),
                              size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada jadwal aktif',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap untuk menambah jadwal',
                            style: GoogleFonts.inter(
                              color: AppColors.statusWarning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${schedules.length} Jadwal Aktif',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: schedules.map((entry) {
                          // Ambil hanya jam (sebelum '|') — abaikan portion
                          final timeOnly = entry.contains('|')
                              ? entry.split('|').first.trim()
                              : entry.trim();
                          // Skip entri yang bukan format jam valid
                          if (!timeOnly.contains(':')) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.statusWarning.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.statusWarning.withAlpha(80),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: AppColors.statusWarning,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeOnly,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Kelola jadwal →',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.statusWarning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
