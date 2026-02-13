import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../2_dashboard/widgets/sensor_error.dart';
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
  List<String> _currentSchedules = [];
  bool _isDataLoaded = false;

  Future<void> _addSchedule() async {
    DateTime tempPickedTime = DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext builderContext) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Pilih Waktu",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.dark,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        initialDateTime: DateTime.now(),
                        onDateTimeChanged: (DateTime newTime) {
                          tempPickedTime = newTime;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final String formattedTime =
                                '${tempPickedTime.hour.toString().padLeft(2, '0')}:${tempPickedTime.minute.toString().padLeft(2, '0')}';
                            setState(() {
                              if (!_currentSchedules.contains(formattedTime)) {
                                _currentSchedules.add(formattedTime);
                                _currentSchedules.sort();
                              }
                            });
                            context.read<ScheduleCubit>().updateSchedule(
                              _currentSchedules,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Simpan",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteDevice(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Alat Pakan?"),
        content: const Text("Alat akan dihapus dari akun Anda."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final storage = context.read<StorageService>();
                final api = context.read<ApiService>();
                final deviceId = storage.getPakanId();
                final userId = storage.getUserIdFromDB();

                if (deviceId != null && userId != null) {
                  await api.releaseDevice(deviceId, userId);
                }
                await storage.clearPakanId();

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleCubit, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleUpdateSuccess) {
          setState(() {
            _currentSchedules = List<String>.from(state.newSchedules);
            _currentSchedules.sort();
          });
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Jadwal tersimpan otomatis!'),
                backgroundColor: AppColors.statusGood,
                duration: Duration(seconds: 1),
              ),
            );
        } else if (state is ScheduleError) {
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
          if (state is ScheduleLoaded) {
            _currentSchedules = List<String>.from(state.schedules);
            _currentSchedules.sort();
          } else if (state is ScheduleUpdateSuccess) {
            _currentSchedules = List<String>.from(state.newSchedules);
            _currentSchedules.sort();
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'IoTernak Smart Pakan',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.statusDanger,
                  ),
                  tooltip: "Hapus Alat",
                  onPressed: () => _deleteDevice(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
                Center(
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/alatpakan.png',
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.pets,
                        size: 50,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Daftar Waktu Pemberian Pakan",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ScheduleState state) {
    if (state is ScheduleLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state is ScheduleError && !_isDataLoaded) {
      return Center(
        child: SensorErrorWidget(
          message: state.message,
          onRetry: () => context.read<ScheduleCubit>().fetchSchedule(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      itemCount: _currentSchedules.length + 1,
      itemBuilder: (context, index) {
        if (index == _currentSchedules.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: InkWell(
              onTap: _addSchedule,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.grey, size: 32),
                ),
              ),
            ),
          );
        }

        final time = _currentSchedules[index];
        return Card(
          color: AppColors.card,
          margin: const EdgeInsets.only(bottom: 12),
          // HAPUS ELEVATION (SHADOW)
          elevation: 0,
          // GANTI DENGAN BORDER
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_filled,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              time,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.statusDanger,
              ),
              onPressed: () {
                setState(() {
                  _currentSchedules.removeAt(index);
                });
                context.read<ScheduleCubit>().updateSchedule(_currentSchedules);
              },
            ),
          ),
        );
      },
    );
  }
}
