import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../utils/role_guard.dart';
import '../../widgets/responsive_widgets.dart';

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

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
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
          title: const Text('Pengaturan Akun Toko'),
          elevation: 0,
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final dataTokoAsync = ref.watch(dataTokoProvider);

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

                return _buildForm(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
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
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
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
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFormFields(),
                      const SizedBox(height: 40),
                      _buildSaveButton(),
                    ],
                  ),
                ),
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
}
