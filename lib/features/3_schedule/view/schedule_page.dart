import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Portion options definition without technical jargon
  final List<Map<String, dynamic>> _portions = [
    {
      'id': 'sedikit',
      'label': 'Sedikit',
      'dots': 1,
      'color': const Color(0xFF4FC3F7),
    },
    {
      'id': 'sedang',
      'label': 'Sedang',
      'dots': 2,
      'color': AppColors.primary,
    },
    {
      'id': 'banyak',
      'label': 'Banyak',
      'dots': 3,
      'color': const Color(0xFFFFB300),
    },
  ];

  Widget _buildCrumbleIcon(int dots, Color color, bool isSelected) {
    final c = isSelected ? color : AppColors.textSecondary;
    if (dots == 1) {
      return Icon(Icons.circle, size: 12, color: c);
    } else if (dots == 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: c),
          const SizedBox(width: 2),
          Icon(Icons.circle, size: 12, color: c),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: c),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 12, color: c),
              const SizedBox(width: 2),
              Icon(Icons.circle, size: 12, color: c),
            ],
          ),
        ],
      );
    }
  }

  Future<void> _addSchedule() async {
    final scheduleCubit = context.read<ScheduleCubit>();
    DateTime tempPickedTime = DateTime.now();
    String selectedDialogPortion = 'sedang';

    await showDialog(
      context: context,
      builder: (BuildContext builderContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_alarm_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Tambah Jadwal Pakan",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Time Picker Section Title
                      Text(
                        "Pilih Waktu",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cupertino Time Picker
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGradientStart.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        child: CupertinoTheme(
                          data: const CupertinoThemeData(
                            brightness: Brightness.light,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
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

                      const SizedBox(height: 20),

                      // Portion Selector Section Title inside Dialog
                      Text(
                        "Kuantitas Porsi Pakan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Portion Selector Chips inside Dialog
                      Row(
                        children: _portions.map((portion) {
                          final bool isSelected =
                              selectedDialogPortion == portion['id'];
                          final Color cardColor = portion['color'] as Color;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedDialogPortion = portion['id'] as String;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cardColor.withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? cardColor
                                        : Colors.grey.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 28,
                                      alignment: Alignment.center,
                                      child: _buildCrumbleIcon(portion['dots'] as int, cardColor, isSelected),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      portion['label'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? cardColor
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Dialog Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.textLight.withOpacity(0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                "Batal",
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final String formattedTime =
                                    '${tempPickedTime.hour.toString().padLeft(2, '0')}:${tempPickedTime.minute.toString().padLeft(2, '0')}|$selectedDialogPortion';
                                setState(() {
                                  _currentSchedules.removeWhere((s) => s.split('|')[0] == formattedTime.split('|')[0]);
                                  _currentSchedules.add(formattedTime);
                                  _currentSchedules.sort();
                                });
                                scheduleCubit.updateSchedule(_currentSchedules);
                                Navigator.pop(dialogContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                "Simpan",
                                style: GoogleFonts.plusJakartaSans(
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
      },
    );
  }

  void _deleteDevice(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hapus Alat Pakan?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Alat IoPakan ini akan dihapus dari akun Anda.",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Batal",
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
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
                      backgroundColor: AppColors.statusDanger,
                    ),
                  );
                }
              }
            },
            child: Text("Hapus Alat",
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getPortionLabel(String portionId) {
    switch (portionId.toLowerCase()) {
      case 'sedikit':
        return 'Sedikit';
      case 'banyak':
        return 'Banyak';
      case 'sedang':
      default:
        return 'Sedang';
    }
  }

  /// Ekstrak {time, portion} dari string "HH:mm|portion".
  /// Jika formatnya tidak valid, kembalikan null.
  ({String time, String portion})? _parseScheduleEntry(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Format normal: "HH:mm|portion"
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      final time = parts[0].trim();
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time)) {
        return (time: time, portion: parts.length > 1 ? parts[1].trim() : 'sedang');
      }
    }

    // Format lama: "HH:mm" saja (tanpa portion)
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmed)) {
      return (time: trimmed, portion: 'sedang');
    }

    // Format tidak dikenal (mis. Map.toString() yang bocor) → abaikan
    return null;
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
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jadwal tersimpan!',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
        } else if (state is ScheduleError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan: ${state.message}'),
                backgroundColor: AppColors.statusDanger,
                behavior: SnackBarBehavior.floating,
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

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.homeBackground,
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  'IoPakan',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.statusDanger,
                        size: 20,
                      ),
                    ),
                    tooltip: "Hapus Alat",
                    onPressed: () => _deleteDevice(context),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Device Image centered below title without card
                      Center(
                        child: Container(
                          height: 170,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: Image.asset(
                            'assets/icon/iopakan.png',
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.pets_rounded,
                              size: 64,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section Title: Schedule List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Waktu Pemberian Pakan",
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_currentSchedules.length} Jadwal",
                              style: GoogleFonts.inter(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Schedule Items or Empty State
                      _buildScheduleSection(context, state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Schedule Section 
  Widget _buildScheduleSection(BuildContext context, ScheduleState state) {
    if (state is ScheduleLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is ScheduleError && _currentSchedules.isEmpty) {
      return SensorErrorWidget(
        message: state.message,
        onRetry: () => context.read<ScheduleCubit>().fetchSchedule(),
      );
    }

    return Column(
      children: [
        if (_currentSchedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.alarm_off_rounded,
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 12),
                Text(
                  "Belum Ada Jadwal Pakan",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tambahkan waktu pemberian pakan otomatis.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentSchedules.length,
            itemBuilder: (context, index) {
              final rawEntry   = _currentSchedules[index];
              final parsed     = _parseScheduleEntry(rawEntry);

              // Lewati entri yang formatnya tidak valid
              if (parsed == null) return const SizedBox.shrink();

              final String time    = parsed.time;
              final String portion = parsed.portion;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  subtitle: Text(
                    "Porsi: ${_getPortionLabel(portion)}",
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.statusDanger,
                        size: 20,
                      ),
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
          ),

        const SizedBox(height: 14),

        // Add Schedule Button
        InkWell(
          onTap: _addSchedule,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  "Tambah Jam Pakan Baru",
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

