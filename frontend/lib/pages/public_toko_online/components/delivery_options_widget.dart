import 'package:flutter/material.dart';
import '../../../models/toko_online_model.dart';

class DeliveryOptionsWidget extends StatelessWidget {
  final TokoOnlineData toko;

  const DeliveryOptionsWidget({
    super.key,
    required this.toko,
  });

  @override
  Widget build(BuildContext context) {
    List<String> options = [];
    if (toko.allowPickup) options.add('📦 Ambil di Tempat');
    if (toko.allowDelivery) options.add('🚚 Diantar');

    if (options.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilihan Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child:
                      Text(option, style: const TextStyle(color: Colors.green)),
                )),
          ],
        ),
      ),
    );
  }
}
