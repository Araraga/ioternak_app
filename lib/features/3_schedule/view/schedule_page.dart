import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../2_dashboard/widgets/sensor_error.dart'; // Kita pakai ulang error widget
import '../cubit/schedule_cubit.dart';
import '../cubit/schedule_state.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleCubit(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      )..fetchSchedule(),
      child: const ScheduleView(),
    );
  }
}

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  // State lokal untuk menampung jadwal yang sedang diedit
  List<String> _currentSchedules = [];

  // Fungsi untuk menambah jadwal baru
  Future<void> _addSchedule() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final String formattedTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

      setState(() {
        if (!_currentSchedules.contains(formattedTime)) {
          _currentSchedules.add(formattedTime);
          _currentSchedules.sort();
        }
      });
    }
  }

  // Fungsi untuk menyimpan perubahan ke server
  void _saveSchedules(BuildContext context, ScheduleState state) {
    if (state is ScheduleUpdating) return;
    context.read<ScheduleCubit>().updateSchedule(_currentSchedules);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleCubit, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleUpdateSuccess) {
          // Sinkronkan state lokal dengan state dari server
          setState(() {
            _currentSchedules = List<String>.from(state.newSchedules);
            _currentSchedules.sort();
          });
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Jadwal berhasil diperbarui!'),
                backgroundColor: AppColors.statusGood,
              ),
            );
        } else if (state is ScheduleError) {
          // Tampilkan error jika gagal *update*
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan: ${state.message}'),
                backgroundColor: AppColors.statusDanger,
              ),
            );
        }
      },
      child: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleLoaded && _currentSchedules.isEmpty) {
            _currentSchedules = List<String>.from(state.schedules);
            _currentSchedules.sort();
          }
          bool isSaving = state is ScheduleUpdating;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Atur Jadwal Pakan'),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => _saveSchedules(context, state),
                  child: isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'SIMPAN',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            floatingActionButton: FloatingActionButton(
              onPressed: _addSchedule,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_alarm),
            ),

            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  /// Helper widget untuk membangun body berdasarkan state
  Widget _buildBody(BuildContext context, ScheduleState state) {
    // 1. Saat loading awal
    if (state is ScheduleLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    // 2. Saat error load awal
    if (state is ScheduleError && _currentSchedules.isEmpty) {
      return SensorErrorWidget(
        message: state.message,
        onRetry: () => context.read<ScheduleCubit>().fetchSchedule(),
      );
    }

    // 3. Saat data ada (Loaded, Updating, Success)
    // atau jika list lokal kosong
    if (_currentSchedules.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada jadwal.\nTekan tombol (+) untuk menambah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    // Tampilkan daftar jadwal
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _currentSchedules.length,
      itemBuilder: (context, index) {
        final time = _currentSchedules[index];
        return Card(
          color: AppColors.card,
          child: ListTile(
            leading: const Icon(Icons.alarm, color: AppColors.primary),
            title: Text(
              time,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Pemberian pakan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.statusDanger),
              onPressed: () {
                // Hapus dari list lokal
                setState(() {
                  _currentSchedules.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}