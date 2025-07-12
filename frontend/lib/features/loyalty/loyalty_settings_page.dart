import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/providers.dart';

class LoyaltySettingsPage extends ConsumerStatefulWidget {
  const LoyaltySettingsPage({super.key});

  @override
  _LoyaltySettingsPageState createState() => _LoyaltySettingsPageState();
}

class _LoyaltySettingsPageState extends ConsumerState<LoyaltySettingsPage> {
  final _kelipatanController = TextEditingController();
  final _poinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ambil data aturan awal dan isi form
    ref.read(loyaltyRuleProvider.future).then((rule) {
      if (rule != null && mounted) {
        _kelipatanController.text = rule.kelipatanRp.toString();
        _poinController.text = rule.dapatPoin.toString();
      }
    });
  }

  @override
  void dispose() {
    _kelipatanController.dispose();
    _poinController.dispose();
    super.dispose();
  }

  Future<void> _simpanAturan() async {
    final kelipatan = int.tryParse(_kelipatanController.text);
    final poin = int.tryParse(_poinController.text);

    if (kelipatan == null || poin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap isi semua kolom dengan angka.')));
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/loyalty/rules', data: {
        'kelipatanRp': kelipatan,
        'dapatPoin': poin,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aturan berhasil disimpan!'),
          backgroundColor: Colors.green));
      ref.invalidate(loyaltyRuleProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan aturan.'),
          backgroundColor: Colors.red));
    }
  }

  void _showRewardDialog({Reward? reward}) {
    final isEditing = reward != null;
    final namaController =
        TextEditingController(text: reward?.namaHadiah ?? '');
    final poinController =
        TextEditingController(text: reward?.poinDibutuhkan.toString() ?? '');
    final deskripsiController =
        TextEditingController(text: reward?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Hadiah' : 'Tambah Hadiah Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Hadiah')),
              TextField(
                  controller: poinController,
                  decoration:
                      const InputDecoration(labelText: 'Poin Dibutuhkan'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: deskripsiController,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi (Opsional)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              final data = {
                'namaHadiah': namaController.text,
                'poinDibutuhkan': int.parse(poinController.text),
                'deskripsi': deskripsiController.text,
              };

              try {
                if (isEditing) {
                  await dio.patch('/loyalty/rewards/${reward.id}', data: data);
                } else {
                  await dio.post('/loyalty/rewards', data: data);
                }
                Navigator.of(context).pop();
                ref.invalidate(rewardsProvider);
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(rewardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Loyalitas')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loyaltyRuleProvider);
          ref.invalidate(rewardsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card untuk Aturan Poin
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aturan Perolehan Poin',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                        'Atur berapa poin yang didapat pelanggan untuk setiap nominal pembelanjaan.'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Setiap belanja Rp'),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: _kelipatanController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Mendapatkan'),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: _poinController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        const Text('Poin'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _simpanAturan,
                          child: const Text('Simpan Aturan')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Card untuk Katalog Hadiah
            Text('Katalog Hadiah',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            rewardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (rewards) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  return Card(
                    child: ListTile(
                      title: Text(reward.namaHadiah),
                      subtitle: Text(reward.deskripsi ?? ''),
                      trailing: Text('${reward.poinDibutuhkan} Poin',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                      onTap: () => _showRewardDialog(reward: reward),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRewardDialog(),
        tooltip: 'Tambah Hadiah',
        child: const Icon(Icons.add),
      ),
    );
  }
}
