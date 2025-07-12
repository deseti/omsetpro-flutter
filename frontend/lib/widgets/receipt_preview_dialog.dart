import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final String receiptText;
  final String transaksiId;

  const ReceiptPreviewDialog({
    super.key,
    required this.receiptText,
    required this.transaksiId,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: SelectableText(
                    receiptText,
                    style: const TextStyle(
                      fontFamily: 'Courier', // Font monospace
                      fontSize: 12,
                      height: 1.2,
                      color: Colors.black87,
                    ),
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

                // Tombol print (placeholder untuk future implementation)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printReceipt(context),
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  /// Static method untuk menampilkan dialog
  static void show(
    BuildContext context, {
    required String receiptText,
    required String transaksiId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReceiptPreviewDialog(
        receiptText: receiptText,
        transaksiId: transaksiId,
      ),
    );
  }
}
