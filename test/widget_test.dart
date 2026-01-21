import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import file proyek Anda
import 'package:ioternak_app/app_view.dart';
import 'package:ioternak_app/core/services/api_service.dart';
import 'package:ioternak_app/core/services/storage_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 1. Mock SharedPreferences (Penting agar StorageService tidak crash saat test)
    SharedPreferences.setMockInitialValues({});

    // 2. Inisialisasi Service Palsu/Asli untuk keperluan test
    final storageService = StorageService();
    await storageService.init(); // Init storage dengan mock values

    final apiService = ApiService();

    // 3. Build AppView dengan parameter yang dibutuhkan
    await tester.pumpWidget(
      AppView(
        // Kita masukkan halaman dummy (Container) saja untuk test agar tidak error navigasi
        initialPage: const Scaffold(body: Center(child: Text('Test Page'))),
        apiService: apiService,
        storageService: storageService,
      ),
    );

    // 4. Verifikasi bahwa aplikasi berhasil dirender (mencari teks 'Test Page')
    expect(find.text('Test Page'), findsOneWidget);
  });
}
