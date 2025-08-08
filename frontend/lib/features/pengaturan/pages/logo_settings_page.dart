// lib/features/pengaturan/pages/logo_settings_page.dart
// Halaman pengaturan logo usaha untuk struk

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/logo_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class LogoSettingsPage extends ConsumerStatefulWidget {
  const LogoSettingsPage({super.key});

  @override
  ConsumerState<LogoSettingsPage> createState() => _LogoSettingsPageState();
}

class _LogoSettingsPageState extends ConsumerState<LogoSettingsPage> {
  bool _isLoading = false;
  Map<String, dynamic> _logoInfo = {};
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _loadLogoInfo();
  }

  Future<void> _loadLogoInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await LogoService.getLogoInfo();
      final bytes = info['hasLogo'] ? await LogoService.getLogoBytes() : null;

      setState(() {
        _logoInfo = info;
        _logoBytes = bytes;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading logo info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    setState(() => _isLoading = true);

    try {
      final logoPath = await LogoService.pickLogoFile();

      if (logoPath != null) {
        // Enable logo by default when new logo is selected
        await LogoService.setLogoEnabled(true);
        await _loadLogoInfo();
        _showSuccessSnackBar('Logo berhasil dipilih dan disimpan');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking logo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLogo(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      await LogoService.setLogoEnabled(enabled);
      await _loadLogoInfo();

      _showSuccessSnackBar(enabled
          ? 'Logo diaktifkan pada struk'
          : 'Logo dinonaktifkan pada struk');
    } catch (e) {
      _showErrorSnackBar('Error toggling logo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeLogo() async {
    final confirmed = await _showConfirmDialog(
      'Hapus Logo',
      'Apakah Anda yakin ingin menghapus logo? Logo akan dihapus dari struk dan tidak dapat dipulihkan.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final success = await LogoService.removeLogo();
      if (success) {
        await _loadLogoInfo();
        _showSuccessSnackBar('Logo berhasil dihapus');
      } else {
        _showErrorSnackBar('Gagal menghapus logo');
      }
    } catch (e) {
      _showErrorSnackBar('Error removing logo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Logo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppTheme.spaceSM),
                              Text(
                                'Tentang Logo Struk',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Text(
                            'Logo akan ditampilkan di bagian atas struk, sebelum informasi toko. '
                            'Gunakan logo dengan ukuran maksimal 2MB dalam format PNG, JPEG, atau BMP.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceLG),

                  // Current logo section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.image,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppTheme.spaceSM),
                              Text(
                                'Logo Saat Ini',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceLG),
                          if (_logoInfo['hasLogo'] == true) ...[
                            // Logo preview
                            Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: _logoBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSM),
                                        child: Image.memory(
                                          _logoBytes!,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : const Padding(
                                        padding:
                                            EdgeInsets.all(AppTheme.spaceLG),
                                        child: Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.spaceMD),

                            // Logo info
                            if (_logoInfo['sizeFormatted'] != null)
                              Text(
                                'Ukuran: ${_logoInfo['sizeFormatted']}',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),

                            const SizedBox(height: AppTheme.spaceLG),

                            // Enable/disable toggle
                            SwitchListTile(
                              title: const Text('Tampilkan logo pada struk'),
                              subtitle: const Text(
                                  'Logo akan muncul di bagian atas struk'),
                              value: _logoInfo['enabled'] ?? false,
                              onChanged: _toggleLogo,
                              activeColor: AppColors.primary,
                            ),

                            const SizedBox(height: AppTheme.spaceMD),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickLogo,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Ganti Logo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMD),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _removeLogo,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Hapus Logo'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // No logo state
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(AppTheme.spaceLG),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMD),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceMD),
                                  Text(
                                    'Belum ada logo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceSM),
                                  Text(
                                    'Pilih logo untuk ditampilkan pada struk',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[500],
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.spaceLG),
                                  ElevatedButton.icon(
                                    onPressed: _pickLogo,
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Pilih Logo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceLG,
                                        vertical: AppTheme.spaceMD,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceLG),

                  // Tips section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: AppTheme.spaceSM),
                              Text(
                                'Tips Logo yang Baik',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          _buildTip(
                              'Gunakan logo dengan rasio 1:1 (persegi) atau 16:9 (landscape)'),
                          _buildTip(
                              'Pastikan logo memiliki kontras yang jelas (hitam-putih lebih baik)'),
                          _buildTip(
                              'Hindari detail yang terlalu kecil karena printer thermal memiliki resolusi terbatas'),
                          _buildTip(
                              'Ukuran file maksimal 2MB untuk performa optimal'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
