import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:dio/dio.dart';
import 'hardware/hardware_manager_service.dart';
import 'hardware/thermal_printer_service.dart';
import 'hardware/hardware_detection_service.dart';

class ReceiptService {
  /// Memformat data transaksi menjadi teks struk yang rapi dan profesional
  static String formatReceiptText({
    required String namaToko,
    required String namaCabang,
    required String alamatCabang,
    required String namaKasir,
    required int transaksiId,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required int totalHarga,
    required String metodeBayar, // [BARU] Tambahkan parameter ini
    String? logoPath, // [BARU] Path logo usaha
  }) {
    // Format tanggal dan waktu saat ini
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final formattedDateTime = dateFormatter.format(now);

    // Format angka rupiah (helper dipakai di bawah)

    // Lebar maksimal struk (32 karakter untuk printer thermal umum)
    const int receiptWidth = 32;

    StringBuffer receipt = StringBuffer();

    // Header struk
    receipt.writeln('=' * receiptWidth);
    receipt.writeln(_centerText(namaToko, receiptWidth));
    receipt.writeln(_centerText('Cabang: $namaCabang', receiptWidth));
    receipt.writeln(_centerText('Alamat: $alamatCabang', receiptWidth));
    receipt.writeln('-' * receiptWidth);

    // Info transaksi
    receipt.writeln('${'No: $transaksiId'.padRight(18)}Kasir: $namaKasir');
    receipt.writeln(formattedDateTime);
    receipt.writeln('-' * receiptWidth);

    // Items transaksi
    for (var item in items) {
      final namaProduk = item['nama']?.toString() ?? 'Produk';
      final jumlah = item['jumlah']?.toString() ?? '1';
      final harga = item['harga'] ?? 0;
      final totalItem = ((int.tryParse(jumlah) ?? 1) * harga).toInt();

      // Nama produk (potong jika terlalu panjang)
      const maxNamaLength = receiptWidth;
      final displayNama = namaProduk.length > maxNamaLength
          ? '${namaProduk.substring(0, maxNamaLength - 3)}...'
          : namaProduk;
      receipt.writeln(displayNama);

      // Detail item: jumlah x harga = total
      final itemDetail = '  $jumlah x ${_formatRupiah(harga)}';
      final itemTotal = _formatRupiah(totalItem);
      final spacing = receiptWidth - itemDetail.length - itemTotal.length;

      if (spacing > 0) {
        receipt.writeln(itemDetail + ' ' * spacing + itemTotal);
      } else {
        receipt.writeln(itemDetail);
        receipt.writeln(' ' * (receiptWidth - itemTotal.length) + itemTotal);
      }
    }

    receipt.writeln('-' * receiptWidth);

    // Total section
    receipt.writeln(
        _formatReceiptLine('Subtotal', _formatRupiah(subtotal), receiptWidth));
    receipt.writeln(_formatReceiptLine('Diskon', 'Rp 0', receiptWidth));
    receipt.writeln(
        _formatReceiptLine('Total', _formatRupiah(totalHarga), receiptWidth));

    receipt.writeln('-' * receiptWidth);

    // [MODIFIKASI] Ganti 'TUNAI' dengan parameter dinamis
    receipt.writeln('Metode Bayar: $metodeBayar');

    receipt.writeln('=' * receiptWidth);

    // Footer
    receipt
        .writeln(_centerText('Terima kasih telah berbelanja!', receiptWidth));
    receipt.writeln(_centerText('Follow kami di sosial media:', receiptWidth));
    receipt.writeln(_centerText('Tiktok: omsetpro.digitali', receiptWidth));
    receipt.writeln(_centerText('X: @Omsetpro', receiptWidth));

    return receipt.toString();
  }

  /// Convert image to ESC/POS format for thermal printing
  /// Handles both local assets and remote URLs
  static Future<Uint8List?> _convertImageToESCPOS(String logoPath) async {
    try {
      Uint8List? imageBytes;

      // Load image from assets, file path, or URL
      if (logoPath.startsWith('assets/')) {
        // Load from assets
        final data = await rootBundle.load(logoPath);
        imageBytes = data.buffer.asUint8List();
      } else if (logoPath.startsWith('http://') ||
          logoPath.startsWith('https://')) {
        // Load from URL (server logo)
        try {
          final dio = Dio();
          final response = await dio.get<List<int>>(
            logoPath,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.data != null) {
            imageBytes = Uint8List.fromList(response.data!);
          }
        } catch (e) {
          print('❌ Error loading logo from URL: $e');
          return null;
        }
      } else {
        // For file paths, would need different handling
        print('⚠️ Local file path handling not implemented yet');
        return null;
      }

      if (imageBytes == null) return null;

      final image = img.decodeImage(imageBytes);

      if (image == null) return null;

      // Resize image to fit thermal printer width (384px for 58mm paper)
      final resized = img.copyResize(image, width: 384);

      // Convert to monochrome
      final monochrome = img.grayscale(resized);

      // Convert to ESC/POS format
      final escposBytes = <int>[];

      // ESC/POS image command header
      escposBytes.addAll([0x1D, 0x76, 0x30, 0x00]); // GS v 0 0

      // Image width and height
      final width = monochrome.width;
      final height = monochrome.height;
      final widthBytes = (width + 7) ~/ 8;

      escposBytes.addAll([widthBytes & 0xFF, (widthBytes >> 8) & 0xFF]);
      escposBytes.addAll([height & 0xFF, (height >> 8) & 0xFF]);

      // Convert pixels to 1-bit format
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < widthBytes; x++) {
          int byte = 0;
          for (int bit = 0; bit < 8; bit++) {
            final pixelX = x * 8 + bit;
            if (pixelX < width) {
              final pixel = monochrome.getPixel(pixelX, y);
              final luminance = img.getLuminance(pixel);
              if (luminance < 128) {
                // Black pixel
                byte |= (1 << (7 - bit));
              }
            }
          }
          escposBytes.add(byte);
        }
      }

      return Uint8List.fromList(escposBytes);
    } catch (e) {
      print('❌ Error converting logo to ESC/POS: $e');
      return null;
    }
  }

  /// Generate receipt with logo support for ESC/POS printers
  static Future<List<int>> formatReceiptWithLogo({
    required String namaToko,
    required String namaCabang,
    required String alamatCabang,
    required String namaKasir,
    required int transaksiId,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required int totalHarga,
    required String metodeBayar,
    String? logoPath,
  }) async {
    final escposCommands = <int>[];

    // Initialize printer
    escposCommands.addAll([0x1B, 0x40]); // ESC @ (Initialize)

    // Add logo if available
    if (logoPath != null && logoPath.isNotEmpty) {
      final logoBytes = await _convertImageToESCPOS(logoPath);
      if (logoBytes != null) {
        // Center align for logo
        escposCommands.addAll([0x1B, 0x61, 0x01]); // ESC a 1 (Center)
        escposCommands.addAll(logoBytes);
        escposCommands.addAll([0x0A, 0x0A]); // Two line feeds after logo
      }
    }

    // Get regular receipt text
    final receiptText = formatReceiptText(
      namaToko: namaToko,
      namaCabang: namaCabang,
      alamatCabang: alamatCabang,
      namaKasir: namaKasir,
      transaksiId: transaksiId,
      items: items,
      subtotal: subtotal,
      totalHarga: totalHarga,
      metodeBayar: metodeBayar,
      logoPath: logoPath,
    );

    // Center align for header
    escposCommands.addAll([0x1B, 0x61, 0x01]); // ESC a 1 (Center)

    // Add receipt text as UTF-8 bytes
    final textBytes = receiptText.codeUnits;
    escposCommands.addAll(textBytes);

    // Cut paper
    escposCommands.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B 0 (Full cut)

    return escposCommands;
  }

  /// Helper untuk memusatkan teks
  static String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);

    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Helper untuk format rupiah sederhana
  static String _formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Print receipt directly to thermal printer if connected
  static Future<PrintResult> printReceiptToHardware({
    required String namaToko,
    required String namaCabang,
    required String alamatCabang,
    required String namaKasir,
    required int transaksiId,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required int totalHarga,
    required String metodeBayar,
    String? logoPath, // [BARU] Path logo usaha
    bool autoCut = true,
    bool openDrawer = false,
  }) async {
    try {
      final hardwareManager = HardwareManagerService();

      // Check if printer is connected
      if (!hardwareManager.isDeviceConnected(HardwareType.thermalPrinter)) {
        return PrintResult(
          success: false,
          message:
              'No thermal printer connected. Please connect a printer first.',
        );
      }

      // Generate receipt text
      final receiptText = formatReceiptText(
        namaToko: namaToko,
        namaCabang: namaCabang,
        alamatCabang: alamatCabang,
        namaKasir: namaKasir,
        transaksiId: transaksiId,
        items: items,
        subtotal: subtotal,
        totalHarga: totalHarga,
        metodeBayar: metodeBayar,
        logoPath: logoPath, // [BARU] Pass logo path
      );

      // Print to hardware
      final result = await hardwareManager.printReceipt(
        receiptText: receiptText,
        autoCut: autoCut,
        openDrawer: openDrawer,
      );

      return result;
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Error printing receipt: $e',
      );
    }
  }

  /// Print test receipt to verify printer functionality
  static Future<PrintResult> printTestReceipt() async {
    try {
      final hardwareManager = HardwareManagerService();

      if (!hardwareManager.isDeviceConnected(HardwareType.thermalPrinter)) {
        return PrintResult(
          success: false,
          message: 'No thermal printer connected',
        );
      }

      return await hardwareManager.printerService.printTestPage();
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Error printing test receipt: $e',
      );
    }
  }

  /// Helper untuk format baris dengan label dan nilai (rata kanan)
  static String _formatReceiptLine(String label, String value, int width) {
    final spacing = width - label.length - value.length;
    if (spacing > 0) {
      return label + ' ' * spacing + value;
    } else {
      return '$label $value';
    }
  }
}
