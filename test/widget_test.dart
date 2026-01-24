import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Opción A (si tu name es correcto):
import 'package:sistemabodega/main.dart';

// Opción B (si prefieres no depender del name):
// import '../lib/main.dart';

void main() {
  testWidgets('App opens without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
