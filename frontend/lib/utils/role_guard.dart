import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

class RoleGuard {
  /// Periksa apakah user memiliki akses ke halaman tertentu
  static bool canAccess(Role? userRole, List<Role> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  /// Widget wrapper untuk melindungi halaman dengan role tertentu
  static Widget protect({
    required Widget child,
    required List<Role> allowedRoles,
    required WidgetRef ref,
    Widget? fallback,
  }) {
    final profile = ref.watch(userProfileProvider);
    final userRole = profile != null ? Role.values.byName(profile['role']) : null;

    if (canAccess(userRole, allowedRoles)) {
      return child;
    }

    return fallback ?? const _UnauthorizedPage();
  }
}

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'Akses Ditolak',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Anda tidak memiliki izin untuk mengakses halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Silakan hubungi administrator untuk mendapatkan akses.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
