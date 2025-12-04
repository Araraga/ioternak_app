import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'main.dart';
import 'core/constants/app_colors.dart';

class AppView extends StatelessWidget {
  final Widget initialPage;

  const AppView({super.key, required this.initialPage});

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
