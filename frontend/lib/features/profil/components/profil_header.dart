import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../models/profil_data_model.dart';

class ProfilHeader extends StatelessWidget {
  final ProfilData profilData;

  const ProfilHeader({
    super.key,
    required this.profilData,
  });

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
}
