import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/data_toko_model.dart';
import '../providers/data_toko_provider.dart';
import '../../../providers/providers.dart';
import '../../../models/toko_online_model.dart';
import '../../../providers/toko_online_provider.dart';

class PengaturanAkunController {
  final WidgetRef ref;

  PengaturanAkunController(this.ref);

  Future<void> pickImage({
    required Function(File?) onImageSelected,
    required Function(Uint8List?, String?) onImageBytesSelected,
    required Function(String, {bool isError}) showSnackBar,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Untuk web, baca sebagai bytes
          final bytes = await pickedFile.readAsBytes();
          onImageBytesSelected(bytes, pickedFile.name);
        } else {
          // Untuk mobile/desktop
          onImageSelected(File(pickedFile.path));
        }
      }
    } catch (e) {
      showSnackBar('Gagal memilih gambar: $e', isError: true);
    }
  }

  Future<void> simpanData({
    required String nama,
    required String alamat,
    required String telepon,
    required String email,
    required String kategoriBisnis,
    File? selectedImage,
    Uint8List? selectedImageBytes,
    String? selectedImageName,
    required Function() onLoadingStart,
    required Function() onLoadingEnd,
    required Function(String, {bool isError}) showSnackBar,
    required Function(String?) updateCurrentLogoUrl,
    required Function() clearSelectedImages,
  }) async {
    onLoadingStart();

    try {
      final dio = ref.read(dioProvider);

      print('💾 Preparing to save akun toko...');

      // Siapkan data form
      final formData = FormData.fromMap({
        'nama': nama.trim(),
        'alamat': alamat.trim(),
        'telepon': telepon.trim(),
        'email': email.trim(),
        'kategoriBisnis': kategoriBisnis,
      });

      print('📝 Form data prepared: ${formData.fields}');

      // Upload logo jika ada gambar baru
      if (selectedImage != null || selectedImageBytes != null) {
        print('🖼️ Logo file detected, adding to form...');
        if (kIsWeb && selectedImageBytes != null) {
          // Untuk web, gunakan bytes
          print(
              '🌐 Web platform - using bytes (${selectedImageBytes.length} bytes)');
          formData.files.add(
            MapEntry(
              'logo',
              MultipartFile.fromBytes(
                selectedImageBytes,
                filename: selectedImageName ?? 'logo_toko.jpg',
              ),
            ),
          );
        } else if (!kIsWeb && selectedImage != null) {
          // Untuk mobile/desktop, gunakan file
          print('📱 Mobile platform - using file: ${selectedImage.path}');
          formData.files.add(
            MapEntry(
              'logo',
              await MultipartFile.fromFile(
                selectedImage.path,
                filename: 'logo_toko.jpg',
              ),
            ),
          );
        }
      } else {
        print('🚫 No logo file to upload');
      }

      print('📤 Sending POST request to /pengaturan/akun-toko...');
      final response = await dio.post('/pengaturan/akun-toko', data: formData);
      print('✅ Response received: ${response.data}');

      // Update currentLogoUrl jika ada logoUrl di response
      if (response.data != null && response.data['logoUrl'] != null) {
        updateCurrentLogoUrl(response.data['logoUrl']);
        print('🔄 Updated _currentLogoUrl to: ${response.data['logoUrl']}');
      }

      // Clear selected images setelah upload berhasil
      clearSelectedImages();

      // Refresh data
      print('🔄 Refreshing data provider...');
      ref.invalidate(dataTokoProvider);

      showSnackBar('Data toko berhasil disimpan!');
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal menyimpan data toko';
      showSnackBar(message, isError: true);
    } catch (e) {
      showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> saveTokoOnlineSettings({
    required String slug,
    required bool isActive,
    required bool allowPickup,
    required bool allowDelivery,
  }) async {
    final settings = TokoOnlineSettings(
      tokoOnlineSlug: slug.trim(),
      isTokoOnlineActive: isActive,
      allowPickup: allowPickup,
      allowDelivery: allowDelivery,
    );

    await ref
        .read(tokoOnlineSettingsProvider.notifier)
        .updateSettings(settings);
  }
}
