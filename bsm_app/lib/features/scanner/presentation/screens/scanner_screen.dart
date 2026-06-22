import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../auth/data/auth_repository_provider.dart';
import '../../data/product_repository.dart';
import '../../domain/product_entity.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _hasScanned = false;
  bool _isCameraReady = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller.start();
    _subscription = _controller.barcodes.listen(_onBarcodeDetected);
    setState(() {
      _isCameraReady = true;
      _hasScanned = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    _showSaveDialog(barcode);
  }

  void _showSaveDialog(Barcode barcode) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Scan Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _scheduleCameraRestart();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _saveScan(barcode, notesController.text.trim());
                // Guard ALL context usages after await with mounted check
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan saved!')),
                );
                _scheduleCameraRestart();
              } catch (e) {
                // Guard ALL context usages after await with mounted check
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
                _scheduleCameraRestart();
              }
            },
            child: const Text('Save Scan'),
          ),
        ],
      ),
    );
  }

  void _scheduleCameraRestart() {
    setState(() => _isCameraReady = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resetScanner();
      }
    });
  }

  Future<void> _saveScan(Barcode barcode, String? notes) async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) return;

    final product = ProductEntity(
      id: 0,
      barcode: barcode.rawValue!,
      barcodeType: barcode.type.name,
      notes: notes?.isEmpty == true ? null : notes,
      scannedAt: DateTime.now(),
      userId: user.id,
    );

    await ref.read(productRepositoryProvider).saveProduct(product);
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isCameraReady = true;
    });
    _controller.start();
  }

  void _goBack() {
    _controller.stop();
    _subscription?.cancel();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Product'),
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          actions: [
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                  );
                },
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controller),
            CustomPaint(
              painter: _ScanOverlayPainter(),
              child: const SizedBox.expand(),
            ),
            if (!_isCameraReady)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Getting ready...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isCameraReady)
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
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.width * 0.75,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
        ),
      ),
      paint,
    );

    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    _drawCorner(canvas, scanArea.topLeft, cornerLength, cornerPaint, true, true);
    _drawCorner(canvas, scanArea.topRight, cornerLength, cornerPaint, false, true);
    _drawCorner(canvas, scanArea.bottomLeft, cornerLength, cornerPaint, true, false);
    _drawCorner(canvas, scanArea.bottomRight, cornerLength, cornerPaint, false, false);
  }

  void _drawCorner(
    Canvas canvas,
    Offset corner,
    double length,
    Paint paint,
    bool right,
    bool down,
  ) {
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