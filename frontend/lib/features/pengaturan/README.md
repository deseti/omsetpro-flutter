# Pengaturan Akun - Modular Structure

File `pengaturan_akun_page.dart` telah direfactor dari 1274 baris menjadi struktur modular yang lebih maintainable.

## Struktur Modular

### 1. Models (`models/`)
- **`data_toko_model.dart`** - Model dan konstanta untuk data toko
  - Class `DataToko` dengan fromJson/toJson methods  
  - Konstanta `kategoriBisnisList`

### 2. Providers (`providers/`)
- **`data_toko_provider.dart`** - Provider untuk data toko
  - `dataTokoProvider` - FutureProvider untuk fetch data toko dari API

### 3. Controllers (`controllers/`)
- **`pengaturan_akun_controller.dart`** - Business logic controller
  - `pickImage()` - Handle image picking untuk logo
  - `simpanData()` - Save data toko ke server
  - `saveTokoOnlineSettings()` - Save pengaturan toko online

### 4. Components (`components/`)
- **`logo_section.dart`** - Widget untuk logo upload section
  - Handle display logo dari network, file, atau placeholder
  - Cross-platform (Web menggunakan bytes, Mobile menggunakan file)

- **`store_info_form.dart`** - Widget form informasi toko
  - Input fields untuk nama, alamat, telepon, email, kategori bisnis
  - Form validation

- **`toko_online_section.dart`** - Widget lengkap untuk toko online features
  - Activation toggle
  - Slug settings dengan validation
  - Delivery options (pickup/delivery)
  - QR Code generator
  - Bank accounts management
  - Shipping tracking

### 5. Main Page (`pengaturan_akun_page.dart`)
- **Berkurang dari 1274 baris menjadi ~460 baris**
- Fokus pada orchestration dan state management
- Responsive layouts (mobile/tablet/desktop)
- Integration dengan semua modular components

## Benefits

1. **Maintainability** - Setiap komponen memiliki tanggung jawab yang jelas
2. **Reusability** - Components dapat digunakan ulang di page lain
3. **Testability** - Setiap komponen dapat di-test secara terpisah
4. **Readability** - Code lebih mudah dibaca dan dipahami
5. **Scalability** - Mudah menambah fitur baru tanpa mengganggu yang existing

## Usage

```dart
// Import modular components
import 'components/logo_section.dart';
import 'components/store_info_form.dart';
import 'components/toko_online_section.dart';
import 'controllers/pengaturan_akun_controller.dart';

// Use in build method
LogoSection(
  currentLogoUrl: _currentLogoUrl,
  selectedImage: _selectedImage,
  selectedImageBytes: _selectedImageBytes,
  onPickImage: _pickImage,
)
```

## File Size Reduction

- **Before**: `pengaturan_akun_page.dart` = 1274 lines
- **After**: 
  - Main page: ~460 lines (64% reduction)
  - Total modular files: ~900 lines
  - Better organized and maintainable structure
