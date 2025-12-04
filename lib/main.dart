import 'package:flutter/material.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'app_view.dart';
import 'features/0_splash/view/onboarding_page.dart';
import 'features/0_splash/view/login_page.dart';
import 'features/2_dashboard/view/home_page.dart';

final storageService = StorageService();
final apiService = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await storageService.init();

  Widget startPage;

  final bool isOnboardingDone = storageService.isOnboardingComplete();
  final String? userName = storageService.getUserName();

  if (!isOnboardingDone) {
    startPage = const OnboardingPage();
  } else if (userName == null || userName.isEmpty) {
    startPage = const LoginPage();
  } else {
    startPage = const HomePage();
  }

  runApp(AppView(initialPage: startPage));
}
