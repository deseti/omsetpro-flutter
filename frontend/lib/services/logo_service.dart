// lib/services/logo_service.dart
// Service untuk mengelola logo usaha pada struk

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class LogoService {
  static const String _logoPathKey = 'business_logo_path';
  static const String _logoEnabledKey = 'logo_enabled';

  /// Get current logo path
  static Future<String?> getLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_logoPathKey);
  }

  /// Check if logo is enabled
  static Future<bool> isLogoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_logoEnabledKey) ?? false;
  }

  /// Set logo enabled/disabled
  static Future<void> setLogoEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_logoEnabledKey, enabled);
  }

  /// Pick logo file from device
  static Future<String?> pickLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Copy file to app directory for persistent storage
        final savedPath = await _saveLogoToAppDirectory(filePath);

        if (savedPath != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_logoPathKey, savedPath);
          return savedPath;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error picking logo file: $e');
      return null;
    }
  }

  /// Save logo to app directory
  static Future<String?> _saveLogoToAppDirectory(String originalPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logoDir = Directory('${appDir.path}/logos');

      if (!await logoDir.exists()) {
        await logoDir.create(recursive: true);
      }

      final originalFile = File(originalPath);
      final fileName = 'business_logo.${originalPath.split('.').last}';
      final newPath = '${logoDir.path}/$fileName';

      await originalFile.copy(newPath);
      return newPath;
    } catch (e) {
      print('❌ Error saving logo: $e');
      return null;
    }
  }

  /// Remove current logo
  static Future<bool> removeLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logoPath = prefs.getString(_logoPathKey);

      if (logoPath != null) {
        final file = File(logoPath);
        if (await file.exists()) {
          await file.delete();
        }
        await prefs.remove(_logoPathKey);
        await prefs.setBool(_logoEnabledKey, false);
      }
      return true;
    } catch (e) {
      print('❌ Error removing logo: $e');
      return false;
    }
  }

  /// Validate logo file
  static Future<bool> validateLogoFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      // Check file size (max 2MB)
      final fileSize = await file.length();
      if (fileSize > 2 * 1024 * 1024) return false;

      // Check if it's a valid image
      final bytes = await file.readAsBytes();
      // Basic validation - check for common image headers
      if (bytes.length < 10) return false;

      // PNG: 89 50 4E 47
      // JPEG: FF D8 FF
      // BMP: 42 4D
      final header = bytes.take(4).toList();

      // PNG
      if (header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47) {
        return true;
      }

      // JPEG
      if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
        return true;
      }

      // BMP
      if (header[0] == 0x42 && header[1] == 0x4D) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error validating logo: $e');
      return false;
    }
  }

  /// Get logo as bytes for display
  static Future<Uint8List?> getLogoBytes() async {
    try {
      final logoPath = await getLogoPath();
      if (logoPath == null) return null;

      final file = File(logoPath);
      if (!await file.exists()) return null;

      return await file.readAsBytes();
    } catch (e) {
      print('❌ Error getting logo bytes: $e');
      return null;
    }
  }

  /// Get logo info
  static Future<Map<String, dynamic>> getLogoInfo() async {
    final logoPath = await getLogoPath();
    final isEnabled = await isLogoEnabled();

    if (logoPath == null) {
      return {
        'hasLogo': false,
        'enabled': false,
        'path': null,
        'size': null,
      };
    }

    try {
      final file = File(logoPath);
      final exists = await file.exists();
      final size = exists ? await file.length() : null;

      return {
        'hasLogo': exists,
        'enabled': isEnabled,
        'path': logoPath,
        'size': size,
        'sizeFormatted': size != null ? _formatFileSize(size) : null,
      };
    } catch (e) {
      return {
        'hasLogo': false,
        'enabled': false,
        'path': logoPath,
        'size': null,
      };
    }
  }

  /// Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
