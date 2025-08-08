import 'package:flutter/material.dart';
import '../../../models/riwayat_transaksi_model.dart';

class ShippingInfoDialog extends StatefulWidget {
  final RiwayatTransaksi transaksi;
  final Function(String resi, String kurir) onSubmit;

  const ShippingInfoDialog({
    super.key,
    required this.transaksi,
    required this.onSubmit,
  });

  @override
  State<ShippingInfoDialog> createState() => _ShippingInfoDialogState();
}

class _ShippingInfoDialogState extends State<ShippingInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _resiController = TextEditingController();
  final _kurirController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if already has data
    _resiController.text = widget.transaksi.nomorResi ?? '';
    _kurirController.text = widget.transaksi.namaKurir ?? '';
  }

  @override
  void dispose() {
    _resiController.dispose();
    _kurirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.orange),
          SizedBox(width: 8),
          Text('Info Pengiriman'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transaksi #${widget.transaksi.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (widget.transaksi.namaPelangganOnline?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'Pelanggan: ${widget.transaksi.namaPelangganOnline}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _resiController,
              decoration: const InputDecoration(
                labelText: 'Nomor Resi',
                hintText: 'Masukkan nomor resi pengiriman',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Nomor resi harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kurirController,
              decoration: const InputDecoration(
                labelText: 'Nama Kurir/Jasa Pengiriman',
                hintText: 'JNE, JT Express, Shopee, dll',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delivery_dining),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Nama kurir harus diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSubmit(
        _resiController.text.trim(),
        _kurirController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handling is done in the parent
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
