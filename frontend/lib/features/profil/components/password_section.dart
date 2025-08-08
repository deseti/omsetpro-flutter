import 'package:flutter/material.dart';

class PasswordSection extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isChangingPassword;
  final bool isLoading;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool showConfirmPassword;
  final VoidCallback onChangePasswordPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;

  const PasswordSection({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isChangingPassword,
    required this.isLoading,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.showConfirmPassword,
    required this.onChangePasswordPressed,
    required this.onCancelPressed,
    required this.onSavePressed,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
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
                if (!isChangingPassword)
                  TextButton.icon(
                    onPressed: onChangePasswordPressed,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Ubah Password'),
                  ),
              ],
            ),
            if (isChangingPassword) ...[
              const SizedBox(height: 24),

              // Password Saat Ini
              TextFormField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: onToggleCurrentPassword,
                  ),
                ),
                obscureText: !showCurrentPassword,
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
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(showNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: onToggleNewPassword,
                  ),
                ),
                obscureText: !showNewPassword,
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
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: onToggleConfirmPassword,
                  ),
                ),
                obscureText: !showConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != newPasswordController.text) {
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
                      onPressed: onCancelPressed,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSavePressed,
                      child: isLoading
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
}
