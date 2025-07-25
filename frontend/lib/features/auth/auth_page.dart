import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/auth/modern_auth_container.dart';
import '../../widgets/auth/modern_login_form.dart';
import '../../widgets/auth/modern_register_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool _isLoginPage = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePage() {
    setState(() {
      _isLoginPage = !_isLoginPage;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ModernAuthContainer(
      title: _isLoginPage ? 'Selamat Datang Kembali' : 'Buat Akun Baru',
      subtitle: _isLoginPage
          ? 'Masuk ke akun Anda untuk melanjutkan'
          : 'Daftar untuk memulai perjalanan bisnis Anda',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoginPage
            ? ModernLoginForm(onToggle: _togglePage)
            : ModernRegisterForm(onToggle: _togglePage),
      ),
    );
  }
}
