import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../utils/role_guard.dart';
import '../../widgets/responsive_widgets.dart';
import '../../models/toko_online_model.dart';
import '../../providers/toko_online_provider.dart';
import 'models/data_toko_model.dart';
import 'providers/data_toko_provider.dart';
import 'components/logo_section.dart';
import 'components/store_info_form.dart';
import 'components/toko_online_section.dart';
import 'controllers/pengaturan_akun_controller.dart';

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
  final _slugController = TextEditingController();

  String _selectedKategori = kategoriBisnisList.first;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // Untuk web
  String? _selectedImageName; // Untuk web
  String? _currentLogoUrl;
  bool _isLoading = false;

  bool _isTokoOnlineActive = false;
  bool _allowPickup = true;
  bool _allowDelivery = false;

  late PengaturanAkunController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PengaturanAkunController(ref);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _slugController.dispose();
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
    await _controller.pickImage(
      onImageSelected: (image) {
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
      },
      onImageBytesSelected: (bytes, name) {
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = name;
          _selectedImage = null;
        });
      },
      showSnackBar: _showSnackBar,
    );
  }

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    await _controller.simpanData(
      nama: _namaController.text,
      alamat: _alamatController.text,
      telepon: _teleponController.text,
      email: _emailController.text,
      kategoriBisnis: _selectedKategori,
      selectedImage: _selectedImage,
      selectedImageBytes: _selectedImageBytes,
      selectedImageName: _selectedImageName,
      onLoadingStart: () => setState(() => _isLoading = true),
      onLoadingEnd: () => setState(() => _isLoading = false),
      showSnackBar: _showSnackBar,
      updateCurrentLogoUrl: (url) => setState(() => _currentLogoUrl = url),
      clearSelectedImages: () => setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedImageName = null;
      }),
    );
  }

  Future<void> _saveTokoOnlineSettings() async {
    await _controller.saveTokoOnlineSettings(
      slug: _slugController.text,
      isActive: _isTokoOnlineActive,
      allowPickup: _allowPickup,
      allowDelivery: _allowDelivery,
    );
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
            LogoSection(
              currentLogoUrl: _currentLogoUrl,
              selectedImage: _selectedImage,
              selectedImageBytes: _selectedImageBytes,
              onPickImage: _pickImage,
            ),
            const SizedBox(height: 24),
            StoreInfoForm(
              namaController: _namaController,
              alamatController: _alamatController,
              teleponController: _teleponController,
              emailController: _emailController,
              selectedKategori: _selectedKategori,
              onKategoriChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedKategori = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            // Toko Online Section
            if (tokoOnlineSettings != null) ...[
              TokoOnlineSection(
                settings: tokoOnlineSettings,
                rekeningBankAsync: rekeningBankAsync,
                isTokoOnlineActive: _isTokoOnlineActive,
                allowPickup: _allowPickup,
                allowDelivery: _allowDelivery,
                slugController: _slugController,
                onSettingsChanged: () {
                  setState(() {
                    _isTokoOnlineActive = !_isTokoOnlineActive;
                    _allowPickup = !_allowPickup;
                    _allowDelivery = !_allowDelivery;
                  });
                  _saveTokoOnlineSettings();
                },
              ),
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
                LogoSection(
                  currentLogoUrl: _currentLogoUrl,
                  selectedImage: _selectedImage,
                  selectedImageBytes: _selectedImageBytes,
                  onPickImage: _pickImage,
                ),
                const SizedBox(height: 32),
                StoreInfoForm(
                  namaController: _namaController,
                  alamatController: _alamatController,
                  teleponController: _teleponController,
                  emailController: _emailController,
                  selectedKategori: _selectedKategori,
                  onKategoriChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedKategori = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                // Toko Online Section
                if (tokoOnlineSettings != null) ...[
                  TokoOnlineSection(
                    settings: tokoOnlineSettings,
                    rekeningBankAsync: rekeningBankAsync,
                    isTokoOnlineActive: _isTokoOnlineActive,
                    allowPickup: _allowPickup,
                    allowDelivery: _allowDelivery,
                    slugController: _slugController,
                    onSettingsChanged: () {
                      setState(() {
                        _isTokoOnlineActive = !_isTokoOnlineActive;
                        _allowPickup = !_allowPickup;
                        _allowDelivery = !_allowDelivery;
                      });
                      _saveTokoOnlineSettings();
                    },
                  ),
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
                      child: LogoSection(
                        currentLogoUrl: _currentLogoUrl,
                        selectedImage: _selectedImage,
                        selectedImageBytes: _selectedImageBytes,
                        onPickImage: _pickImage,
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Form fields di sebelah kanan
                    Expanded(
                      flex: 3,
                      child: StoreInfoForm(
                        namaController: _namaController,
                        alamatController: _alamatController,
                        teleponController: _teleponController,
                        emailController: _emailController,
                        selectedKategori: _selectedKategori,
                        onKategoriChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedKategori = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Toko Online Section (full width)
                if (tokoOnlineSettings != null) ...[
                  TokoOnlineSection(
                    settings: tokoOnlineSettings,
                    rekeningBankAsync: rekeningBankAsync,
                    isTokoOnlineActive: _isTokoOnlineActive,
                    allowPickup: _allowPickup,
                    allowDelivery: _allowDelivery,
                    slugController: _slugController,
                    onSettingsChanged: () {
                      setState(() {
                        _isTokoOnlineActive = !_isTokoOnlineActive;
                        _allowPickup = !_allowPickup;
                        _allowDelivery = !_allowDelivery;
                      });
                      _saveTokoOnlineSettings();
                    },
                  ),
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
