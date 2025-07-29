import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';

class ManualPaymentDialog extends StatelessWidget {
  final int totalHarga;
  final Function(String paymentType) onManualPaymentSelected;
  // [BARU] Tambahkan callback baru untuk pembayaran digital sungguhan
  final VoidCallback onDigitalPaymentInitiated;

  const ManualPaymentDialog({
    super.key,
    required this.totalHarga,
    required this.onManualPaymentSelected,
    required this.onDigitalPaymentInitiated, // [BARU]
  });

  static void show(
    BuildContext context, {
    required int totalHarga,
    required Function(String paymentType) onManualPaymentSelected,
    required VoidCallback onDigitalPaymentInitiated, // [BARU]
  }) {
    showDialog(
      context: context,
      builder: (context) => ManualPaymentDialog(
        totalHarga: totalHarga,
        onManualPaymentSelected: onManualPaymentSelected,
        onDigitalPaymentInitiated: onDigitalPaymentInitiated, // [BARU]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Pembayaran'), // Judul diubah agar lebih umum
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total: ${CurrencyFormatter.formatCurrency(totalHarga)}'),
          const SizedBox(height: 16),
          const Text(
            'Pilih metode pembayaran:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // [MODIFIKASI] Opsi ini sekarang memanggil fungsi yang berbeda
          _buildPaymentOption(
            context,
            icon: Icons.qr_code,
            title: 'QRIS & E-Wallet',
            subtitle: 'Buat pembayaran via Midtrans',
            onTapAction: () {
              Navigator.of(context).pop();
              onDigitalPaymentInitiated(); // Panggil fungsi untuk memunculkan QRIS
            },
          ),

          // [MODIFIKASI] Opsi ini tetap sebagai pencatatan manual
          _buildPaymentOption(
            context,
            icon: Icons.credit_card,
            title: 'Transfer Bank (Manual)',
            subtitle: 'Catat sebagai lunas via transfer',
            onTapAction: () {
              Navigator.of(context).pop();
              // 'transfer' adalah nama metode bayar yang akan disimpan
              onManualPaymentSelected('Transfer Bank');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTapAction, // [MODIFIKASI] Gunakan callback umum
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTapAction, // Gunakan action yang sudah ditentukan
    );
  }
}
