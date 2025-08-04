# OmsetPro - SuperApp UMKM Indonesia

OmsetPro adalah platform digital yang dirancang untuk membantu pelaku UMKM di Indonesia dalam mengelola bisnis mereka secara efisien dan modern. Proyek ini terdiri dari dua bagian utama:

- **Backend**: API berbasis NestJS dengan Prisma ORM, mendukung fitur multi-tenancy, manajemen user, cabang, produk, transaksi, laporan, pelanggan, dan integrasi eksternal.
- **Frontend**: Aplikasi Flutter multi-platform (Android, iOS, Web, Desktop) yang menyediakan antarmuka kasir, manajemen produk, pelanggan, laporan, dan fitur-fitur bisnis lainnya.

## Fitur Utama yang Sudah Diimplementasikan

1. **Auth & User Management**: Sistem registrasi, login, dan manajemen user yang aman.
2. **Manajemen Cabang & Produk**: Owner dapat mengelola cabang usaha dan produk secara terpusat.
3. **Transaksi & Mode Offline**: Kasir tetap dapat beroperasi walau tanpa koneksi internet.
4. **Dasbor Smart AI**: Insight bisnis otomatis berbasis AI untuk membantu pengambilan keputusan.
5. **Fondasi CRM**: Sistem pencatatan dan pengelolaan data pelanggan.

## Arsitektur Singkat

- **Backend**: Dibangun dengan NestJS, menggunakan Prisma untuk ORM, mendukung multi-tenancy, role management, dan integrasi eksternal (akan datang).
- **Frontend**: Flutter, mendukung berbagai platform, terintegrasi dengan backend melalui REST API.
- **Database**: SQLite (dev), siap untuk migrasi ke PostgreSQL/Cloud.
- **Fitur Keamanan**: JWT Auth, role-based access, validasi input, dan pengelolaan secrets.


## Roadmap Pengembangan OmsetPro (2025+)
Roadmap ini disusun untuk membawa OmsetPro menjadi platform kasir dan bisnis UMKM paling lengkap dan modern di Indonesia, setara bahkan melampaui fitur Moka POS.

### Fase 1: Fondasi & Fitur Dasar (Selesai)
- Auth & User Management
- Manajemen Cabang & Produk
- Transaksi & Mode Offline
- Dasbor Smart AI
- CRM, Loyalitas, Promo & Diskon

### Fase 2: Integrasi Eksternal & Marketplace (2025)
- Integrasi pembayaran QRIS langsung (bukan hanya via Midtrans)
- Integrasi API pengiriman (JNE, J&T, GoSend)
- Integrasi marketplace (Shopee, Tokopedia, dsb) — sinkronisasi stok & pesanan

### Fase 3: Fitur Restoran & F&B
- Manajemen meja (table management), split bill, multi-payment, refund
- Kitchen Display System (KDS)
- Pengelolaan menu paket/bundling, diskon per item/nota, pajak & service charge otomatis

### Fase 4: Hardware & Operasional
- Dukungan printer struk (Bluetooth/USB, ESC/POS)
- Integrasi barcode scanner & cash drawer
- Manajemen shift & absensi karyawan, log aktivitas kasir

### Fase 5: Inventori & Analitik Lanjutan
- Transfer stok antar cabang, mutasi stok, notifikasi stok minimum
- Stock opname, histori perubahan stok
- Dashboard analitik interaktif, heatmap penjualan, prediksi stok & pelanggan churn (AI)

### Fase 6: Ekosistem & Monetisasi
- Sistem langganan Freemium (Free & Premium)
- Panel Kontrol Super Admin (manajemen pengguna, langganan, analitik platform)
- Integrasi software akuntansi (Jurnal, Accurate, dsb)

### Fitur Lain yang Akan Dikejar
- Self-service ordering (QR code scan & order)
- Membership tier/level pelanggan
- Pengelolaan promo lanjutan (happy hour, promo bundling, dsb)

Roadmap ini akan terus diperbarui sesuai kebutuhan pasar dan feedback pengguna. Prioritas pengembangan dapat disesuaikan dengan kebutuhan mitra UMKM dan tren industri.
