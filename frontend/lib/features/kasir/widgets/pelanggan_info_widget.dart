import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pelanggan_model.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import './pilih_pelanggan_dialog.dart';
import './redeem_reward_dialog.dart';

class PelangganInfoWidget extends ConsumerWidget {
  final Pelanggan? pelanggan;

  const PelangganInfoWidget({
    super.key,
    required this.pelanggan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: pelanggan == null
          ? _buildNoPelangganInfo(context)
          : _buildPelangganDetails(context, ref),
    );
  }

  Widget _buildNoPelangganInfo(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.person_add_alt_1,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'Tanpa Pelanggan',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        'Klik untuk mencari atau menambah',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => const PilihPelangganDialog(),
        );
      },
    );
  }

  Widget _buildPelangganDetails(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(
              pelanggan!.nama.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          title: Text(
            pelanggan!.nama,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(
            pelanggan!.noHp,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Hapus Pelanggan dari Transaksi',
            onPressed: () {
              ref.read(AppProviders.selectedPelangganProvider.notifier).state =
                  null;
            },
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const PilihPelangganDialog(),
            );
          },
        ),
        Divider(color: Theme.of(context).colorScheme.outline),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Poin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    '${pelanggan!.totalPoin} Poin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              FilledButton.tonal(
                onPressed: pelanggan!.totalPoin > 0
                    ? () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              RedeemRewardDialog(pelanggan: pelanggan!),
                        );
                      }
                    : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard, size: 18),
                    SizedBox(width: AppTheme.spaceXS),
                    Text('Tukar Poin'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
