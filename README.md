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



## Perbandingan Fitur OmsetPro vs Moka POS

| Fitur                                    | OmsetPro (Status) | Moka POS (Gratis) | Moka POS (Premium) |
|------------------------------------------|-------------------|-------------------|--------------------|
| Akun Gratis & Premium                    | ❌ Belum Ada      | ✅ Ada            | ✅ Ada             |
| Manajemen Produk & Stok                  | ✅ Ada            | ✅                | ✅                 |
| Multi-cabang (Multi-outlet)              | ✅ Ada            | ✅                | ✅                 |
| Transaksi Kasir & Mode Offline           | ✅ Ada            | ✅                | ✅                 |
| Laporan Penjualan                        | ✅ Ada            | ✅                | ✅                 |
| Promo & Diskon Dinamis                   | ✅ Ada            | ✅                | ✅                 |
| Loyalti & CRM                            | ✅ Ada            | ✅                | ✅                 |
| Integrasi Pembayaran Digital (Midtrans)  | ✅ Ada            | ✅ (QRIS)         | ✅ (QRIS, EDC)     |
| Integrasi Hardware POS (Printer, Scanner)| ✅ Ada (dasar)    | ✅ (dasar)        | ✅ (lengkap)       |
| Self-service Ordering (QR code)          | 🚧 Roadmap        | ❌                | ✅                 |
| Manajemen Meja (Table Management)        | ❌ Belum Ada      | ❌                | ✅                 |
| Kitchen Display System (KDS)             | ❌ Belum Ada      | ❌                | ✅                 |
| Refund & Multi-payment                   | ❌ Belum Ada      | ❌                | ✅                 |
| Inventori Lanjutan (transfer stok, dsb)  | ❌ Belum Ada      | ❌                | ✅                 |
| Shift & Absensi Karyawan                 | ❌ Belum Ada      | ❌                | ✅                 |
| Integrasi Marketplace & Akuntansi        | 🚧 Roadmap        | ❌                | ✅                 |
| Analitik Lanjutan (AI, heatmap, dsb)     | 🚧 Roadmap        | ❌                | ✅                 |
| Pajak & Service Charge Otomatis          | ❌ Belum Ada      | ❌                | ✅                 |
| Membership Tier/Level Pelanggan          | ❌ Belum Ada      | ❌                | ✅                 |
| Bundling/Combo Produk                    | ❌ Belum Ada      | ❌                | ✅                 |
| Backend Monitoring Hardware              | ❌ Belum Ada      | ❌                | ✅ (enterprise)    |

Keterangan:
- ✅ Ada: Sudah tersedia dan berjalan di OmsetPro
- 🚧 Roadmap: Sudah direncanakan, belum implementasi
- ❌ Belum Ada: Belum tersedia di OmsetPro

## Roadmap Pengembangan OmsetPro (2025+)
Roadmap ini akan terus diperbarui agar OmsetPro bisa bersaing di semua segmen (retail, F&B, enterprise):

### Fase 1: Fondasi & Fitur Dasar (Selesai)
- Auth & User Management
- Manajemen Cabang & Produk
- Transaksi & Mode Offline
- Dasbor Smart AI
- CRM, Loyalitas, Promo & Diskon

### Fase 2: Integrasi Eksternal & Marketplace (Berjalan)
- Integrasi pembayaran QRIS langsung (bukan hanya via Midtrans)
- Integrasi API pengiriman (JNE, J&T, GoSend)
- Integrasi marketplace (Shopee, Tokopedia, dsb)

### Fase 3: Fitur Restoran & F&B (Roadmap)
- Manajemen meja (table management), split/merge table, split bill
- Kitchen Display System (KDS)
- Multi-payment, refund
- Pengelolaan menu paket/bundling, diskon per item/nota, pajak & service charge otomatis

### Fase 4: Hardware & Operasional (Berjalan)
- Dukungan printer struk (Bluetooth/USB, ESC/POS)
- Integrasi barcode scanner & cash drawer
- Manajemen shift & absensi karyawan, log aktivitas kasir
- Integrasi hardware tambahan (customer display, timbangan, EDC)

### Fase 5: Inventori & Analitik Lanjutan (Roadmap)
- Transfer stok antar cabang, mutasi stok, notifikasi stok minimum
- Stock opname, histori perubahan stok
- Dashboard analitik interaktif, heatmap penjualan, prediksi stok & pelanggan churn (AI)



### Fase 6: Ekosistem & Monetisasi (Roadmap)
- Sistem langganan Freemium (Free & Premium)
- Panel Kontrol Super Admin (Admin Panel Internal, akan dibuat sebagai modul terpisah di luar folder frontend/backend, struktur monorepo & modular):
  - Monitoring semua akun (user, bisnis, cabang) beserta status (gratis/premium/berlangganan/tidak aktif)
  - Statistik jumlah user gratis vs premium, total pelanggan aktif, pertumbuhan langganan
  - Riwayat pembayaran, status billing, dan aktivitas upgrade/downgrade akun
  - Monitoring performa aplikasi, error, bug, dan uptime
  - Analitik penggunaan, pertumbuhan user, dan aktivitas pelanggan
  - Kontrol operasional: reset akun, troubleshooting, support, investigasi masalah user
  - Manajemen hak akses internal, audit log, dan keamanan data
  - Fitur export data, filter, dan pencarian user/tenant
  - Dashboard ini hanya untuk tim internal (engineering, support, manajemen) dan tidak diakses user bisnis
- Integrasi software akuntansi (Jurnal, Accurate, dsb)

> **Catatan:** Admin Panel/Super Admin Dashboard akan dibuat sebagai modul terpisah di luar folder frontend dan backend (struktur monorepo & modular), namun tetap terhubung penuh ke seluruh ekosistem OmsetPro. Dashboard ini memungkinkan tim internal memantau, mengelola, dan menganalisis seluruh aplikasi OmsetPro secara terpusat, meskipun pengelolaan kodenya terpisah untuk kemudahan pengembangan dan maintainability.

### Fitur Lain yang Akan Dikejar
- Self-service ordering (QR code scan & order)
- Membership tier/level pelanggan
- Pengelolaan promo lanjutan (happy hour, promo bundling, dsb)

Prioritas pengembangan dapat disesuaikan dengan kebutuhan mitra UMKM dan tren industri. Roadmap dan tabel fitur akan terus diperbarui agar transparan dan relevan dengan kompetisi pasar.
