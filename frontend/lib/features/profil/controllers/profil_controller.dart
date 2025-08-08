import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/profil_data_model.dart';
import '../providers/profil_data_provider.dart';
import '../../../providers/providers.dart';

class ProfilController {
  final WidgetRef ref;
  final GlobalKey<FormState> formKey;
  final TextEditingController namaController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  ProfilController({
    required this.ref,
    required this.formKey,
    required this.namaController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
  });

  void loadData(ProfilData data) {
    namaController.text = data.namaLengkap;
  }

  Future<void> updateNama({
    required VoidCallback onSuccess,
    required Function(String) onError,
    required VoidCallback onStartLoading,
    required VoidCallback onStopLoading,
  }) async {
    if (!formKey.currentState!.validate()) return;

    onStartLoading();

    try {
      final dio = ref.read(dioProvider);

      await dio.patch('/auth/update-profile', data: {
        'namaLengkap': namaController.text.trim(),
      });

      // Update state di provider
      final currentProfile = ref.read(userProfileProvider);
      if (currentProfile != null) {
        ref.read(userProfileProvider.notifier).state = {
          ...currentProfile,
          'namaLengkap': namaController.text.trim(),
        };
      }

      // Refresh data profil
      ref.invalidate(profilDataProvider);

      onSuccess();
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Gagal memperbarui nama';
      onError(message);
    } catch (e) {
      onError('Terjadi kesalahan: $e');
    } finally {
      onStopLoading();
    }
  }

  Future<void> changePassword({
    required VoidCallback onSuccess,
    required Function(String) onError,
    required VoidCallback onStartLoading,
    required VoidCallback onStopLoading,
    required VoidCallback onClearFields,
  }) async {
    if (!formKey.currentState!.validate()) return;

    onStartLoading();

    try {
      final dio = ref.read(dioProvider);

      await dio.patch('/auth/change-password', data: {
        'currentPassword': currentPasswordController.text,
        'newPassword': newPasswordController.text,
      });

      onClearFields();
      onSuccess();
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Gagal mengubah password';
      onError(message);
    } catch (e) {
      onError('Terjadi kesalahan: $e');
    } finally {
      onStopLoading();
    }
  }
}
