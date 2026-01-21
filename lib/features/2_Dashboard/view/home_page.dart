import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart'; // Import API Service

import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

import '../../0_splash/view/onboarding_page.dart';
import '../../1_provisioning/view/provision_page.dart';
import '../../4_profile/view/profile_page.dart';
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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Panggil fungsi sinkronisasi saat halaman dimuat
    _syncDevices();
  }

  /// Fungsi untuk mengambil data device dari server dan menyimpannya ke lokal
  /// Ini memperbaiki masalah device hilang saat logout/login
  Future<void> _syncDevices() async {
    try {
      final storage = context.read<StorageService>();
      final api = context.read<ApiService>();
      final userId = storage.getUserIdFromDB();

      if (userId != null) {
        // 1. Ambil data terbaru dari server
        final devices = await api.getMyDevices(userId);

        // 2. Simpan kembali ke Storage Lokal (Restore Session)
        bool dataChanged = false;
        for (var device in devices) {
          if (device['type'] == 'sensor') {
            await storage.saveSensorId(device['device_id']);
            dataChanged = true;
          } else if (device['type'] == 'feeder') {
            await storage.savePakanId(device['device_id']);
            dataChanged = true;
          }
        }

        // 3. Refresh Tampilan Dashboard jika ada data baru
        if (dataChanged && mounted) {
          context.read<DashboardCubit>().checkDevices();
        }
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = statusBarHeight + kToolbarHeight + 10.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Kandang Saya',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 32,
              color: AppColors.primary,
            ),
            tooltip: 'Tambah Perangkat',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const ProvisionPage()),
                  )
                  .then((_) {
                    context.read<DashboardCubit>().checkDevices();
                    // Sync ulang setelah tambah alat
                    _syncDevices();
                  });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          image: DecorationImage(
            image: const AssetImage('assets/images/background.png'),
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
              int deviceCount = 0;
              if (state.hasSensorDevice) deviceCount++;
              if (state.hasPakanDevice) deviceCount++;

              return ListView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 40),
                children: [
                  const SizedBox(height: 45),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      ).then((_) {
                        context.read<DashboardCubit>().checkDevices();
                      });
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Reset Aplikasi?"),
                          content: const Text("Semua data lokal akan dihapus."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Batal"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await context
                                    .read<StorageService>()
                                    .clearAllData();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text(
                                "Reset Total",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo,',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),

                        const SizedBox(height: 0),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                state.userName,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 20,
                              color: Color.fromARGB(255, 53, 53, 53),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$deviceCount Perangkat Terhubung',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 50),

                  if (deviceCount == 0)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.devices,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Belum ada perangkat.\nTekan ikon (+) di pojok kanan atas untuk menambahkan.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                  if (state.hasSensorDevice) ...[
                    const SensorCard(),
                    const SizedBox(height: 16),
                  ],

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
