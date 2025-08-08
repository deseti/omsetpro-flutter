import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/riwayat_transaksi_model.dart';
import '../../../providers/riwayat_transaksi_provider.dart';
import '../../../theme/app_colors.dart';

class FilterSection extends ConsumerWidget {
  const FilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriode = ref.watch(selectedPeriodeProvider);

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Filter Periode:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FilterPeriode.values.map((periode) {
                final isSelected = selectedPeriode == periode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      periode.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(riwayatTransaksiProvider.notifier)
                          .onPeriodeChanged(periode);
                    },
                    backgroundColor: Colors.grey[800],
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey[700]!,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
