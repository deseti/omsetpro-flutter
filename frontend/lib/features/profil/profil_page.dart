import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/profil_data_model.dart';
import 'providers/profil_data_provider.dart';
import 'controllers/profil_controller.dart';
import 'components/personal_info_section.dart';
import 'components/password_section.dart';
import 'layouts/profil_layouts.dart';
import '../../widgets/responsive_widgets.dart';

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

  late ProfilController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfilController(
      ref: ref,
      formKey: _formKey,
      namaController: _namaController,
      currentPasswordController: _currentPasswordController,
      newPasswordController: _newPasswordController,
      confirmPasswordController: _confirmPasswordController,
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadData(ProfilData data) {
    _controller.loadData(data);
  }

  Future<void> _updateNama() async {
    await _controller.updateNama(
      onSuccess: () {
        setState(() {
          _isEditingNama = false;
        });
        _showSnackBar('Nama berhasil diperbarui!');
      },
      onError: (message) {
        _showSnackBar(message, isError: true);
      },
      onStartLoading: () {
        setState(() {
          _isLoading = true;
        });
      },
      onStopLoading: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _changePassword() async {
    await _controller.changePassword(
      onSuccess: () {
        _showSnackBar('Password berhasil diubah!');
      },
      onError: (message) {
        _showSnackBar(message, isError: true);
      },
      onStartLoading: () {
        setState(() {
          _isLoading = true;
        });
      },
      onStopLoading: () {
        setState(() {
          _isLoading = false;
        });
      },
      onClearFields: () {
        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Consumer(
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
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProfilData profilData) {
    final personalInfoSection = PersonalInfoSection(
      profilData: profilData,
      namaController: _namaController,
      isEditingNama: _isEditingNama,
      isLoading: _isLoading,
      onEditPressed: () {
        setState(() {
          _isEditingNama = true;
        });
      },
      onCancelPressed: () {
        setState(() {
          _isEditingNama = false;
          _namaController.text = profilData.namaLengkap;
        });
      },
      onSavePressed: _updateNama,
    );

    final passwordSection = PasswordSection(
      currentPasswordController: _currentPasswordController,
      newPasswordController: _newPasswordController,
      confirmPasswordController: _confirmPasswordController,
      isChangingPassword: _isChangingPassword,
      isLoading: _isLoading,
      showCurrentPassword: _showCurrentPassword,
      showNewPassword: _showNewPassword,
      showConfirmPassword: _showConfirmPassword,
      onChangePasswordPressed: () {
        setState(() {
          _isChangingPassword = true;
        });
      },
      onCancelPressed: () {
        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      },
      onSavePressed: _changePassword,
      onToggleCurrentPassword: () {
        setState(() {
          _showCurrentPassword = !_showCurrentPassword;
        });
      },
      onToggleNewPassword: () {
        setState(() {
          _showNewPassword = !_showNewPassword;
        });
      },
      onToggleConfirmPassword: () {
        setState(() {
          _showConfirmPassword = !_showConfirmPassword;
        });
      },
    );

    return ResponsiveLayout(
      mobile: ProfilLayouts.buildMobileLayout(
          profilData, personalInfoSection, passwordSection),
      tablet: ProfilLayouts.buildTabletLayout(
          profilData, personalInfoSection, passwordSection),
      desktop: ProfilLayouts.buildDesktopLayout(
          profilData, personalInfoSection, passwordSection),
    );
  }
}
