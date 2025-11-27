import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'main.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';

import 'core/constants/app_colors.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: apiService,
        ),
        RepositoryProvider.value(
          value: storageService,
        ),
      ],
      child: MaterialApp(
        title: 'Smart Kandang IoT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: AppColors.background,
          cardColor: AppColors.card,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: AppColors.card,
            centerTitle: true,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}