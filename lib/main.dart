import 'package:flutter/material.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'app_view.dart';

final storageService = StorageService();
final apiService = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await storageService.init();

  runApp(const AppView());
}
