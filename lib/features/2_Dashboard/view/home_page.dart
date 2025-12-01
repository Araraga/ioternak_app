import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';

import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

import '../../1_provisioning/view/provision_page.dart';
import '../widgets/sensor_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(
        storageService: context.read<StorageService>(),
      )..checkDevices(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maggenzim IoT Kandang',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.statusDanger),
            tooltip: 'Reset Aplikasi',
            onPressed: () {
              context.read<DashboardCubit>().clearAllDevices();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(
              builder: (_) => const ProvisionPage()))
              .then((_) {
            context.read<DashboardCubit>().checkDevices();
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is DashboardLoaded) {
            if (!state.hasSensorDevice && !state.hasPakanDevice) {
              return const Center(
                child: Text(
                  'Belum ada perangkat terhubung.\nTekan tombol (+) untuk menambah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (state.hasSensorDevice)
                  const SensorCard(),
                const SizedBox(height: 16),

                if (state.hasPakanDevice)
                  const Text("TODO: Tampilkan PakanCard di sini"),
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
    );
  }
}