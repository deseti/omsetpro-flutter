import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;

class PromoSectionWidget extends ConsumerWidget {
  const PromoSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePromosAsync = ref.watch(AppProviders.activePromosProvider);
    final selectedPromo = ref.watch(AppProviders.selectedPromoProvider);

    return activePromosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Memuat promo...', style: TextStyle(fontSize: 12)),
      ),
      error: (e, s) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Promo tidak tersedia', style: TextStyle(fontSize: 12)),
      ),
      data: (promos) {
        if (promos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Text('Tidak ada promo aktif', style: TextStyle(fontSize: 12)),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Promo Tersedia:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButton<Map<String, dynamic>?>(
                value: selectedPromo,
                hint: const Text('Pilih Promo (Opsional)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<Map<String, dynamic>?>(
                    value: null,
                    child: Text('Tanpa Promo'),
                  ),
                  ...promos.map((promo) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: promo,
                      child: Text(
                          '${promo['nama']} - ${promo['nilai']}${promo['tipe'] == 'PERCENTAGE' ? '%' : ' Rupiah'}'),
                    );
                  }),
                ],
                onChanged: (value) {
                  ref.read(AppProviders.selectedPromoProvider.notifier).state =
                      value;
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
