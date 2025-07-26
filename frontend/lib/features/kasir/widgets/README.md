# Cart Section Widget - Modular Structure

File ini telah direfactor untuk menjadi lebih modular dan mudah dikelola. Berikut adalah struktur file baru:

## File Structure

### 1. `cart_section_widget.dart` (Main Widget)
- Widget utama yang menentukan layout berdasarkan platform (mobile/desktop)
- Mengatur state management dan callback functions
- Berukuran lebih kecil dan fokus pada logic utama

### 2. `mobile_cart_widget.dart` (Mobile Layout)
- Layout khusus untuk mobile dengan floating action buttons
- Menggunakan Stack layout dengan cart items di tengah
- FAB untuk akses cepat ke customer, promo, dan total

### 3. `desktop_cart_widget.dart` (Desktop Layout)
- Layout tradisional untuk desktop/tablet
- Menggunakan column layout dengan semua section visible
- Interface yang lebih luas untuk layar besar

### 4. `cart_floating_buttons.dart` (Mobile FABs)
- Floating action buttons untuk mobile interface
- Tiga button: Customer, Promo, Total
- Positioning yang tetap di kiri layar

### 5. `cart_bottom_sheets.dart` (Modal Sheets)
- Bottom sheet/modal untuk setiap section di mobile
- Customer selection modal
- Promo selection modal  
- Total breakdown modal
- Reusable dan konsisten design

### 6. `cart_widgets.dart` (Export File)
- Central export file untuk semua cart widgets
- Memudahkan import di file lain
- Includes existing widgets (cart_item, payment_buttons, etc.)

## Benefits

### 1. **Modularity**
- Setiap file memiliki responsibility yang jelas
- Mudah untuk maintenance dan debugging
- Code reusability yang lebih baik

### 2. **Separation of Concerns**
- Mobile dan desktop logic terpisah
- Bottom sheets terpisah dari layout logic
- Floating buttons sebagai component independen

### 3. **Scalability**
- Mudah menambah fitur baru
- Dapat ditest secara independent
- Easier code review process

### 4. **Performance**
- Lazy loading untuk modal yang tidak digunakan
- Conditional rendering berdasarkan platform
- Reduced bundle size per component

## Usage

```dart
// Import dengan mudah melalui export file
import '../widgets/cart_widgets.dart';

// Atau import specific widget
import '../widgets/cart_section_widget.dart';

// Penggunaan tetap sama seperti sebelumnya
CartSectionWidget(
  onCashPayment: () {},
  onDigitalPayment: () {},
  onManualPayment: (type) {},
)
```

## Migration Guide

### Before (Monolithic)
- 1 file besar dengan 800+ lines
- Semua logic dalam satu class
- Sulit untuk maintain dan test

### After (Modular)
- 6 files dengan responsibility yang jelas
- Setiap file <200 lines
- Easy to understand dan maintain

## Mobile UX Improvements

### Popup/Modal Approach
- Mengatasi masalah overlap dengan keranjang
- User experience yang lebih clean
- Accessibility yang lebih baik untuk mobile

### Floating Action Buttons
- Quick access ke fungsi penting
- Visual yang tidak mengganggu
- Consistent positioning

### Bottom Sheets
- Native mobile interaction pattern
- Full screen space utilization
- Easy to dismiss dan navigate
