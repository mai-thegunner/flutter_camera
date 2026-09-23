import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:trying_flutter/main.dart';

void main() {
  Widget testApp({Barcode? barcode}) {
    return MaterialApp(
      home: Scaffold(
        body: BarcodeResultPanel(
          barcode: barcode,
          scannedAt: DateTime(2026, 9, 23, 14, 5, 9),
          onClear: () {},
        ),
      ),
    );
  }

  testWidgets('shows an empty state before scanning', (tester) async {
    await tester.pumpWidget(testApp());
    expect(find.byKey(const Key('empty-result')), findsOneWidget);
    expect(find.text('ยังไม่พบบาร์โค้ด'), findsOneWidget);
  });

  testWidgets('shows a detected barcode value', (tester) async {
    await tester.pumpWidget(
      testApp(
        barcode: Barcode(
          rawValue: '8851234567890',
          format: BarcodeFormat.ean13,
        ),
      ),
    );

    expect(find.byKey(const Key('barcode-value')), findsOneWidget);
    expect(find.text('8851234567890'), findsOneWidget);
    expect(find.textContaining('EAN13'), findsOneWidget);
  });
}
