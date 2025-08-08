import 'package:flutter/material.dart';
import '../../../models/toko_online_model.dart';
import '../../../utils/currency_formatter.dart';

class CartItemsSection extends StatelessWidget {
  final List<CartItem> cart;

  const CartItemsSection({
    super.key,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pesanan Anda',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...cart.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.produk.nama,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${CurrencyFormatter.formatCurrency(item.produk.harga)} x ${item.jumlah}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCurrency(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class CustomerFormSection extends StatelessWidget {
  final TextEditingController namaController;
  final TextEditingController hpController;

  const CustomerFormSection({
    super.key,
    required this.namaController,
    required this.hpController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Pelanggan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty == true) return 'Nama harus diisi';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: hpController,
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty == true) return 'Nomor HP harus diisi';
            return null;
          },
        ),
      ],
    );
  }
}

class DeliveryOptionsSection extends StatelessWidget {
  final TokoOnlineData toko;
  final String selectedTipe;
  final ValueChanged<String> onTipeChanged;

  const DeliveryOptionsSection({
    super.key,
    required this.toko,
    required this.selectedTipe,
    required this.onTipeChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<String> availableOptions = [];
    if (toko.allowPickup) availableOptions.add('Diambil');
    if (toko.allowDelivery) availableOptions.add('Diantar');

    if (availableOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pengiriman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...availableOptions.map((option) => RadioListTile<String>(
              title: Text(
                  option == 'Diambil' ? 'Ambil di Tempat' : 'Diantar Kurir'),
              value: option,
              groupValue: selectedTipe,
              onChanged: (value) => onTipeChanged(value!),
            )),
      ],
    );
  }
}

class PaymentInfoSection extends StatelessWidget {
  final TokoOnlineData toko;

  const PaymentInfoSection({
    super.key,
    required this.toko,
  });

  @override
  Widget build(BuildContext context) {
    if (toko.rekeningBank.isEmpty) {
      return const Card(
        color: Colors.orange,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Toko belum menambahkan rekening bank. Hubungi langsung untuk pembayaran.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('Transfer ke salah satu rekening berikut:'),
        const SizedBox(height: 8),
        ...toko.rekeningBank.map((rekening) => Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(rekening.namaBank),
                subtitle: Text(
                    '${rekening.nomorRekening}\na.n. ${rekening.namaPemilik}'),
              ),
            )),
      ],
    );
  }
}

class TotalSection extends StatelessWidget {
  final int totalPrice;

  const TotalSection({
    super.key,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            CurrencyFormatter.formatCurrency(totalPrice),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
