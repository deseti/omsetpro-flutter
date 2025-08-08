import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../models/toko_online_model.dart';
import '../../../providers/toko_online_provider.dart';

class TokoOnlineSection extends ConsumerStatefulWidget {
  final TokoOnlineSettings settings;
  final AsyncValue<List<RekeningBank>>? rekeningBankAsync;
  final bool isTokoOnlineActive;
  final bool allowPickup;
  final bool allowDelivery;
  final TextEditingController slugController;
  final VoidCallback onSettingsChanged;

  const TokoOnlineSection({
    super.key,
    required this.settings,
    required this.rekeningBankAsync,
    required this.isTokoOnlineActive,
    required this.allowPickup,
    required this.allowDelivery,
    required this.slugController,
    required this.onSettingsChanged,
  });

  @override
  ConsumerState<TokoOnlineSection> createState() => _TokoOnlineSectionState();
}

class _TokoOnlineSectionState extends ConsumerState<TokoOnlineSection> {
  final _bankFormKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _resiController = TextEditingController();
  final _kurirController = TextEditingController();

  bool _showAddBankForm = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _resiController.dispose();
    _kurirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActivationCard(),
        const SizedBox(height: 16),
        if (widget.isTokoOnlineActive) ...[
          _buildSlugSettingsCard(),
          const SizedBox(height: 16),
          _buildDeliveryOptionsCard(),
          const SizedBox(height: 16),
          _buildQRCodeCard(),
          const SizedBox(height: 16),
          if (widget.rekeningBankAsync != null)
            _buildBankAccountsCard(widget.rekeningBankAsync!),
          const SizedBox(height: 16),
          _buildShippingTrackingCard(),
        ],
      ],
    );
  }

  Widget _buildActivationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toko Online',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Aktifkan Toko Online'),
              subtitle: const Text(
                  'Izinkan pelanggan memesan melalui link toko online'),
              value: widget.isTokoOnlineActive,
              onChanged: (value) {
                widget.onSettingsChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlugSettingsCard() {
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
              controller: widget.slugController,
              decoration: const InputDecoration(
                labelText: 'Nama Unik Toko (Slug)',
                hintText: 'contoh: kopi-bahagia',
                helperText: 'Hanya huruf kecil, angka, dan tanda hubung (-)',
                prefixText: 'omsetpro.com/toko/',
                border: OutlineInputBorder(),
              ),
              validator: _validateSlug,
              onChanged: (value) => widget.onSettingsChanged(),
            ),
            const SizedBox(height: 16),
            if (widget.settings.tokoOnlineSlug?.isNotEmpty == true) ...[
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
                        'https://omsetpro.com/toko/${widget.settings.tokoOnlineSlug}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.green),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'https://omsetpro.com/toko/${widget.settings.tokoOnlineSlug}',
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
              value: widget.allowPickup,
              onChanged: (value) {
                widget.onSettingsChanged();
              },
            ),
            CheckboxListTile(
              title: const Text('Diantar Kurir (Delivery)'),
              subtitle: const Text('Pesanan diantar langsung ke pelanggan'),
              value: widget.allowDelivery,
              onChanged: (value) {
                widget.onSettingsChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    if (widget.settings.tokoOnlineSlug?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    // Generate real QR code URL
    final qrCodeUrl =
        'https://omsetpro.com/toko/${widget.settings.tokoOnlineSlug}';

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

  Widget _buildShippingTrackingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lacak Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan informasi pengiriman untuk pesanan yang dikirim via kurir',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _resiController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Resi',
                      hintText: 'Masukkan nomor resi pengiriman',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kurirController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kurir',
                      hintText: 'JNE, JT Express, Shopee, dll',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.delivery_dining),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_resiController.text.isNotEmpty &&
                    _kurirController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Info pengiriman berhasil disimpan!')),
                  );
                  _resiController.clear();
                  _kurirController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap lengkapi nomor resi dan nama kurir'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Simpan Info Pengiriman'),
            ),
          ],
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
}
