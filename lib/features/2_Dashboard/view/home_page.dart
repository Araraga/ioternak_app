import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';

import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

import '../../1_provisioning/view/provision_page.dart';
import '../widgets/sensor_card.dart';
import '../widgets/pakan_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardCubit(storageService: context.read<StorageService>())
            ..checkDevices(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Hitung Padding Atas agar konten muncul pas DI BAWAH AppBar
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = statusBarHeight + kToolbarHeight + 10.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Kandang Saya',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // [PERUBAHAN 1] Icon Logout DIGANTI dengan Icon Plus (+)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 32,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            tooltip: 'Tambah Perangkat',
            onPressed: () {
              // Logika pindah ke halaman Provisioning
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const ProvisionPage()),
                  )
                  .then((_) {
                    context.read<DashboardCubit>().checkDevices();
                  });
            },
          ),
          const SizedBox(width: 8), // Sedikit jarak dari kanan
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          image: DecorationImage(
            image: const AssetImage('assets/images/homebackground.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.05),
              BlendMode.darken,
            ),
          ),
        ),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is DashboardLoaded) {
              // Hitung jumlah perangkat aktif
              int deviceCount = 0;
              if (state.hasSensorDevice) deviceCount++;
              if (state.hasPakanDevice) deviceCount++;

              return ListView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 40),
                children: [
                  // --- 1. HEADER (NAMA USER) ---
                  // Tombol bulat besar (+) dihapus karena sudah pindah ke AppBar
                  const SizedBox(height: 10),

                  // Nama User (Placeholder)
                  // [FITUR TAMBAHAN] Tekan lama tulisan ini untuk Reset/Logout
                  InkWell(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Reset Aplikasi?"),
                          content: const Text(
                            "Data perangkat akan dihapus dari aplikasi ini.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Batal"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context
                                    .read<DashboardCubit>()
                                    .clearAllDevices();
                              },
                              child: const Text(
                                "Reset",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Halo, Peternak',
                      style: TextStyle(
                        fontSize: 30, // Ukuran Besar
                        fontWeight: FontWeight.bold, // Tebal
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Jumlah Device
                  Text(
                    '$deviceCount Perangkat',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 50), // Jarak ke Kartu

                  // --- 2. DAFTAR KARTU ---
                  if (deviceCount == 0)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          138,
                          138,
                          138,
                        ).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Belum ada perangkat.\nTekan (+) di pojok kanan atas untuk menambahkan.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),

                  // Kartu Sensor
                  if (state.hasSensorDevice) ...[
                    const SensorCard(),
                    const SizedBox(height: 16),
                  ],

                  // Kartu Pakan
                  if (state.hasPakanDevice) const PakanCard(),
                ],
              );
            }

            return const Center(
              child: Text(
                'Gagal memuat status perangkat.',
                style: TextStyle(color: AppColors.statusDanger),
              ),
            );
          },
        ),
      ),
    );
  }
}
