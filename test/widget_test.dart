// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_restaurant/main.dart';
import 'package:app_restaurant/core/di/dependency_injection.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Inicializar dependencias
    final di = DependencyInjection();
    await di.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(di: di));

    // Verify that LoginPage is shown (should see "Bienvenido")
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}