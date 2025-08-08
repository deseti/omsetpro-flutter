import 'package:flutter/material.dart';
import '../../../models/toko_online_model.dart';

class TokoInfoWidget extends StatelessWidget {
  final TokoOnlineData toko;

  const TokoInfoWidget({
    super.key,
    required this.toko,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (toko.logoUrl != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(toko.logoUrl!),
                  )
                else
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.store, size: 30),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toko.nama,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (toko.alamat.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(toko.alamat,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                      if (toko.telepon.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📞 ${toko.telepon}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
