import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(const BarcodeScannerApp());

class BarcodeScannerApp extends StatelessWidget {
  const BarcodeScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Small Barcode Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const <BarcodeFormat>[
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf14,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
    ],
  );

  Barcode? _lastBarcode;
  DateTime? _scannedAt;
  double _zoom = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    Barcode? barcode;
    for (final item in capture.barcodes) {
      if (item.rawValue?.trim().isNotEmpty ?? false) {
        barcode = item;
        break;
      }
    }

    if (barcode == null || barcode.rawValue == _lastBarcode?.rawValue) return;
    setState(() {
      _lastBarcode = barcode;
      _scannedAt = DateTime.now();
    });
  }

  void _clearResult() {
    setState(() {
      _lastBarcode = null;
      _scannedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07130F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07130F),
        title: const Text('ทดสอบสแกนบาร์โค้ด'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final Size size = constraints.biggest;
                      final Rect scanWindow = Rect.fromCenter(
                        center: size.center(Offset.zero),
                        width: size.width * .82,
                        height: 128,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          MobileScanner(
                            controller: _controller,
                            scanWindow: scanWindow,
                            onDetect: _handleDetection,
                            errorBuilder: (context, error) => _CameraError(
                              message:
                                  error.errorDetails?.message ??
                                  'ไม่สามารถเปิดกล้องได้',
                            ),
                          ),
                          CustomPaint(
                            painter: _ScannerOverlayPainter(scanWindow),
                          ),
                          const Positioned(
                            left: 24,
                            right: 24,
                            top: 18,
                            child: Text(
                              'วางบาร์โค้ดให้อยู่ในกรอบ แล้วค่อย ๆ เลื่อนกล้องเข้าใกล้',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: <Shadow>[
                                  Shadow(blurRadius: 8, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 10,
                            child: _CameraControls(
                              controller: _controller,
                              zoom: _zoom,
                              onZoomChanged: (value) {
                                setState(() => _zoom = value);
                                unawaited(_controller.setZoomScale(value));
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            BarcodeResultPanel(
              barcode: _lastBarcode,
              scannedAt: _scannedAt,
              onClear: _clearResult,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  const _CameraControls({
    required this.controller,
    required this.zoom,
    required this.onZoomChanged,
  });

  final MobileScannerController controller;
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'เปิด/ปิดไฟฉาย',
              onPressed: controller.toggleTorch,
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
            const Icon(Icons.zoom_out, size: 20),
            Expanded(
              child: Slider(value: zoom, onChanged: onZoomChanged),
            ),
            const Icon(Icons.zoom_in, size: 20),
            IconButton(
              tooltip: 'สลับกล้อง',
              onPressed: controller.switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class BarcodeResultPanel extends StatelessWidget {
  const BarcodeResultPanel({
    super.key,
    required this.barcode,
    required this.scannedAt,
    required this.onClear,
  });

  final Barcode? barcode;
  final DateTime? scannedAt;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final String? value = barcode?.rawValue;
    final String type = barcode?.format.name.toUpperCase() ?? '';
    final String time = scannedAt == null
        ? ''
        : '${scannedAt!.hour.toString().padLeft(2, '0')}:'
              '${scannedAt!.minute.toString().padLeft(2, '0')}:'
              '${scannedAt!.second.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10271F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B765C)),
      ),
      child: value == null
          ? const Column(
              children: <Widget>[
                Icon(Icons.barcode_reader, size: 34, color: Color(0xFF72D6B1)),
                SizedBox(height: 8),
                Text('ยังไม่พบบาร์โค้ด', key: Key('empty-result')),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle, color: Color(0xFF72D6B1)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('อ่านสำเร็จ • $type • $time')),
                    IconButton(
                      tooltip: 'ล้างผลลัพธ์',
                      onPressed: onClear,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  value,
                  key: const Key('barcode-value'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF20100E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$message\n\nกรุณาอนุญาตให้แอปเข้าถึงกล้องใน Settings',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shade = Paint()..color = Colors.black.withValues(alpha: .38);
    final Path outside = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, shade);

    final Paint border = Paint()
      ..color = const Color(0xFF72D6B1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(16)),
      border,
    );

    final Paint line = Paint()
      ..color = const Color(0xFFE8FF3D)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(window.left + 16, window.center.dy),
      Offset(window.right - 16, window.center.dy),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.window != window;
  }
}
