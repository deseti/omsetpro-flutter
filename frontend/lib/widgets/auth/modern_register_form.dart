import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/providers.dart';
import '../../services/network_service.dart';
import 'modern_text_field.dart';
import 'modern_button.dart';

class ModernRegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onToggle;

  const ModernRegisterForm({
    super.key,
    required this.onToggle,
  });

  @override
  ConsumerState<ModernRegisterForm> createState() => _ModernRegisterFormState();
}

class _ModernRegisterFormState extends ConsumerState<ModernRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Anda harus menyetujui syarat dan ketentuan'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting registration process...');

      // Gunakan NetworkService yang sudah support fallback URLs
      final dio = await NetworkService.getDio();

      final data = {
        'namaLengkap': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      print(
          '📡 Sending register request to: ${dio.options.baseUrl}/auth/register');
      final response = await dio.post('/auth/register', data: data);
      print('✅ Registration response received: ${response.statusCode}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(response.data is Map<String, dynamic>
                    ? (response.data['message']?.toString() ??
                        'Registrasi berhasil!')
                    : 'Registrasi berhasil!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Pindah ke form login setelah sukses
        widget.onToggle();
      }
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan jaringan.';

      try {
        if (e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message']?.toString() ??
                'Terjadi kesalahan server.';
          } else if (responseData is String) {
            errorMessage = responseData;
          }
        }
      } catch (_) {
        errorMessage = 'Terjadi kesalahan tidak terduga.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $errorMessage')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenHeight < 700; // Small screen detection
    const isWeb = kIsWeb;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernTextField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap Anda',
            prefixIcon: Icons.person_outline,
            controller: _namaController,
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama lengkap tidak boleh kosong';
              }
              if (value.trim().length < 2) {
                return 'Nama lengkap minimal 2 karakter';
              }
              return null;
            },
          ),
          SizedBox(
              height: isWeb ? 20 : (keyboardVisible || isSmallScreen ? 8 : 20)),

          ModernTextField(
            label: 'Email',
            hint: 'Masukkan email Anda',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          SizedBox(
              height: isWeb ? 20 : (keyboardVisible || isSmallScreen ? 8 : 20)),

          ModernTextField(
            label: 'Password',
            hint: 'Masukkan password Anda',
            prefixIcon: Icons.lock_outline,
            controller: _passwordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                return 'Password harus mengandung huruf dan angka';
              }
              return null;
            },
          ),
          SizedBox(
              height: isWeb ? 20 : (keyboardVisible || isSmallScreen ? 8 : 20)),

          ModernTextField(
            label: 'Konfirmasi Password',
            hint: 'Ulangi password Anda',
            prefixIcon: Icons.lock_outline,
            controller: _confirmPasswordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password tidak boleh kosong';
              }
              if (value != _passwordController.text) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ),
          SizedBox(
              height: isWeb ? 20 : (keyboardVisible || isSmallScreen ? 8 : 20)),

          // Terms and Conditions - Always visible on web
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setuju syarat & ketentuan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: isWeb
                        ? 14
                        : (keyboardVisible || isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
              height:
                  isWeb ? 32 : (keyboardVisible || isSmallScreen ? 12 : 32)),

          ModernButton(
            text: 'Daftar',
            onPressed: _handleRegister,
            isLoading: _isLoading,
            icon: Icons.person_add,
          ),

          // Always show toggle on web, hide on mobile when keyboard/small screen
          if (isWeb || (!keyboardVisible && !isSmallScreen)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'atau',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                Expanded(
                    child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 16),
            ModernButton(
              text: 'Sudah punya akun? Masuk sekarang',
              onPressed: widget.onToggle,
              style: ModernButtonStyle.text,
            ),
          ],
        ],
      ),
    );
  }
}
