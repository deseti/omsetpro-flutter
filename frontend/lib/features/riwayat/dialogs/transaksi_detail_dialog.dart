import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/riwayat_transaksi_model.dart';
import '../../../theme/app_colors.dart';

class TransaksiDetailDialog extends StatelessWidget {
  final RiwayatTransaksi transaksi;

  const TransaksiDetailDialog({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTransactionInfo(),
                    const SizedBox(height: 20),
                    const Divider(),
                    _buildProductDetails(formatter),
                    const SizedBox(height: 16),
                    const Divider(),
                    _buildSummary(formatter),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Transaksi #${transaksi.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm').format(transaksi.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Kasir', transaksi.kasir.namaLengkap),
        _buildInfoRow('Cabang', transaksi.cabang.nama),
        _buildInfoRow('Metode Bayar', transaksi.metodeBayar),
        if (transaksi.pelanggan != null)
          _buildInfoRow('Pelanggan', transaksi.pelanggan!.nama),
      ],
    );
  }

  Widget _buildProductDetails(NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Produk:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...transaksi.detail.map((detail) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.produk.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${detail.jumlah} x ${formatter.format(detail.hargaSaatItu)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (detail.potonganItem > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Diskon: ${formatter.format(detail.potonganItem)}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (detail.potonganItem > 0) ...[
                        Text(
                          formatter.format(detail.subtotal),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          formatter.format(detail.subtotalSetelahDiskon),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ] else ...[
                        Text(
                          formatter.format(detail.subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSummary(NumberFormat formatter) {
    return Column(
      children: [
        if (transaksi.potongan > 0) ...[
          _buildSummaryRow(
              'Subtotal', formatter.format(transaksi.totalSebelumDiskon)),
          _buildSummaryRow(
              'Diskon', '- ${formatter.format(transaksi.potongan)}',
              color: Colors.green[600]),
        ],
        _buildSummaryRow('Total', formatter.format(transaksi.total),
            isTotal: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
