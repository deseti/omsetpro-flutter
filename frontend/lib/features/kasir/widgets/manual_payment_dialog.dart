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
      title: const Text('Pilih Metode Pembayaran'),
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

          // Opsi Pembayaran Langsung
          _buildPaymentOption(
            context,
            icon: Icons.payment,
            title: 'Pembayaran Langsung',
            subtitle: 'Tunai, kartu debit, atau e-wallet langsung',
            color: Colors.green,
            onTapAction: () {
              Navigator.of(context).pop();
              onManualPaymentSelected('Langsung');
            },
          ),

          const SizedBox(height: 8),

          // Opsi Pembayaran Tempo/Hutang
          _buildPaymentOption(
            context,
            icon: Icons.schedule,
            title: 'Pembayaran Tempo/Hutang',
            subtitle: 'Akan dibayar kemudian',
            color: Colors.orange,
            onTapAction: () {
              Navigator.of(context).pop();
              onManualPaymentSelected('Tempo/Hutang');
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
    required VoidCallback onTapAction,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTapAction,
      ),
    );
  }
}
