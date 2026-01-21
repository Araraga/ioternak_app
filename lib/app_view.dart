import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Hapus import main.dart karena kita tidak butuh variabel global lagi
// import 'main.dart';
import 'core/services/api_service.dart'; // Import tipe data Service
import 'core/services/storage_service.dart'; // Import tipe data Service
import 'core/constants/app_colors.dart';

class AppView extends StatelessWidget {
  final Widget initialPage;
  final ApiService apiService; // Tambahkan ini
  final StorageService storageService; // Tambahkan ini

  const AppView({
    super.key,
    required this.initialPage,
    required this.apiService, // Wajib diisi
    required this.storageService, // Wajib diisi
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Gunakan variabel lokal dari class ini
        RepositoryProvider.value(value: apiService),
        RepositoryProvider.value(value: storageService),
      ],
      child: MaterialApp(
        title: 'Smart Kandang IoT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            background: AppColors.background,
          ),
          useMaterial3: true,
        ),
        home: initialPage,
      ),
    );
  }
}
