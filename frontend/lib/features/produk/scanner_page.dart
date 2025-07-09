import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Barcode')),
      body: MobileScanner(
        // Izinkan semua format barcode
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              // Jika barcode terdeteksi, tutup halaman ini dan kirim kodenya kembali
              Navigator.of(context).pop(code);
            }
          }
        },
      ),
    );
  }
}