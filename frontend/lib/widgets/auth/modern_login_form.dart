import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/providers.dart';
import 'modern_text_field.dart';
import 'modern_button.dart';

class ModernLoginForm extends ConsumerStatefulWidget {
  final VoidCallback onToggle;

  const ModernLoginForm({
    super.key,
    required this.onToggle,
  });

  @override
  ConsumerState<ModernLoginForm> createState() => _ModernLoginFormState();
}

class _ModernLoginFormState extends ConsumerState<ModernLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final data = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final response = await dio.post('/auth/login', data: data);
      final accessToken = response.data['accessToken'];

      // Simpan token ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);

      if (_rememberMe) {
        await prefs.setBool('rememberMe', true);
        await prefs.setString('email', _emailController.text.trim());
      }

      // Update state di Riverpod
      ref.read(accessTokenProvider.notifier).state = accessToken;
      ref.read(authStateProvider.notifier).state = true;

      // Navigasi setelah state diupdate
      if (mounted) {
        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Login berhasil!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.of(context).pushReplacementNamed('/home');
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
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe && savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final isSmallScreen = mediaQuery.size.height < 700;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          SizedBox(height: keyboardVisible || isSmallScreen ? 12 : 20),

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
              return null;
            },
          ),
          SizedBox(height: keyboardVisible || isSmallScreen ? 8 : 16),

          // Remember Me & Forgot Password - Hide when keyboard is visible for space
          if (!keyboardVisible && !isSmallScreen) ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ingat saya',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Fitur reset password belum tersedia'),
                        backgroundColor: theme.colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Lupa Password?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 16),
          ],

          ModernButton(
            text: 'Masuk',
            onPressed: _handleLogin,
            isLoading: _isLoading,
            icon: Icons.login,
          ),
          
          // Hide divider and toggle when keyboard is visible or small screen
          if (!keyboardVisible && !isSmallScreen) ...[
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
              text: 'Belum punya akun? Daftar sekarang',
              onPressed: widget.onToggle,
              style: ModernButtonStyle.text,
            ),
          ],
        ],
      ),
    );
  }
}
