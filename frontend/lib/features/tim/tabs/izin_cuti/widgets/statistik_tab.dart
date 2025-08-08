import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/izin_models.dart';
import '../providers/izin_providers.dart';
import '../services/izin_service.dart';

class StatistikTab extends ConsumerWidget {
  const StatistikTab({super.key});

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final izinList = ref.watch(izinTimListProvider);

    return izinList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (izinList) {
        final stats = IzinService.calculateStatistics(izinList);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(izinTimListProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Total Izin',
                          stats['total'].toString(), Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildStatCard('Pending',
                          stats['pending'].toString(), Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Disetujui',
                          stats['approved'].toString(), Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildStatCard(
                          'Ditolak', stats['rejected'].toString(), Colors.red)),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Statistik per Jenis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Jenis izin statistics
              ...JenisIzin.values.map((jenis) {
                final jenisStats =
                    stats['byJenis'][jenis.name] ?? {'total': 0, 'approved': 0};
                return Card(
                  child: ListTile(
                    leading: IzinService.getJenisIzinIcon(jenis.name),
                    title: Text(IzinUtils.getJenisIzinText(jenis)),
                    subtitle: Text('${jenisStats['total']} pengajuan'),
                    trailing: Text(
                      '${jenisStats['approved']} disetujui',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                );
              }),

              if (stats['byUser'].isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Statistik per Anggota Tim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // User statistics
                ...(stats['byUser'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                  final userStats = entry.value;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(entry.key[0]),
                      ),
                      title: Text(entry.key),
                      subtitle: Text('${userStats['total']} pengajuan total'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${userStats['approved']} disetujui',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12),
                          ),
                          Text(
                            '${userStats['pending']} pending',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
