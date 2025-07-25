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
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Promo Tersedia:',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
        );
      },
    );
  }
}
