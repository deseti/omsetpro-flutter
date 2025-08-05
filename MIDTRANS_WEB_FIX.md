# Perbaikan Integrasi Midtrans untuk Web

## Masalah yang Diperbaiki

1. **Transaksi web tidak muncul di dashboard sandbox Midtrans**
2. **Status pembayaran web tidak ter-update di aplikasi**
3. **Snap.js tidak ter-load dengan benar** - Error: `'window.snap.pay'` tidak ditemukan
4. **Double request dari frontend** - Frontend melakukan 2 request berbeda

## Perbaikan yang Dilakukan

### 1. Frontend Web (`payment_service_web.dart`)
- ✅ Menggunakan `snapPay()` function yang lebih robust
- ✅ Error handling yang lebih baik dengan fallback yang terkontrol
- ✅ Mencegah double request dengan proper exception handling
- ✅ Timeout handling untuk pembayaran

### 2. Web HTML (`index.html`)
- ✅ Script Snap.js dengan loading detection
- ✅ Fungsi `snapPay()` yang lebih reliable
- ✅ Error handling dan logging yang lebih detailed
- ✅ Window load event listener untuk memastikan Snap.js ter-load

### 3. Backend (`midtrans.service.ts`)
- ✅ Endpoint `/midtrans/create-snap-url` mengembalikan `snap_token` dan `snap_url`
- ✅ Webhook handler yang lebih lengkap dengan validasi signature
- ✅ Update status transaksi berdasarkan notifikasi Midtrans

### 4. Webhook Testing Setup
- ✅ Script `setup-webhook.bat` untuk Windows
- ✅ Script `setup-webhook.sh` untuk Linux/Mac
- ✅ Panduan konfigurasi webhook di dashboard Midtrans

## Cara Testing - LANGKAH PENTING

### 1. Setup Webhook untuk Testing (WAJIB!)

**Opsi A: Menggunakan ngrok (Direkomendasikan)**
```bash
# Install ngrok dari https://ngrok.com/download
# Lalu jalankan:
cd backend
./setup-webhook.bat  # Windows
# atau
./setup-webhook.sh   # Linux/Mac
```

**Opsi B: Manual ngrok**
```bash
# Terminal 1: Jalankan backend
cd backend
npm run start

# Terminal 2: Jalankan ngrok
ngrok http 3000
# Copy URL yang diberikan (contoh: https://abc123.ngrok.io)
```

### 2. Konfigurasi Dashboard Midtrans
1. Buka https://dashboard.sandbox.midtrans.com/
2. Login dengan akun Midtrans Anda
3. Masuk ke **Settings** > **Configuration**
4. Set **Payment Notification URL** ke: `https://YOUR_NGROK_URL/midtrans/webhook`
   - Contoh: `https://abc123.ngrok.io/midtrans/webhook`
5. **Save** konfigurasi

### 3. Testing Pembayaran Web
1. Refresh browser dan buka aplikasi web
2. Masuk ke halaman kasir
3. Tambahkan produk ke keranjang
4. Klik "Bayar Digital (QRIS, dll)"
5. **Pop-up Snap pembayaran harus muncul** (bukan redirect ke tab baru)
6. Pilih metode pembayaran (QRIS, Virtual Account, dll)

### 4. Simulasi Pembayaran di Dashboard

**PENTING**: Di sandbox Midtrans, Anda **TIDAK perlu scan QR atau bayar dengan uang sungguhan**.

**Cara Simulasi Pembayaran:**
1. Setelah step 3, transaksi harus muncul di dashboard sandbox
2. Buka dashboard: https://dashboard.sandbox.midtrans.com/
3. Masuk ke menu **Transactions**
4. Cari transaksi yang baru dibuat (cek order ID, contoh: `OMSETPRO-1754409450504-182`)
5. Klik transaksi tersebut
6. **Klik tombol "Simulate Payment"** atau **"Action" > "Set to Settlement"**
7. Status transaksi akan berubah dari `pending` menjadi `settlement`
8. **Webhook akan otomatis dikirim ke backend Anda**

**❌ JANGAN scan QR code di sandbox** - itu hanya untuk testing visual
**✅ GUNAKAN tombol "Simulate Payment"** - ini cara yang benar untuk testing sandbox

### 5. Verifikasi Status Pembayaran
1. Setelah simulate payment, refresh halaman Snap (jika masih terbuka)
2. Atau klik tombol **"Check Status"** di halaman pembayaran
3. Status akan berubah menjadi "SUCCESS" dan halaman akan redirect kembali ke aplikasi

### 6. Update Terbaru (05/08/2025) - Masalah Race Condition

**Masalah yang ditemukan:**
- Pop-up Snap.js berhasil muncul ✅
- Backend menerima webhook dengan benar ✅  
- Tapi frontend mengalami race condition dalam deteksi Snap.js ❌

**Solusi sementara:**
- Menggunakan redirect method yang lebih stabil
- Halaman pembayaran terbuka langsung di window yang sama
- Status transaksi akan ter-update otomatis via webhook

### 7. Verifikasi di Backend
Monitor log backend, Anda harus melihat:
```
📨 Webhook diterima dari Midtrans: { order_id: '...', transaction_status: 'settlement', ... }
🔍 Processing webhook for order ... with status settlement
✅ Transaction settled
✅ Transaction ... status updated to paid
```

### 6. Verifikasi di Frontend
- Refresh halaman aplikasi
- Transaksi harus muncul di riwayat transaksi
- Status harus "paid" atau "lunas"

## Troubleshooting

### Error: "window.snap.pay is not a function"
- **Solusi**: Refresh browser dan tunggu beberapa detik sebelum melakukan pembayaran
- **Penyebab**: Snap.js belum ter-load sempurna

### Transaksi tidak muncul di dashboard Midtrans
- **Solusi**: Cek log backend, pastikan tidak ada error saat request ke Midtrans
- **Penyebab**: Network error atau client key salah

### Webhook tidak diterima backend
- **Solusi**: 
  1. Pastikan ngrok masih running
  2. Cek webhook URL di dashboard Midtrans
  3. Pastikan backend dapat diakses dari internet

### Status transaksi tidak update
- **Solusi**: 
  1. Cek log backend untuk webhook
  2. Pastikan webhook signature validation benar
  3. Manual simulate payment di dashboard

## Status Testing

✅ **Snap.js Loading**: Diperbaiki dengan detection dan logging  
✅ **Payment Redirect**: Menggunakan redirect yang stabil (Updated 05/08)  
✅ **Webhook Setup**: Script otomatis untuk ngrok  
✅ **Backend Logging**: Detailed logging untuk debugging  
✅ **Error Handling**: Fallback yang terkontrol  
✅ **Result Parsing**: Perbaikan parsing callback dari Snap.js ✅ (Updated 05/08/2025)  
✅ **Sandbox Testing**: Dokumentasi simulasi pembayaran yang benar ✅ (Updated 05/08/2025)  

### Update Terbaru (05/08/2025)
**Masalah yang diperbaiki:**
- ❌ Frontend menampilkan "Pembayaran gagal" padahal Snap.js berhasil
- ❌ Callback dari Snap.js tidak ter-parse dengan benar (`[object Object]`)
- ❌ Race condition dalam deteksi Snap.js ready state

**Solusi yang diterapkan:**
- ✅ Perbaikan parsing result callback di `payment_service_web.dart`
- ✅ Callback yang lebih robust di `index.html` 
- ✅ Logging yang lebih detail untuk debugging
- ✅ **Fallback ke redirect method yang lebih stabil**
- ✅ Dokumentasi testing sandbox yang lebih jelas

**Flow yang sekarang bekerja:**
1. User klik "Bayar Digital" 
2. Frontend redirect ke halaman Snap Midtrans
3. User pilih metode pembayaran (QRIS/VA/dll)
4. **Status: PENDING** (normal untuk QRIS/VA)
5. **Admin simulate payment** di dashboard sandbox
6. **Webhook diterima** backend dengan status settlement
7. **Status transaksi ter-update** di aplikasi

## File yang Diubah

1. `frontend/web/index.html` - Perbaikan Snap.js loading dan callback function ✅ (Updated 05/08)
2. `frontend/lib/services/payment_service_web.dart` - Error handling dan result parsing ✅ (Updated 05/08)
3. `backend/src/midtrans/midtrans.service.ts` - Webhook handler dan logging
4. `backend/setup-webhook.bat` - Script Windows untuk webhook setup
5. `backend/setup-webhook.sh` - Script Linux/Mac untuk webhook setup

## Next Steps

1. ✅ Test dengan script webhook setup
2. ✅ Verifikasi pop-up Snap.js muncul di web
3. ✅ Test simulasi pembayaran di dashboard
4. ✅ Verifikasi webhook diterima backend
5. 🔄 Test berbagai metode pembayaran (QRIS, VA, dll)
6. 🔄 Untuk production: ganti ke production keys dan URLs
