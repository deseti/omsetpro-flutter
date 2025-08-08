import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../utils/role_guard.dart';
import '../../widgets/responsive_widgets.dart';
import '../../models/toko_online_model.dart';
import '../../providers/toko_online_provider.dart';
import '../../utils/currency_formatter.dart';

// Model untuk data toko
class DataToko {
  final String nama;
  final String? logoUrl;
  final String alamat;
  final String telepon;
  final String email;
  final String kategoriBisnis;

  DataToko({
    required this.nama,
    this.logoUrl,
    required this.alamat,
    required this.telepon,
    required this.email,
    required this.kategoriBisnis,
  });

  factory DataToko.fromJson(Map<String, dynamic> json) {
    return DataToko(
      nama: json['nama'] ?? '',
      logoUrl: json['logoUrl'],
      alamat: json['alamat'] ?? '',
      telepon: json['telepon'] ?? '',
      email: json['email'] ?? '',
      kategoriBisnis: json['kategoriBisnis'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'logoUrl': logoUrl,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'kategoriBisnis': kategoriBisnis,
    };
  }
}

// Provider untuk data toko
final dataTokoProvider = FutureProvider.autoDispose<DataToko>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    print('🔍 Fetching akun toko data...');
    final response = await dio.get('/pengaturan/akun-toko');
    print('✅ Response received: ${response.data}');
    final dataToko = DataToko.fromJson(response.data);
    print('📋 Parsed data toko - logoUrl: ${dataToko.logoUrl}');
    return dataToko;
  } on DioException catch (e) {
    print('❌ DioException: ${e.message}, Status: ${e.response?.statusCode}');
    if (e.response?.statusCode == 404) {
      // Jika belum ada data, return data kosong
      print('📝 Returning empty data for 404');
      return DataToko(
        nama: '',
        alamat: '',
        telepon: '',
        email: '',
        kategoriBisnis: '',
      );
    }
    rethrow;
  } catch (e) {
    print('❌ General error: $e');
    rethrow;
  }
});

// Daftar kategori bisnis
const List<String> kategoriBisnisList = [
  'Makanan & Minuman',
  'Fashion & Pakaian',
  'Elektronik',
  'Kecantikan & Kesehatan',
  'Rumah Tangga',
  'Otomotif',
  'Olahraga & Outdoor',
  'Buku & Alat Tulis',
  'Mainan & Hobi',
  'Jasa & Layanan',
  'Lainnya',
];

class PengaturanAkunPage extends ConsumerStatefulWidget {
  const PengaturanAkunPage({super.key});

  @override
  ConsumerState<PengaturanAkunPage> createState() => _PengaturanAkunPageState();
}

class _PengaturanAkunPageState extends ConsumerState<PengaturanAkunPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedKategori = kategoriBisnisList.first;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // Untuk web
  String? _selectedImageName; // Untuk web
  String? _currentLogoUrl;
  bool _isLoading = false;

  // Toko Online related controllers and variables
  final _slugController = TextEditingController();
  final _bankFormKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _resiController = TextEditingController();
  final _kurirController = TextEditingController();

  bool _isTokoOnlineActive = false;
  bool _allowPickup = true;
  bool _allowDelivery = false;
  bool _showAddBankForm = false;

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _slugController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _resiController.dispose();
    _kurirController.dispose();
    super.dispose();
  }

  void _loadData(DataToko data) {
    print('📥 Loading data into form: $data');
    print('🖼️ Current logoUrl: ${data.logoUrl}');

    setState(() {
      _namaController.text = data.nama;
      _alamatController.text = data.alamat;
      _teleponController.text = data.telepon;
      _emailController.text = data.email;
      _selectedKategori = data.kategoriBisnis.isNotEmpty
          ? data.kategoriBisnis
          : kategoriBisnisList.first;
      _currentLogoUrl = data.logoUrl;
    });

    print('✅ Data loaded - currentLogoUrl set to: $_currentLogoUrl');
  }

  void _loadTokoOnlineData(TokoOnlineSettings settings) {
    setState(() {
      if (_slugController.text.isEmpty) {
        _slugController.text = settings.tokoOnlineSlug ?? '';
      }
      _isTokoOnlineActive = settings.isTokoOnlineActive;
      _allowPickup = settings.allowPickup;
      _allowDelivery = settings.allowDelivery;
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Untuk web, baca sebagai bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = pickedFile.name;
            _selectedImage = null; // Clear file untuk web
          });
        } else {
          // Untuk mobile/desktop
          setState(() {
            _selectedImage = File(pickedFile.path);
            _selectedImageBytes = null; // Clear bytes untuk mobile
            _selectedImageName = null;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', isError: true);
    }
  }

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = ref.read(dioProvider);

      print('💾 Preparing to save akun toko...');

      // Siapkan data form
      final formData = FormData.fromMap({
        'nama': _namaController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'telepon': _teleponController.text.trim(),
        'email': _emailController.text.trim(),
        'kategoriBisnis': _selectedKategori,
      });

      print('📝 Form data prepared: ${formData.fields}');

      // Upload logo jika ada gambar baru
      if (_selectedImage != null || _selectedImageBytes != null) {
        print('🖼️ Logo file detected, adding to form...');
        if (kIsWeb && _selectedImageBytes != null) {
          // Untuk web, gunakan bytes
          print(
              '🌐 Web platform - using bytes (${_selectedImageBytes!.length} bytes)');
          formData.files.add(
            MapEntry(
              'logo',
              MultipartFile.fromBytes(
                _selectedImageBytes!,
                filename: _selectedImageName ?? 'logo_toko.jpg',
              ),
            ),
          );
        } else if (!kIsWeb && _selectedImage != null) {
          // Untuk mobile/desktop, gunakan file
          print('📱 Mobile platform - using file: ${_selectedImage!.path}');
          formData.files.add(
            MapEntry(
              'logo',
              await MultipartFile.fromFile(
                _selectedImage!.path,
                filename: 'logo_toko.jpg',
              ),
            ),
          );
        }
      } else {
        print('🚫 No logo file to upload');
      }

      print('📤 Sending POST request to /pengaturan/akun-toko...');
      final response = await dio.post('/pengaturan/akun-toko', data: formData);
      print('✅ Response received: ${response.data}');

      // Update currentLogoUrl jika ada logoUrl di response
      if (response.data != null && response.data['logoUrl'] != null) {
        setState(() {
          _currentLogoUrl = response.data['logoUrl'];
          print('🔄 Updated _currentLogoUrl to: $_currentLogoUrl');
        });
      }

      // Clear selected images setelah upload berhasil
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      // Refresh data
      print('🔄 Refreshing data provider...');
      ref.invalidate(dataTokoProvider);

      _showSnackBar('Data toko berhasil disimpan!');
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal menyimpan data toko';
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard.protect(
      allowedRoles: [Role.OWNER],
      ref: ref,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Toko'),
          elevation: 0,
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final dataTokoAsync = ref.watch(dataTokoProvider);
            final tokoOnlineSettingsAsync =
                ref.watch(tokoOnlineSettingsProvider);
            final rekeningBankAsync = ref.watch(rekeningBankProvider);

            return dataTokoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(dataTokoProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (dataToko) {
                // Load data ke form controllers hanya jika belum di-load
                if (_namaController.text.isEmpty ||
                    _currentLogoUrl != dataToko.logoUrl) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadData(dataToko);
                  });
                }

                return tokoOnlineSettingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      _buildForm(context, null, rekeningBankAsync),
                  data: (tokoOnlineSettings) {
                    // Load toko online data
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadTokoOnlineData(tokoOnlineSettings);
                    });

                    return _buildForm(
                        context, tokoOnlineSettings, rekeningBankAsync);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context,
      TokoOnlineSettings? tokoOnlineSettings,
      AsyncValue<List<RekeningBank>>? rekeningBankAsync) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(tokoOnlineSettings, rekeningBankAsync),
      tablet: _buildTabletLayout(tokoOnlineSettings, rekeningBankAsync),
      desktop: _buildDesktopLayout(tokoOnlineSettings, rekeningBankAsync),
    );
  }

  Widget _buildMobileLayout(TokoOnlineSettings? tokoOnlineSettings,
      AsyncValue<List<RekeningBank>>? rekeningBankAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogoSection(),
            const SizedBox(height: 24),
            _buildFormFields(),
            const SizedBox(height: 24),
            // Toko Online Section
            if (tokoOnlineSettings != null) ...[
              _buildTokoOnlineSection(tokoOnlineSettings, rekeningBankAsync),
              const SizedBox(height: 24),
            ],
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(TokoOnlineSettings? tokoOnlineSettings,
      AsyncValue<List<RekeningBank>>? rekeningBankAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogoSection(),
                const SizedBox(height: 32),
                _buildFormFields(),
                const SizedBox(height: 32),
                // Toko Online Section
                if (tokoOnlineSettings != null) ...[
                  _buildTokoOnlineSection(
                      tokoOnlineSettings, rekeningBankAsync),
                  const SizedBox(height: 32),
                ],
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(TokoOnlineSettings? tokoOnlineSettings,
      AsyncValue<List<RekeningBank>>? rekeningBankAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo section di sebelah kiri
                    Expanded(
                      flex: 2,
                      child: _buildLogoSection(),
                    ),
                    const SizedBox(width: 32),
                    // Form fields di sebelah kanan
                    Expanded(
                      flex: 3,
                      child: _buildFormFields(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Toko Online Section (full width)
                if (tokoOnlineSettings != null) ...[
                  _buildTokoOnlineSection(
                      tokoOnlineSettings, rekeningBankAsync),
                  const SizedBox(height: 32),
                ],
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Logo Toko',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _buildLogoContent(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload),
              label: const Text('Pilih Logo'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: JPG, PNG (maks. 2MB)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoContent() {
    print('🖼️ Building logo content...');
    print('- _selectedImageBytes != null: ${_selectedImageBytes != null}');
    print('- _selectedImage != null: ${_selectedImage != null}');
    print('- _currentLogoUrl: $_currentLogoUrl');
    print('- kIsWeb: $kIsWeb');

    // Prioritas: bytes (web) > file (mobile) > network image > placeholder
    if (kIsWeb && _selectedImageBytes != null) {
      print('✅ Using selected image bytes (web)');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _selectedImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (!kIsWeb && _selectedImage != null) {
      print('✅ Using selected image file (mobile)');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
      print('✅ Using network image from URL: $_currentLogoUrl');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _currentLogoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('✅ Network image loaded successfully');
              return child;
            }
            print(
                '⏳ Loading network image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading network image: $error');
            return _buildLogoPlaceholder();
          },
        ),
      );
    } else {
      print('📋 Using placeholder (no image available)');
      return _buildLogoPlaceholder();
    }
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.store,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Logo Toko',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Toko',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Toko *',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama toko tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamatController,
              decoration: const InputDecoration(
                labelText: 'Alamat Toko *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat toko tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teleponController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Toko *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: const InputDecoration(
                labelText: 'Kategori Bisnis *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: kategoriBisnisList.map((kategori) {
                return DropdownMenuItem(
                  value: kategori,
                  child: Text(kategori),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedKategori = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kategori bisnis harus dipilih';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _simpanData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan Pengaturan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Toko Online Sections
  Widget _buildTokoOnlineSection(TokoOnlineSettings tokoOnlineSettings,
      AsyncValue<List<RekeningBank>>? rekeningBankAsync) {
    return Column(
      children: [
        _buildActivationCard(tokoOnlineSettings),
        const SizedBox(height: 16),
        if (_isTokoOnlineActive) ...[
          _buildSlugSettingsCard(tokoOnlineSettings),
          const SizedBox(height: 16),
          _buildDeliveryOptionsCard(),
          const SizedBox(height: 16),
          _buildQRCodeCard(tokoOnlineSettings),
          const SizedBox(height: 16),
          if (rekeningBankAsync != null)
            _buildBankAccountsCard(rekeningBankAsync),
          const SizedBox(height: 16),
          _buildShippingTrackingCard(),
        ],
      ],
    );
  }

  Widget _buildActivationCard(TokoOnlineSettings settings) {
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
              value: _isTokoOnlineActive,
              onChanged: (value) {
                setState(() {
                  _isTokoOnlineActive = value;
                });
                _saveTokoOnlineSettings();
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
              onChanged: (value) => _saveTokoOnlineSettings(),
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
                _saveTokoOnlineSettings();
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
                _saveTokoOnlineSettings();
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
                  _showSnackBar('Info pengiriman berhasil disimpan!');
                  _resiController.clear();
                  _kurirController.clear();
                } else {
                  _showSnackBar('Harap lengkapi nomor resi dan nama kurir',
                      isError: true);
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

  // Toko Online helper methods
  String? _validateSlug(String? value) {
    if (value?.isEmpty == true) {
      return 'Slug harus diisi';
    }
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value!)) {
      return 'Hanya boleh huruf kecil, angka, dan tanda hubung';
    }
    return null;
  }

  Future<void> _saveTokoOnlineSettings() async {
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
}
