import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/promo_provider.dart';
import '../../providers/providers.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';

class PromoPage extends ConsumerWidget {
  const PromoPage({Key? key}) : super(key: key);

  void _showPromoDialog(BuildContext context, WidgetRef ref, {Promo? promo}) {
    final isEditing = promo != null;
    final formKey = GlobalKey<FormState>();
    
    // State
    final namaController = TextEditingController(text: promo?.nama ?? '');
    final deskripsiController = TextEditingController(text: promo?.deskripsi ?? '');
    PromoTipe? tipe = promo?.tipe;
    final nilaiController = TextEditingController(text: promo?.nilai.toString() ?? '');
    // Gunakan tipe yang lebih spesifik dan aman
    List<Object?> selectedProdukIds = promo?.produk.map((p) => p.id as Object).toList() ?? [];

    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog tertutup saat diklik di luar
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Promo' : 'Buat Promo Baru'),
          content: Consumer(
            builder: (context, ref, child) {
              final produkAsync = ref.watch(allOwnerProductsProvider);
              return produkAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Gagal memuat produk: $e'),
                data: (produkList) {
                  return Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: namaController,
                            decoration: const InputDecoration(labelText: 'Nama Promo'),
                            validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                          TextFormField(controller: deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi')),
                          StatefulBuilder(
                            builder: (BuildContext context, StateSetter setState) {
                              return DropdownButtonFormField<PromoTipe>(
                                value: tipe,
                                hint: const Text('Pilih Tipe Promo'),
                                items: PromoTipe.values.map((PromoTipe value) {
                                  return DropdownMenuItem<PromoTipe>(
                                    value: value,
                                    child: Text(value.name),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() => tipe = newValue);
                                },
                                validator: (value) => value == null ? 'Tipe promo tidak boleh kosong' : null,
                              );
                            },
                          ),
                          TextFormField(
                            controller: nilaiController,
                            decoration: const InputDecoration(labelText: 'Nilai (persen atau nominal)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Nilai tidak boleh kosong' : null,
                          ),
                          MultiSelectFormField(
                            title: const Text("Produk Berlaku"),
                            dataSource: produkList.map((p) => {'display': '${p.nama} (${p.cabangNama})', 'value': p.id}).toList(),
                            textField: 'display',
                            valueField: 'value',
                            okButtonLabel: 'OK',
                            cancelButtonLabel: 'BATAL',
                            hintWidget: const Text('Pilih satu atau lebih produk'),
                            initialValue: selectedProdukIds,
                            onSaved: (value) {
                              // [PERBAIKAN] Mengatasi nilai null dengan aman
                              selectedProdukIds = value ?? [];
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Harap pilih setidaknya satu produk';
                              }
                              return null;
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
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  
                  if (tipe == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tipe promo harus dipilih'), backgroundColor: Colors.red),
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
                      'produkIds': selectedProdukIds.map((e) => e as int).toList(),
                    };

                    if (isEditing && promo != null) {
                      await dio.patch('/promo/${promo.id}', data: data);
                    } else {
                      await dio.post('/promo', data: data);
                    }
                    
                    if (!context.mounted) return;
                    Navigator.of(dialogContext).pop();
                    ref.invalidate(promoListProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Promo berhasil disimpan!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan promo: $e'), backgroundColor: Colors.red),
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
                    title: Text(promo.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Tipe: ${promo.tipe.name} | Nilai: ${promo.nilai}${promo.tipe == PromoTipe.PERCENTAGE ? '%' : ''}\n'
                      'Produk: ${promo.produk.map((p) => p.nama).join(', ')}',
                    ),
                    trailing: Switch(
                      value: promo.isActive,
                      onChanged: (value) async {
                        try {
                          final dio = ref.read(dioProvider);
                          await dio.patch('/promo/${promo.id}', data: {'isActive': value});
                          ref.invalidate(promoListProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red),
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
        child: const Icon(Icons.add),
        tooltip: 'Buat Promo Baru',
      ),
    );
  }
}