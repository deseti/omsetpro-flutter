# Perubahan Sistem Pembayaran - Nonaktifkan Midtrans Digital

## Ringkasan Perubahan

Sistem pembayaran telah dimodifikasi untuk menonaktifkan pembayaran digital Midtrans dan mengganti dengan sistem pembayaran manual yang mendukung pembayaran langsung dan pembayaran tempo/hutang.

## Perubahan File

### 1. Frontend - Service Layer

#### `frontend/lib/services/payment_service_interface.dart`
- **Perubahan**: Menghapus `PaymentMethod.digital` dari enum
- **Status**: Hanya tersisa `cash` dan `manual`

#### `frontend/lib/services/payment_service_factory.dart`  
- **Perubahan**: 
  - Menonaktifkan pembayaran digital untuk semua platform
  - Mengaktifkan manual entry untuk tempo/hutang
  - Provider hanya mengembalikan `PaymentMethod.cash` dan `PaymentMethod.manual`

### 2. Frontend - UI Components

#### `frontend/lib/features/kasir/widgets/payment_buttons_widget.dart`
- **Perubahan**:
  - Menghapus tombol "Bayar Digital (QRIS, dll)"
  - Mengubah label tombol menjadi "Pembayaran Manual" dan "Pembayaran Tunai"
  - Membersihkan switch case untuk menghapus referensi ke digital payment

#### `frontend/lib/features/kasir/widgets/manual_payment_dialog.dart`
- **Perubahan**:
  - Mengganti opsi pembayaran dengan:
    - **Pembayaran Langsung**: Untuk transaksi yang dibayar saat itu juga
    - **Pembayaran Tempo/Hutang**: Untuk transaksi yang akan dibayar kemudian
  - Menambahkan visual indicator (warna) untuk membedakan jenis pembayaran

#### `frontend/lib/features/kasir/kasir_page.dart`
- **Perubahan**:
  - Menghapus fungsi `_processDigitalTransaction`
  - Menambahkan fungsi `_processManualPayment` untuk menangani pembayaran manual
  - Membersihkan import yang tidak diperlukan

## Fitur Baru

### Pembayaran Manual
1. **Pembayaran Langsung**
   - Untuk transaksi yang dibayar tunai, kartu debit, atau e-wallet langsung oleh pelanggan
   - Status: Lunas
   - Metode: "Langsung"

2. **Pembayaran Tempo/Hutang**
   - Untuk transaksi yang akan dibayar kemudian
   - Status: Belum lunas (perlu sistem follow-up terpisah)
   - Metode: "Tempo/Hutang"

### Flow Pembayaran Baru
1. Kasir memilih produk dan menambahkan ke keranjang
2. Pilih metode pembayaran:
   - **Pembayaran Tunai**: Langsung catat sebagai lunas
   - **Pembayaran Manual**: Munculkan dialog pilihan (Langsung/Tempo)
3. Transaksi tercatat dengan metode pembayaran yang sesuai
4. Struk dicetak dengan informasi metode pembayaran

## Backend - Tidak Ada Perubahan

Backend Midtrans tetap tersedia namun tidak digunakan oleh frontend. File berikut masih ada tapi tidak aktif:
- `backend/src/midtrans/midtrans.service.ts`
- `backend/src/midtrans/midtrans.controller.ts` 
- `backend/src/midtrans/midtrans.module.ts`

## Testing yang Diperlukan

1. **Test pembayaran tunai** - memastikan berfungsi normal
2. **Test pembayaran langsung** - memastikan tercatat sebagai "Langsung"
3. **Test pembayaran tempo** - memastikan tercatat sebagai "Tempo/Hutang"
4. **Test struk** - memastikan metode pembayaran tercetak dengan benar
5. **Test offline mode** - memastikan semua pembayaran tetap berfungsi offline

## Rekomendasi Selanjutnya

1. **Sistem Manajemen Hutang**: Buat fitur untuk tracking dan follow-up pembayaran tempo
2. **Laporan Pembayaran**: Tambahkan filter berdasarkan metode pembayaran di laporan
3. **Notifikasi Jatuh Tempo**: Sistem reminder untuk pembayaran tempo yang mendekati/melewati jatuh tempo
4. **Pembayaran Parsial**: Opsi untuk pembayaran tempo yang dibayar secara bertahap

## Rollback Plan

Jika perlu mengembalikan pembayaran digital:
1. Kembalikan enum `PaymentMethod` untuk menyertakan `digital`
2. Kembalikan provider untuk mengaktifkan digital payment berdasarkan platform
3. Kembalikan tombol digital payment di payment_buttons_widget
4. Kembalikan fungsi digital payment di kasir_page
