# Izin Cuti Module - Refactored Structure

## Overview
File `izin_cuti_tab.dart` yang sebelumnya memiliki 841 baris telah dipecah menjadi struktur modular untuk meningkatkan maintainability dan readability.

## New Structure

```
izin_cuti/
├── models/
│   └── izin_models.dart          # Enums dan utilities untuk izin
├── providers/
│   └── izin_providers.dart       # Riverpod providers untuk data management
├── services/
│   └── izin_service.dart         # Business logic dan helper functions
├── widgets/
│   ├── daftar_izin_tab.dart      # Widget untuk tab daftar izin
│   ├── statistik_tab.dart        # Widget untuk tab statistik
│   ├── pengajuan_izin_dialog.dart # Dialog untuk pengajuan izin baru
│   └── approval_dialog.dart      # Dialog untuk approval izin
└── izin_cuti.dart               # Barrel file untuk exports
```

## File Details

### 1. `models/izin_models.dart` (~30 lines)
- Enum `JenisIzin` (IZIN, SAKIT, CUTI)
- Enum `StatusIzin` (PENDING, APPROVED, REJECTED)
- Class `IzinUtils` dengan helper methods:
  - `getJenisIzinText()` - Format text untuk jenis izin
  - `formatDate()` - Format tanggal Indonesia

### 2. `providers/izin_providers.dart` (~17 lines)
- `izinTimListProvider` - Provider untuk list semua izin tim
- `izinTimByUserProvider` - Provider untuk izin berdasarkan user ID

### 3. `services/izin_service.dart` (~70 lines)
- `getStatusColor()` - Warna berdasarkan status izin
- `getJenisIzinIcon()` - Icon berdasarkan jenis izin
- `filterIzin()` - Filter izin berdasarkan status
- `calculateStatistics()` - Kalkulasi statistik izin

### 4. `widgets/daftar_izin_tab.dart` (~200+ lines)
- Widget utama untuk menampilkan daftar izin
- Filter chips untuk status
- List view dengan expansion tiles
- Floating action button untuk tambah izin
- Integration dengan dialog components

### 5. `widgets/statistik_tab.dart` (~100+ lines)
- Widget untuk menampilkan statistik izin
- Summary cards
- Statistik per jenis izin
- Statistik per anggota tim

### 6. `widgets/pengajuan_izin_dialog.dart` (~130+ lines)
- Dialog untuk membuat pengajuan izin baru
- Form dengan dropdown dan date picker
- Validasi input
- API integration untuk submit

### 7. `widgets/approval_dialog.dart` (~120+ lines)
- Dialog untuk approve/reject izin
- Radio button untuk pilihan approval
- Text field untuk catatan
- API integration untuk update status

### 8. `izin_cuti_tab.dart` (Main file, now ~40 lines)
- Container utama dengan TabController
- Import dan gunakan widget components
- Clean dan focused code

## Benefits of Refactoring

1. **Maintainability**: Setiap file memiliki tanggung jawab yang jelas
2. **Reusability**: Components dapat digunakan kembali
3. **Testability**: Lebih mudah untuk unit testing individual components
4. **Readability**: Code lebih mudah dibaca dan dipahami
5. **Scalability**: Mudah untuk menambah fitur baru
6. **Team Collaboration**: Developer bisa bekerja pada file yang berbeda tanpa conflict

## Usage
Import barrel file untuk menggunakan semua components:
```dart
import 'izin_cuti/izin_cuti.dart';
```

Atau import individual components sesuai kebutuhan:
```dart
import 'izin_cuti/widgets/daftar_izin_tab.dart';
import 'izin_cuti/models/izin_models.dart';
```
