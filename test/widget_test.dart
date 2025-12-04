import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ioternak_app/app_view.dart';

void main() {
  testWidgets('App render smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AppView(initialPage: Scaffold()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
