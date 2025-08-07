import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../widgets/responsive_widgets.dart';

// Model untuk data profil user
class ProfilData {
  final String namaLengkap;
  final String email;
  final Role role;
  final List<AksesCabang> aksesCabang;

  ProfilData({
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.aksesCabang,
  });

  factory ProfilData.fromJson(Map<String, dynamic> json) {
    var aksesList = json['aksesCabang'] as List? ?? [];
    List<AksesCabang> aksesCabangList =
        aksesList.map((i) => AksesCabang.fromJson(i)).toList();

    return ProfilData(
      namaLengkap: json['namaLengkap'] ?? '',
      email: json['email'] ?? '',
      role: Role.values.byName(json['role']),
      aksesCabang: aksesCabangList,
    );
  }
}

// Provider untuk data profil
final profilDataProvider = FutureProvider.autoDispose<ProfilData>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    print('🔍 Fetching profil data...');
    final response = await dio.get('/auth/profile');
    print('✅ Response received: ${response.data}');
    final profilData = ProfilData.fromJson(response.data['user']);
    return profilData;
  } on DioException catch (e) {
    print('❌ DioException: ${e.message}, Status: ${e.response?.statusCode}');
    rethrow;
  } catch (e) {
    print('❌ General error: $e');
    rethrow;
  }
});

class ProfilPage extends ConsumerStatefulWidget {
  const ProfilPage({super.key});

  @override
  ConsumerState<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends ConsumerState<ProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditingNama = false;
  bool _isChangingPassword = false;
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _namaController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadData(ProfilData data) {
    setState(() {
      _namaController.text = data.namaLengkap;
    });
  }

  Future<void> _updateNama() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = ref.read(dioProvider);

      await dio.patch('/auth/update-profile', data: {
        'namaLengkap': _namaController.text.trim(),
      });

      // Update state di provider
      final currentProfile = ref.read(userProfileProvider);
      if (currentProfile != null) {
        ref.read(userProfileProvider.notifier).state = {
          ...currentProfile,
          'namaLengkap': _namaController.text.trim(),
        };
      }

      // Refresh data profil
      ref.invalidate(profilDataProvider);

      setState(() {
        _isEditingNama = false;
      });

      _showSnackBar('Nama berhasil diperbarui!');
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Gagal memperbarui nama';
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = ref.read(dioProvider);

      await dio.patch('/auth/change-password', data: {
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      });

      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      _showSnackBar('Password berhasil diubah!');
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Gagal mengubah password';
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

  String _getRoleDisplayName(Role role) {
    switch (role) {
      case Role.OWNER:
        return 'Pemilik';
      case Role.ADMIN:
        return 'Admin';
      case Role.KASIR:
        return 'Kasir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final profilAsync = ref.watch(profilDataProvider);

          return profilAsync.when(
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
                    onPressed: () => ref.invalidate(profilDataProvider),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            data: (profilData) {
              // Load data ke form controllers
              if (_namaController.text.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadData(profilData);
                });
              }

              return _buildForm(context, profilData);
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProfilData profilData) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(profilData),
      tablet: _buildTabletLayout(profilData),
      desktop: _buildDesktopLayout(profilData),
    );
  }

  Widget _buildMobileLayout(ProfilData profilData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(profilData),
            const SizedBox(height: 24),
            _buildPersonalInfoSection(profilData),
            const SizedBox(height: 24),
            _buildPasswordSection(),
            const SizedBox(height: 24),
            _buildAccessSection(profilData),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(ProfilData profilData) {
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
                _buildProfileHeader(profilData),
                const SizedBox(height: 32),
                _buildPersonalInfoSection(profilData),
                const SizedBox(height: 32),
                _buildPasswordSection(),
                const SizedBox(height: 32),
                _buildAccessSection(profilData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ProfilData profilData) {
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
                // Profil header di sebelah kiri
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildProfileHeader(profilData),
                      const SizedBox(height: 32),
                      _buildAccessSection(profilData),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Form fields di sebelah kanan
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPersonalInfoSection(profilData),
                      const SizedBox(height: 32),
                      _buildPasswordSection(),
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

  Widget _buildProfileHeader(ProfilData profilData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                profilData.namaLengkap.isNotEmpty
                    ? profilData.namaLengkap[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profilData.namaLengkap,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getRoleDisplayName(profilData.role),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profilData.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(ProfilData profilData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Personal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Nama Lengkap
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditingNama,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap tidak boleh kosong';
                      }
                      if (value.trim().length < 2) {
                        return 'Nama lengkap minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isEditingNama)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingNama = true;
                      });
                    },
                    tooltip: 'Edit Nama',
                  ),
              ],
            ),

            if (_isEditingNama) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditingNama = false;
                          _namaController.text = profilData.namaLengkap;
                        });
                      },
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateNama,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              initialValue: profilData.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.lock, color: Colors.grey),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Keamanan Akun',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (!_isChangingPassword)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isChangingPassword = true;
                      });
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Ubah Password'),
                  ),
              ],
            ),
            if (_isChangingPassword) ...[
              const SizedBox(height: 24),

              // Password Saat Ini
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showCurrentPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password saat ini tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Baru
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Konfirmasi Password Baru
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isChangingPassword = false;
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ubah Password'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              const Text(
                'Klik "Ubah Password" untuk mengubah password akun Anda.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessSection(ProfilData profilData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akses Cabang',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (profilData.role == Role.OWNER) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akses Penuh',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'Sebagai pemilik, Anda memiliki akses ke semua cabang dan fitur.',
                            style: TextStyle(color: Colors.green[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (profilData.aksesCabang.isNotEmpty) ...[
              ...profilData.aksesCabang.map((akses) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            akses.namaCabang,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Belum Ada Akses',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          Text(
                            'Anda belum memiliki akses ke cabang manapun. Hubungi pemilik untuk mendapatkan akses.',
                            style: TextStyle(color: Colors.orange[600]),
                          ),
                        ],
                      ),
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
}
