import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../6_weather/cubit/weather_cubit.dart';
import '../cubit/barn_cubit.dart';
import '../cubit/barn_state.dart';
import 'widgets/live_weather_card.dart';
import 'widgets/executive_dashboard_kpi.dart';
import 'widgets/barn_card.dart';
import 'widgets/barn_form_modal.dart';

class KandangManagementPage extends StatelessWidget {
  const KandangManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final storage = context.read<StorageService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BarnCubit(api: api, storage: storage)..fetchBarns(),
        ),
        BlocProvider(
          create: (_) => WeatherCubit(
            apiService: api,
            storage: storage,
          )..fetchWeather(useGps: false),
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

class _KandangManagementViewState extends State<KandangManagementView> {
  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<BarnCubit, BarnState>(
          listener: (context, state) {
            if (state is BarnError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.statusDanger,
                ),
              );
            } else if (state is BarnLoaded && state.barns.isNotEmpty) {
              final barnWithCoord = state.barns.firstWhere(
                (b) => b['latitude'] != null && b['longitude'] != null,
                orElse: () => null,
              );
              if (barnWithCoord != null) {
                final lat = barnWithCoord['latitude'].toString();
                final lon = barnWithCoord['longitude'].toString();
                final loc = barnWithCoord['location']?.toString() ??
                    barnWithCoord['barn_name']?.toString() ??
                    '';
                context.read<WeatherCubit>().fetchWeather(
                  latitude: lat,
                  longitude: lon,
                  locationName: loc,
                  useGps: false,
                );
              }
            }
          },
          builder: (context, barnState) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await context.read<BarnCubit>().fetchBarns();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(dateStr),
                    const SizedBox(height: 18),
                    const LiveWeatherCard(),
                    const SizedBox(height: 20),
                    ExecutiveDashboardKpi(barnState: barnState),
                    const SizedBox(height: 22),
                    _buildBarnList(barnState, context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(String dateString) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manajemen Kandang',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateString,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBarnList(BarnState barnState, BuildContext context) {
    if (barnState is BarnLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (barnState is BarnLoaded) {
      if (barnState.barns.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Kandang (${barnState.barns.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showBarnFormModal(context),
                icon: const Icon(Icons.add_location_alt_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Tambah Kandang',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...barnState.barns.map(
            (b) => BarnCard(
              key: ValueKey(b['id'] ?? b['barn_id'] ?? b.hashCode),
              barn: Map<String, dynamic>.from(b),
              onEdit: (barnData) => showBarnFormModal(context, existingBarn: barnData),
              onDelete: (id, name) => _confirmDeleteBarn(context, id, name),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_home_work_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Kandang Terdaftar',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tambahkan kandang pertama Anda dan manfaatkan GPS untuk data cuaca real-time yang akurat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showBarnFormModal(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Daftarkan Kandang',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBarn(BuildContext context, int barnId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Kandang?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "$name"? Semua data flock, tugas, dan keuangan terkait juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              context.read<BarnCubit>().deleteBarn(barnId.toString());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
