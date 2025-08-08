import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hardware_providers.dart';
import '../services/hardware/hardware_manager_service.dart';
import '../services/receipt_service.dart';

class ReceiptPreviewDialog extends ConsumerWidget {
  final String receiptText;
  final String transaksiId;
  final String? logoUrl; // [BARU] URL logo dari server

  const ReceiptPreviewDialog({
    super.key,
    required this.receiptText,
    required this.transaksiId,
    this.logoUrl, // [BARU] Optional logo URL
  });

  static void show(
    BuildContext context, {
    required String receiptText,
    required String transaksiId,
    String? logoUrl, // [BARU] Optional logo URL
  }) {
    showDialog(
      context: context,
      builder: (context) => ReceiptPreviewDialog(
        receiptText: receiptText,
        transaksiId: transaksiId,
        logoUrl: logoUrl, // [BARU] Pass logo URL
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrinterConnected = ref.watch(isPrinterConnectedProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dialog
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview Struk #$transaksiId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview area dengan background seperti kertas
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // [BARU] Logo preview jika ada
                      if (logoUrl != null && logoUrl!.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              logoUrl!,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Logo tidak dapat dimuat',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 60,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      // Teks struk
                      SelectableText(
                        receiptText,
                        style: const TextStyle(
                          fontFamily: 'Courier', // Font monospace
                          fontSize: 12,
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol copy ke clipboard
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Tombol print ke thermal printer atau placeholder
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isPrinterConnected
                        ? () => _printToThermalPrinter(context, ref)
                        : () => _showPrinterSetupDialog(context),
                    icon: Icon(isPrinterConnected
                        ? Icons.print
                        : Icons.print_disabled),
                    label: Text(isPrinterConnected ? 'Print' : 'Setup Printer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor:
                          isPrinterConnected ? Colors.green.shade50 : null,
                      foregroundColor:
                          isPrinterConnected ? Colors.green.shade700 : null,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Tombol OK/Tutup
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: const Text('OK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Copy receipt text ke clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Struk berhasil disalin ke clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Print receipt to thermal printer
  Future<void> _printToThermalPrinter(
      BuildContext context, WidgetRef ref) async {
    try {
      final hardwareManager = ref.read(hardwareManagerProvider);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Print to thermal printer
      final result = await hardwareManager.printReceipt(
        receiptText: receiptText,
        autoCut: true,
        openDrawer: false, // Don't open drawer on receipt reprint
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show result
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.of(context).pop();

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show printer setup dialog
  void _showPrinterSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Setup Required'),
        content: const Text(
          'No thermal printer is connected. Please set up your printer first.\n\n'
          'Go to Hardware Settings to scan and connect your thermal printer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to hardware settings
              Navigator.of(context).pushNamed('/hardware-settings');
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Print receipt (placeholder untuk implementasi printer)
  void _printReceipt(BuildContext context) {
    // FUTURE: Implementasi print ke thermal printer akan ditambahkan
    // Untuk saat ini hanya menampilkan pesan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur print akan tersedia di update mendatang'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
