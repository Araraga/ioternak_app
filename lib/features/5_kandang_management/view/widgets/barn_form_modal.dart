import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../6_weather/cubit/weather_cubit.dart';
import '../../cubit/barn_cubit.dart';

void showBarnFormModal(BuildContext context, {Map<String, dynamic>? existingBarn}) {
  final isEditing = existingBarn != null;
  final nameCtrl = TextEditingController(text: existingBarn?['barn_name'] ?? existingBarn?['name'] ?? '');
  final capCtrl = TextEditingController(text: existingBarn?['capacity']?.toString() ?? '');
  final locCtrl = TextEditingController(text: existingBarn?['location'] ?? '');
  String selectedType = existingBarn?['animal_type'] ?? existingBarn?['type'] ?? 'Broiler';

  double? latitude = double.tryParse(existingBarn?['latitude']?.toString() ?? '');
  double? longitude = double.tryParse(existingBarn?['longitude']?.toString() ?? '');
  bool isFetchingGps = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_location_rounded : Icons.add_home_work_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Perbarui Data Kandang' : 'Tambah Kandang Baru',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Kelola nama, kapasitas, dan lokasi GPS kandang',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Kandang',
                      hintText: 'Contoh: Kandang Broiler Blok A',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Jenis Ternak',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Broiler', 'Layer', 'Bebek', 'Puyuh'].map((type) {
                      final isSelected = selectedType.toLowerCase() == type.toLowerCase();
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        labelStyle: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kapasitas Kandang (Ekor)',
                      hintText: 'Contoh: 5000',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GPS Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Lokasi GPS Presisi',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ambil koordinat GPS HP saat Anda di kandang untuk data cuaca real-time mikroklimat presisi.',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isFetchingGps
                                ? null
                                : () async {
                                    setModalState(() => isFetchingGps = true);
                                    try {
                                      final loc = await LocationService().getDeviceLiveLocation();
                                      if (loc != null) {
                                        setModalState(() {
                                          latitude = loc.latitude;
                                          longitude = loc.longitude;
                                          locCtrl.text = loc.formattedAddress;
                                        });
                                      }
                                    } catch (_) {}
                                    finally {
                                      setModalState(() => isFetchingGps = false);
                                    }
                                  },
                            icon: isFetchingGps
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
                            label: Text(
                              isFetchingGps ? 'Mencari Posisi GPS...' : '📍 Gunakan Lokasi GPS HP Saat Ini',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (latitude != null && longitude != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Koordinat: ${latitude?.toStringAsFixed(4)}, ${longitude?.toStringAsFixed(4)}',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: locCtrl,
                    decoration: InputDecoration(
                      labelText: 'Alamat / Lokasi Kandang',
                      hintText: 'Contoh: Sleman, D.I. Yogyakarta',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final cap = int.tryParse(capCtrl.text.trim()) ?? 0;
                        final loc = locCtrl.text.trim().isEmpty ? 'Sleman, D.I. Yogyakarta' : locCtrl.text.trim();

                        if (name.isEmpty || cap <= 0) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Nama kandang dan kapasitas wajib diisi!'),
                              backgroundColor: AppColors.statusDanger,
                            ),
                          );
                          return;
                        }

                        if (isEditing) {
                          final barnId = existingBarn['id'].toString();
                          context.read<BarnCubit>().updateBarn(
                            barnId: barnId,
                            updates: {
                              'barn_name': name,
                              'animal_type': selectedType,
                              'capacity': cap,
                              'location': loc,
                              if (latitude != null) 'latitude': latitude,
                              if (longitude != null) 'longitude': longitude,
                            },
                          );
                        } else {
                          context.read<BarnCubit>().createBarn(
                            barnName: name,
                            animalType: selectedType,
                            capacity: cap,
                            location: loc,
                            latitude: latitude,
                            longitude: longitude,
                          );
                        }

                        if (latitude != null && longitude != null) {
                          try {
                            sheetContext.read<StorageService>().saveWeatherLocation(
                              latitude.toString(),
                              longitude.toString(),
                              loc,
                            );
                            sheetContext.read<WeatherCubit>().fetchWeather(
                              latitude: latitude.toString(),
                              longitude: longitude.toString(),
                              locationName: loc,
                              useGps: false,
                            );
                          } catch (_) {}
                        }

                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? 'Simpan Perubahan' : 'Daftarkan Kandang',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
