import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/toko_online_model.dart';
import '../providers/toko_online_provider.dart';
import '../utils/currency_formatter.dart';

class TokoOnlinePage extends ConsumerStatefulWidget {
  const TokoOnlinePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TokoOnlinePage> createState() => _TokoOnlinePageState();
}

class _TokoOnlinePageState extends ConsumerState<TokoOnlinePage> {
  final _slugController = TextEditingController();
  final _bankFormKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isTokoOnlineActive = false;
  bool _allowPickup = true;
  bool _allowDelivery = false;
  bool _showAddBankForm = false;

  @override
  void dispose() {
    _slugController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(tokoOnlineSettingsProvider);
    final rekeningBankAsync = ref.watch(rekeningBankProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Toko Online'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(tokoOnlineSettingsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (settings) {
          _updateFormFromSettings(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivationCard(settings),
                const SizedBox(height: 16),
                if (_isTokoOnlineActive) ...[
                  _buildSlugSettingsCard(settings),
                  const SizedBox(height: 16),
                  _buildDeliveryOptionsCard(),
                  const SizedBox(height: 16),
                  _buildQRCodeCard(settings),
                  const SizedBox(height: 16),
                  _buildBankAccountsCard(rekeningBankAsync),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateFormFromSettings(TokoOnlineSettings settings) {
    if (_slugController.text.isEmpty) {
      _slugController.text = settings.tokoOnlineSlug ?? '';
    }
    _isTokoOnlineActive = settings.isTokoOnlineActive;
    _allowPickup = settings.allowPickup;
    _allowDelivery = settings.allowDelivery;
  }

  Widget _buildActivationCard(TokoOnlineSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Toko Online',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Aktifkan Toko Online'),
              subtitle: const Text(
                  'Izinkan pelanggan memesan melalui link toko online'),
              value: _isTokoOnlineActive,
              onChanged: (value) {
                setState(() {
                  _isTokoOnlineActive = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlugSettingsCard(TokoOnlineSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link Toko Online',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Nama Unik Toko (Slug)',
                hintText: 'contoh: kopi-bahagia',
                helperText: 'Hanya huruf kecil, angka, dan tanda hubung (-)',
                prefixText: 'omsetpro.com/toko/',
                border: OutlineInputBorder(),
              ),
              validator: _validateSlug,
              onChanged: (value) => _saveSettings(),
            ),
            const SizedBox(height: 16),
            if (settings.tokoOnlineSlug?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'https://omsetpro.com/toko/${settings.tokoOnlineSlug}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.green),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'https://omsetpro.com/toko/${settings.tokoOnlineSlug}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link disalin!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opsi Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Ambil di Tempat (Pickup)'),
              subtitle:
                  const Text('Pelanggan bisa ambil pesanan langsung di toko'),
              value: _allowPickup,
              onChanged: (value) {
                setState(() {
                  _allowPickup = value ?? true;
                });
                _saveSettings();
              },
            ),
            CheckboxListTile(
              title: const Text('Diantar Kurir (Delivery)'),
              subtitle: const Text('Pesanan diantar langsung ke pelanggan'),
              value: _allowDelivery,
              onChanged: (value) {
                setState(() {
                  _allowDelivery = value ?? false;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard(TokoOnlineSettings settings) {
    if (settings.tokoOnlineSlug?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    // Generate real QR code URL
    final qrCodeUrl = 'https://omsetpro.com/toko/${settings.tokoOnlineSlug}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code Toko Online',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrCodeUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      // Add logo/emblem if needed
                      embeddedImage: null, // Could add store logo here
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      qrCodeUrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pelanggan bisa scan QR Code ini untuk langsung mengakses toko online Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: qrCodeUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Link disalin ke clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade800,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _saveQRCodeToGallery(context, qrCodeUrl),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Simpan QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountsCard(
      AsyncValue<List<RekeningBank>> rekeningBankAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekening Bank',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddBankForm = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Daftar rekening bank yang akan ditampilkan kepada pelanggan untuk pembayaran',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_showAddBankForm) _buildAddBankForm(),
            rekeningBankAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (rekeningList) {
                if (rekeningList.isEmpty) {
                  return const Card(
                    color: Colors.orange,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada rekening bank yang ditambahkan.\nTambah rekening agar pelanggan bisa melakukan pembayaran.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rekeningList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final rekening = rekeningList[index];
                    return ListTile(
                      leading: const Icon(Icons.account_balance),
                      title: Text(rekening.namaBank),
                      subtitle: Text(
                          '${rekening.nomorRekening}\na.n. ${rekening.namaPemilik}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRekening(rekening.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBankForm() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _bankFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Rekening Bank',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bank',
                  hintText: 'contoh: BCA, Mandiri, BRI',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Nama bank harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Rekening',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Nomor rekening harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Nama pemilik harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAddBankForm = false;
                        _clearBankForm();
                      });
                    },
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addRekening,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateSlug(String? value) {
    if (value?.isEmpty == true) {
      return 'Slug harus diisi';
    }
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value!)) {
      return 'Hanya boleh huruf kecil, angka, dan tanda hubung';
    }
    return null;
  }

  Future<void> _saveSettings() async {
    final settings = TokoOnlineSettings(
      tokoOnlineSlug: _slugController.text.trim(),
      isTokoOnlineActive: _isTokoOnlineActive,
      allowPickup: _allowPickup,
      allowDelivery: _allowDelivery,
    );

    await ref
        .read(tokoOnlineSettingsProvider.notifier)
        .updateSettings(settings);
  }

  void _clearBankForm() {
    _bankNameController.clear();
    _accountNumberController.clear();
    _accountNameController.clear();
  }

  Future<void> _addRekening() async {
    if (!_bankFormKey.currentState!.validate()) return;

    final rekening = RekeningBank(
      namaBank: _bankNameController.text.trim(),
      nomorRekening: _accountNumberController.text.trim(),
      namaPemilik: _accountNameController.text.trim(),
    );

    await ref.read(rekeningBankProvider.notifier).addRekening(rekening);

    setState(() {
      _showAddBankForm = false;
    });
    _clearBankForm();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekening bank berhasil ditambahkan!')),
      );
    }
  }

  Future<void> _deleteRekening(int rekeningId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rekening'),
        content: const Text('Yakin ingin menghapus rekening bank ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(rekeningBankProvider.notifier).deleteRekening(rekeningId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rekening bank berhasil dihapus!')),
        );
      }
    }
  }

  /// Save QR Code to device gallery (implementation for future enhancement)
  Future<void> _saveQRCodeToGallery(BuildContext context, String qrData) async {
    try {
      // For now, show a message about the feature
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Fitur simpan QR Code ke galeri akan segera hadir!\n'
            'Sementara Anda bisa screenshot halaman ini.',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Copy Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrData));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link QR disalin!')),
              );
            },
          ),
        ),
      );

      // TODO: Implement actual QR code image generation and save to gallery
      // This would require:
      // 1. Convert QR widget to image
      // 2. Save to device gallery with proper permissions
      // 3. Handle platform-specific gallery access (iOS Photos, Android MediaStore)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
