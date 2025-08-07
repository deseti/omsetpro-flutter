import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/promo_provider.dart';
import '../../providers/providers.dart';

class PromoPage extends ConsumerWidget {
  const PromoPage({super.key});

  void _showPromoDialog(BuildContext context, WidgetRef ref, {Promo? promo}) {
    final isEditing = promo != null;
    final formKey = GlobalKey<FormState>();

    // State
    final namaController = TextEditingController(text: promo?.nama ?? '');
    final deskripsiController =
        TextEditingController(text: promo?.deskripsi ?? '');
    PromoTipe? tipe = promo?.tipe;
    final nilaiController =
        TextEditingController(text: promo?.nilai.toString() ?? '');
    // Gunakan tipe yang lebih spesifik dan aman
    List<Object?> selectedProdukIds =
        promo?.produk.map((p) => p.id as Object).toList() ?? [];

    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog tertutup saat diklik di luar
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Promo' : 'Buat Promo Baru'),
          content: Consumer(
            builder: (context, ref, child) {
              final produkAsync = ref.watch(simpleProdukProvider);
              return produkAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat daftar produk...'),
                      ],
                    ),
                  ),
                ),
                error: (e, s) => Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('Gagal memuat produk: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(directProdukListProvider);
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
                data: (produkList) {
                  if (produkList.isEmpty) {
                    return Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada produk',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pastikan Anda sudah menambahkan produk di cabang.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: namaController,
                            decoration:
                                const InputDecoration(labelText: 'Nama Promo'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nama tidak boleh kosong'
                                : null,
                          ),
                          TextFormField(
                              controller: deskripsiController,
                              decoration: const InputDecoration(
                                  labelText: 'Deskripsi')),
                          StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter setState) {
                              return DropdownButtonFormField<PromoTipe>(
                                value: tipe,
                                hint: const Text('Pilih Tipe Promo'),
                                items: PromoTipe.values.map((PromoTipe value) {
                                  return DropdownMenuItem<PromoTipe>(
                                    value: value,
                                    child: Text(value.name),
                                  );
                                }).toList(),
                                onChanged: (PromoTipe? newValue) {
                                  setState(() {
                                    tipe = newValue;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Tipe promo tidak boleh kosong'
                                    : null,
                              );
                            },
                          ),
                          TextFormField(
                            controller: nilaiController,
                            decoration: const InputDecoration(
                                labelText: 'Nilai (persen atau nominal)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nilai tidak boleh kosong'
                                : null,
                          ),
                          StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter setState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Produk Berlaku'),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: selectedProdukIds.isEmpty
                                              ? const Text(
                                                  'Pilih satu atau lebih produk',
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                )
                                              : Text(
                                                  '${selectedProdukIds.length} produk dipilih',
                                                ),
                                          trailing:
                                              const Icon(Icons.arrow_drop_down),
                                          onTap: () async {
                                            final List<int>? selected =
                                                await showDialog<List<int>>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                List<int> tempSelected =
                                                    List.from(selectedProdukIds
                                                        .cast<int>());
                                                return StatefulBuilder(
                                                  builder: (context,
                                                      setDialogState) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Pilih Produk'),
                                                      content: SizedBox(
                                                        width: double.maxFinite,
                                                        height: 400,
                                                        child: ListView.builder(
                                                          itemCount:
                                                              produkList.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            final produk =
                                                                produkList[
                                                                    index];
                                                            final isSelected =
                                                                tempSelected
                                                                    .contains(
                                                                        produk
                                                                            .id);
                                                            return CheckboxListTile(
                                                              title: Text(
                                                                  '${produk.nama} (${produk.cabangNama})'),
                                                              value: isSelected,
                                                              onChanged: (bool?
                                                                  value) {
                                                                setDialogState(
                                                                    () {
                                                                  if (value ==
                                                                      true) {
                                                                    tempSelected
                                                                        .add(produk
                                                                            .id);
                                                                  } else {
                                                                    tempSelected
                                                                        .remove(
                                                                            produk.id);
                                                                  }
                                                                });
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child: const Text(
                                                              'BATAL'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(
                                                                      tempSelected),
                                                          child:
                                                              const Text('OK'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                            if (selected != null) {
                                              setState(() {
                                                selectedProdukIds =
                                                    selected.cast<Object?>();
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedProdukIds.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Harap pilih setidaknya satu produk',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();

                  if (tipe == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tipe promo harus dipilih'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }

                  // Validasi produk yang dipilih
                  if (selectedProdukIds.isEmpty) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Harap pilih setidaknya satu produk'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }

                  try {
                    final dio = ref.read(dioProvider);
                    final data = {
                      'nama': namaController.text,
                      'deskripsi': deskripsiController.text,
                      'tipe': tipe.toString().split('.').last,
                      'nilai': double.parse(nilaiController.text),
                      'produkIds':
                          selectedProdukIds.map((e) => e as int).toList(),
                    };

                    if (isEditing) {
                      await dio.patch('/promo/${promo.id}', data: data);
                    } else {
                      await dio.post('/promo', data: data);
                    }

                    if (!context.mounted) return;
                    Navigator.of(dialogContext).pop();
                    ref.invalidate(promoListProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Promo berhasil disimpan!'),
                          backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal menyimpan promo: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoListAsync = ref.watch(promoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Promo & Diskon'),
      ),
      body: promoListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (promos) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(promoListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: promos.length,
              itemBuilder: (context, index) {
                final promo = promos[index];
                return Card(
                  child: ListTile(
                    title: Text(promo.nama,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Tipe: ${promo.tipe.name} | Nilai: ${promo.nilai}${promo.tipe == PromoTipe.PERCENTAGE ? '%' : ''}\n'
                      'Produk: ${promo.produk.map((p) => p.nama).join(', ')}',
                    ),
                    trailing: Switch(
                      value: promo.isActive,
                      onChanged: (value) async {
                        try {
                          final dio = ref.read(dioProvider);
                          await dio.patch('/promo/${promo.id}',
                              data: {'isActive': value});
                          ref.invalidate(promoListProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal mengubah status: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                    onTap: () => _showPromoDialog(context, ref, promo: promo),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPromoDialog(context, ref),
        tooltip: 'Buat Promo Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}
