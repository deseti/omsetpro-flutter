import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class LogoSection extends StatefulWidget {
  final String? currentLogoUrl;
  final File? selectedImage;
  final Uint8List? selectedImageBytes;
  final VoidCallback onPickImage;

  const LogoSection({
    super.key,
    this.currentLogoUrl,
    this.selectedImage,
    this.selectedImageBytes,
    required this.onPickImage,
  });

  @override
  State<LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends State<LogoSection> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Logo Toko',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.onPickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _buildLogoContent(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onPickImage,
              icon: const Icon(Icons.upload),
              label: const Text('Pilih Logo'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: JPG, PNG (maks. 2MB)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoContent() {
    print('🖼️ Building logo content...');
    print('- selectedImageBytes != null: ${widget.selectedImageBytes != null}');
    print('- selectedImage != null: ${widget.selectedImage != null}');
    print('- currentLogoUrl: ${widget.currentLogoUrl}');
    print('- kIsWeb: $kIsWeb');

    // Prioritas: bytes (web) > file (mobile) > network image > placeholder
    if (kIsWeb && widget.selectedImageBytes != null) {
      print('✅ Using selected image bytes (web)');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          widget.selectedImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (!kIsWeb && widget.selectedImage != null) {
      print('✅ Using selected image file (mobile)');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          widget.selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (widget.currentLogoUrl != null &&
        widget.currentLogoUrl!.isNotEmpty) {
      print('✅ Using network image from URL: ${widget.currentLogoUrl}');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.currentLogoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('✅ Network image loaded successfully');
              return child;
            }
            print(
                '⏳ Loading network image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading network image: $error');
            return _buildLogoPlaceholder();
          },
        ),
      );
    } else {
      print('📋 Using placeholder (no image available)');
      return _buildLogoPlaceholder();
    }
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.store,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Logo Toko',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
