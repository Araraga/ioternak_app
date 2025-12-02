import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import service global dari main.dart
import 'main.dart';
import 'core/constants/app_colors.dart';

class AppView extends StatelessWidget {
  // Terima halaman awal sebagai parameter
  final Widget initialPage;

  const AppView({
    super.key,
    required this.initialPage, // Wajib diisi
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiService),
        RepositoryProvider.value(value: storageService),
      ],
      child: MaterialApp(
        title: 'Smart Kandang IoT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Gunakan AppColors.background sebagai warna dasar Scaffold
          scaffoldBackgroundColor: AppColors.background,
          // Skema warna utama
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            background: AppColors.background,
          ),
          useMaterial3: true,
          // Tema Font dan Elemen lain bisa ditambahkan di sini
        ),

        // [PENTING] Gunakan halaman yang sudah ditentukan di main.dart
        home: initialPage,
      ),
    );
  }
}
