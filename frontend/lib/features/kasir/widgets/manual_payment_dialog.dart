import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';

class ManualPaymentDialog extends StatelessWidget {
  final int totalHarga;
  final Function(String paymentType) onPaymentSelected;

  const ManualPaymentDialog({
    super.key,
    required this.totalHarga,
    required this.onPaymentSelected,
  });

  static void show(
    BuildContext context, {
    required int totalHarga,
    required Function(String paymentType) onPaymentSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => ManualPaymentDialog(
        totalHarga: totalHarga,
        onPaymentSelected: onPaymentSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pembayaran Manual'),
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
          _buildPaymentOption(
            context,
            icon: Icons.credit_card,
            title: 'Transfer Bank',
            subtitle: 'Catat sebagai pembayaran digital',
            paymentType: 'transfer',
          ),
          _buildPaymentOption(
            context,
            icon: Icons.qr_code,
            title: 'QRIS',
            subtitle: 'Pembayaran melalui QRIS',
            paymentType: 'qris',
          ),
          _buildPaymentOption(
            context,
            icon: Icons.account_balance_wallet,
            title: 'E-Wallet',
            subtitle: 'GoPay, OVO, DANA, dll',
            paymentType: 'ewallet',
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
    required String paymentType,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.of(context).pop();
        onPaymentSelected(paymentType);
      },
    );
  }
}
