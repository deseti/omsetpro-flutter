import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/riwayat_transaksi_model.dart';
import '../../../theme/app_colors.dart';

class TransaksiCard extends StatelessWidget {
  final RiwayatTransaksi transaksi;
  final bool dark;
  final VoidCallback onTap;
  final VoidCallback? onAddShippingInfo;

  const TransaksiCard({
    super.key,
    required this.transaksi,
    required this.onTap,
    this.dark = false,
    this.onAddShippingInfo,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: dark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(formatter),
              const SizedBox(height: 12),
              _buildAmountInfo(formatter),
              const SizedBox(height: 12),
              _buildUserInfo(),
              if (transaksi.isTokoOnline) ...[
                const SizedBox(height: 8),
                _buildTokoOnlineInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(NumberFormat formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${transaksi.id}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor(transaksi.metodeBayar)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaksi.metodeBayar,
                style: TextStyle(
                  color: _getPaymentMethodColor(transaksi.metodeBayar),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        Text(
          DateFormat('dd/MM/yy HH:mm').format(transaksi.createdAt),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInfo(NumberFormat formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatter.format(transaksi.total),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
            if (transaksi.potongan > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Diskon: ${formatter.format(transaksi.potongan)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaksi.totalItem} item',
              style: TextStyle(
                fontSize: 14,
                color: dark ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              transaksi.cabang.nama,
              style: TextStyle(
                fontSize: 12,
                color: dark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        Icon(Icons.person,
            size: 16, color: dark ? Colors.white38 : Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          transaksi.kasir.namaLengkap,
          style: TextStyle(
            fontSize: 12,
            color: dark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        if (transaksi.pelanggan != null) ...[
          const SizedBox(width: 16),
          Icon(Icons.account_circle,
              size: 16, color: dark ? Colors.white38 : Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            transaksi.pelanggan!.nama,
            style: TextStyle(
              fontSize: 12,
              color: dark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTokoOnlineInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 4),
              Text(
                'Toko Online',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              if (transaksi.tipePengiriman != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaksi.isDelivery
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaksi.tipePengiriman!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: transaksi.isDelivery
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (transaksi.namaPelangganOnline?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              'Pelanggan: ${transaksi.namaPelangganOnline}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
              ),
            ),
          ],
          if (transaksi.isDelivery && transaksi.hasShippingInfo) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_shipping,
                    size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${transaksi.namaKurir ?? "Kurir"}: ${transaksi.nomorResi ?? "Belum ada resi"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (transaksi.isDelivery && !transaksi.hasShippingInfo) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onAddShippingInfo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_box,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Tambah Info Pengiriman',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String metodeBayar) {
    switch (metodeBayar.toLowerCase()) {
      case 'tunai':
        return Colors.green;
      case 'qris':
        return Colors.purple;
      case 'transfer bank':
        return Colors.blue;
      case 'digital':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
