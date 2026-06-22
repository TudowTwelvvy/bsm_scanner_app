import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../auth/data/auth_repository_provider.dart';
import '../data/product_repository.dart';
import '../domain/product_entity.dart';

// WHY: ConsumerStatefulWidget because we need:
// 1. State (hasScanned flag, controller lifecycle)
// 2. Riverpod access (ref.read to save product)
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  // MobileScannerController is the "brain" of the camera in v7.
  // It manages: start, stop, torch, camera switching, and barcode stream.
  final MobileScannerController _controller = MobileScannerController();

  // StreamSubscription is like a radio antenna. We MUST unplug it in dispose()
  // or it stays connected forever, causing memory leaks and duplicate scans.
  StreamSubscription<BarcodeCapture>? _subscription;

  // Prevents saving the same barcode 50 times in one second while
  // the user holds the camera steady.
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    // v7 BREAKING CHANGE: You MUST manually start the camera.
    // Older versions auto-started. v7 does not.
    _controller.start();

    // v7 BREAKING CHANGE: No 'onDetect' parameter on the widget.
    // Instead, we listen to the controller's built-in barcode stream.
    _subscription = _controller.barcodes.listen(_onBarcodeDetected);
  }

  @override
  void dispose() {
    // CRITICAL ORDER: Cancel stream FIRST, then dispose controller.
    // If you dispose first, the stream listener might crash trying to
    // access a dead controller.
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ─── BARCODE DETECTED ───
  void _onBarcodeDetected(BarcodeCapture capture) {
    // _hasScanned is our "lock". Once true, we ignore all further detections
    // until the user taps "Scan Another".
    if (_hasScanned || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop(); // Stop camera to save battery and prevent duplicates
    
    _showSaveDialog(barcode);
  }

  // ─── SAVE DIALOG ───
  void _showSaveDialog(Barcode barcode) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // User MUST tap a button. Tapping outside won't close it.
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Scan Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Don't stretch vertically
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              barcode.rawValue!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Type: ${barcode.type.name}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Add notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          // CANCEL: Don't save, resume scanning
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _resetScanner();       // Turn camera back on
            },
            child: const Text('Cancel'),
          ),
          // SAVE: Send to API, then resume scanning
          ElevatedButton(
            onPressed: () async {
              await _saveScan(barcode, notesController.text.trim());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan saved!')),
                );
                _resetScanner();
              }
            },
            child: const Text('Save Scan'),
          ),
        ],
      ),
    );
  }

  // ─── SAVE TO API ───
  Future<void> _saveScan(Barcode barcode, String? notes) async {
    // Get the current user from the auth stream.
    // valueOrNull = the latest emitted value, or null if stream hasn't emitted yet.
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return; // Should never happen (router guards this)

    final product = ProductEntity(
      id: 0, // API assigns the real ID (auto-increment)
      barcode: barcode.rawValue!,
      barcodeType: barcode.type.name,
      notes: notes?.isEmpty == true ? null : notes,
      scannedAt: DateTime.now(),
      userId: user.id, // Guid string from JWT
    );

    // ref.read (not watch) because we only need to call a method once.
    await ref.read(productRepositoryProvider).saveProduct(product);
  }

  void _resetScanner() {
    setState(() => _hasScanned = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          // Torch toggle: reads controller state via ValueListenableBuilder
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Switch front/back camera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand, // Fill entire screen
        children: [
          MobileScanner(controller: _controller),
          // Dark overlay with cutout square
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at a barcode or QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SCAN OVERLAY PAINTER ───
// WHY: CustomPainter draws directly on the GPU canvas. This is smoother
// than stacking 20 Container widgets with borders.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    // Scan window is a square centered on screen, 75% of width
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.width * 0.75,
    );

    // Draw "screen minus scan window" = darkened area around the cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12))),
      ),
      paint,
    );

    // White corner brackets so user knows where to aim
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Draw 8 lines (2 per corner) to form brackets
    _drawCorner(canvas, scanArea.topLeft, cornerLength, cornerPaint, true, true);
    _drawCorner(canvas, scanArea.topRight, cornerLength, cornerPaint, false, true);
    _drawCorner(canvas, scanArea.bottomLeft, cornerLength, cornerPaint, true, false);
    _drawCorner(canvas, scanArea.bottomRight, cornerLength, cornerPaint, false, false);
  }

  void _drawCorner(Canvas canvas, Offset corner, double length, Paint paint,
      bool right, bool down) {
    canvas.drawLine(
      corner,
      corner + Offset(right ? length : -length, 0),
      paint,
    );
    canvas.drawLine(
      corner,
      corner + Offset(0, down ? length : -length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}