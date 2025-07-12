import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/pelanggan_model.dart';
import '../../../providers/loyalty_provider.dart';
import '../../../providers/providers.dart';
import '../../pelanggan/pelanggan_page.dart'; // <-- [PERBAIKAN] Import yang hilang ditambahkan

class RedeemRewardDialog extends ConsumerWidget {
  final Pelanggan pelanggan;

  const RedeemRewardDialog({Key? key, required this.pelanggan}) : super(key: key);

  void _redeem(BuildContext context, WidgetRef ref, Reward reward) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Konfirmasi Penukaran'),
        content: Text('Anda yakin ingin menukar ${reward.poinDibutuhkan} poin dengan "${reward.namaHadiah}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(confirmContext).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              try {
                final response = await dio.post('/loyalty/redeem', data: {
                  'pelangganId': pelanggan.id,
                  'rewardId': reward.id,
                });

                // Update data pelanggan yang dipilih di halaman kasir
                final updatedPelanggan = Pelanggan.fromJson(response.data['pelanggan']);
                ref.read(selectedPelangganProvider.notifier).state = updatedPelanggan;

                // Tutup semua dialog dan tampilkan notifikasi
                Navigator.of(confirmContext).pop(); // Tutup dialog konfirmasi
                Navigator.of(context).pop(); // Tutup dialog redeem
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Poin berhasil ditukar!'), backgroundColor: Colors.green),
                );
                
                // Refresh daftar pelanggan di halaman utama manajemen pelanggan
                ref.invalidate(pelangganListFutureProvider);

              } on DioException catch (e) {
                final errorMessage = e.response?.data['message'] ?? 'Gagal menukar poin.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tukar Poin', style: Theme.of(context).textTheme.titleLarge),
            Text('${pelanggan.nama} - ${pelanggan.totalPoin} Poin', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: rewardsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (rewards) {
                  // Filter hadiah yang bisa ditukar
                  final availableRewards = rewards.where((r) => pelanggan.totalPoin >= r.poinDibutuhkan && r.isActive).toList();
                  
                  if (availableRewards.isEmpty) {
                    return const Center(child: Text('Tidak ada hadiah yang bisa ditukar.'));
                  }

                  return ListView.builder(
                    itemCount: availableRewards.length,
                    itemBuilder: (context, index) {
                      final reward = availableRewards[index];
                      return Card(
                        child: ListTile(
                          title: Text(reward.namaHadiah),
                          subtitle: Text(reward.deskripsi ?? ''),
                          trailing: Text(
                            '${reward.poinDibutuhkan} Poin',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                          onTap: () => _redeem(context, ref, reward),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}