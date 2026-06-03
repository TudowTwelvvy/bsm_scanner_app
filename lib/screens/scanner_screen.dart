import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  //this controller is used to control the mobile scanner, such as starting and stopping the camera, and getting the scanned barcode data
  final MobileScannerController _cameraController = MobileScannerController();
  
  StreamSubscription<BarcodeCapture>? _subscription;
 //this variable is used to prevent multiple scans of the same barcode, as the mobile scanner can sometimes scan the same barcode multiple times in quick succession
  bool _hasScanned = false;

  @override 
  void initState() {
    super.initState();
    _cameraController.start();
    _subscription = _cameraController.barcodes.listen(_onBarcodeDetected);
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return; //prevent multiple scans of the same barcode

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;
    final Barcode barcode = barcodes.first; //get the first detected barcode
    
    if(barcode.rawValue == null) return;
    
    //locks the scanner to prevent multiple scans of the same barcode
    setState(() {
      _hasScanned = true;
    }); //if the barcode has no data, return

    _cameraController.stop(); //stop the camera to prevent further scans
    _showSaveDialog(barcode); //show the scanned barcode data in a dialog
  }

    void _showSaveDialog(Barcode barcode) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.qr_code_scanner, size: 48, color: Color(0xFF1A73E8)),
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
              Text(
                'Type: ${barcode.type.name}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('Save this scan to your history?'),
            ],
          ),
          actions: [
            TextButton(
              //go back to scanning without saving, and turn the camera back on
              onPressed: () {
                Navigator.pop(context); 
                _resetScanner();      // Turn the camera back on
              },
              child: const Text('Cancel'),
            ),

            //save the scanned barcode data to Firestore and then go back to scanning
            //When the user taps "Save", we save the scan to Firestore, show a confirmation message, and then reset the scanner for the next scan.
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                
                await _saveToFirestore(barcode);
                //After saving, we check if the widget is still mounted (i.e., the user hasn't navigated away), then pop the dialog, show a confirmation SnackBar, and reset the scanner for the next scan.
                if (!mounted) return;
                navigator.pop();
                
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Scan saved!'),
                  ),
                );
                _resetScanner();
              },
              child: const Text('Save Scan'),
            ),
          ],
        );
      },
    );
  }
    //talks to firestore and resets the scanner for the next scan
    Future<void> _saveToFirestore(Barcode barcode) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    
    //firestore structure: users collection -> user document (uid) -> scans collection -> scan document (auto-generated id) with fields: barcode, barcodeType, scannedAt
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scans')
        .add({
      'barcode': barcode.rawValue,
      'barcodeType': barcode.type.name,
      'scannedAt': Timestamp.now(), //for timestamp
    });
  }

 //turn everything back to the initial state for the next scan
  void _resetScanner() {
    setState(() {
      _hasScanned = false; //unlock the scanner for the next scan
    });
    _cameraController.start(); //turn the camera back on
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cameraController.dispose();
    super.dispose();
    
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          //Flashlight toggle
          IconButton(
            icon: ValueListenableBuilder(
              //The controller broadcasts its current state (torch on/off, camera facing, etc.)
              //through a ValueNotifier. We listen to it to update the icon.
              valueListenable: _cameraController,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),

          // Switch front/back camera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The camera preview fills the entire screen.
          MobileScanner(
            controller: _cameraController,
            
          ),

          // Dark overlay with a cutout square so the user knows where to aim.
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

//This class paints the dark overlay with a transparent cutout in the middle, and white corner brackets to indicate where to aim the barcode.
// It uses the CustomPainter class to draw directly on the canvas. The scan window is a square in the center of the screen, and the rest of the screen is covered with a semi-transparent black color.
// The corner brackets are drawn as white lines at the corners of the scan window, to give a nice visual indication of where to position the barcode for scanning.
//This is purely a UI element and does not affect the scanning functionality, which is handled by the MobileScanner widget underneath.
// The CustomPaint widget in the build method uses this painter to draw the overlay on top of the camera preview.
// The shouldRepaint method returns false because this overlay does not change dynamically. If we were to animate the overlay (e.g., a moving line), we would return true when the animation updates.
// This overlay helps guide the user to position the barcode correctly for scanning, improving the user experience.
// The use of CustomPainter allows for a highly customizable and efficient way to create this kind of overlay without needing to use multiple widgets or images.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paint the dark area around the scan window.
    final backgroundPaint = Paint()..color = Colors.black54;

    // The scan window is a square in the center, 75% of screen width.
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.width * 0.75,
    );

    // Create a path that is "the whole screen MINUS the scan window"
    final backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
        ),
    );

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Now draw white corner brackets so the user knows exactly where to aim.
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const length = 30.0;

    // Top-left corner
    canvas.drawLine(
      scanWindow.topLeft,
      scanWindow.topLeft + const Offset(length, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.topLeft,
      scanWindow.topLeft + const Offset(0, length),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      scanWindow.topRight,
      scanWindow.topRight + const Offset(-length, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.topRight,
      scanWindow.topRight + const Offset(0, length),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      scanWindow.bottomLeft,
      scanWindow.bottomLeft + const Offset(length, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.bottomLeft,
      scanWindow.bottomLeft + const Offset(0, -length),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      scanWindow.bottomRight,
      scanWindow.bottomRight + const Offset(-length, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.bottomRight,
      scanWindow.bottomRight + const Offset(0, -length),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}