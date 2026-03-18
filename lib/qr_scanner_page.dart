import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();

  bool _isScanning = true;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    cameraController.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _switchCamera() {
    cameraController.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pindai QR/Barcode',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter', // Menggunakan font Inter
            fontSize: 20, // Ukuran font untuk judul AppBar
          ),
        ),
        backgroundColor: const Color(0xFF0D2547),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: _switchCamera,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return;

              final barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;

                if (code != null) {
                  setState(() {
                    _isScanning = false;
                  });

                  Navigator.pop(context, code);
                }
              }
            },
          ),

          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: ScannerCornersPainter(
                      borderColor: Colors.white,
                      borderWidth: 3.0,
                      cornerLength: 20.0,
                    ),
                    child: Container(),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      const double lineHeight =
                          3.0; // Garis sedikit lebih tebal
                      final topPosition = _animation.value * (220 - lineHeight);
                      return Positioned(
                        top: topPosition,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: lineHeight,
                          decoration: BoxDecoration(
                            // Warna solid biru muda neon untuk garis pindai
                            color: const Color(0xFF05AFFD),
                            boxShadow: [
                              BoxShadow(
                                // Warna shadow disesuaikan dengan warna garis
                                color: const Color(0xFF05AFFD).withOpacity(0.7),
                                blurRadius: 10, // Efek blur lebih kuat
                                spreadRadius: 3, // Efek menyebar lebih luas
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Mengatur posisi tombol senter dan teks instruksi di bagian bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 50.0,
              ), // Padding dari bawah layar untuk Column
              child: Column(
                mainAxisSize:
                    MainAxisSize
                        .min, // Agar Column tidak memakan semua ruang vertikal
                children: [
                  // Tombol Mengambang "Nyalakan Senter"
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFlashOn
                                ? Icons.flashlight_on
                                : Icons.flashlight_off,
                            color: _isFlashOn ? Colors.yellow : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFlashOn ? 'Matikan Senter' : 'Nyalakan Senter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter', // Menggunakan font Inter
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Spasi antara tombol dan teks
                  // Teks instruksi "Posisikan QR atau Barcode di dalam bingkai"
                  Text(
                    'Posisikan QR atau Barcode di dalam bingkai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                        0.8,
                      ), // Sedikit transparan
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter', // Menggunakan font Inter
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerCornersPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerLength;

  ScannerCornersPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Sudut kiri atas
    canvas.drawLine(Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);

    // Sudut kanan atas
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Sudut kiri bawah
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Sudut kanan bawah
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ScannerCornersPainter ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.cornerLength != cornerLength;
  }
}
