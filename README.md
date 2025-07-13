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

## Roadmap Resmi OmsetPro - Menuju SuperApp UMKM
Dokumen ini adalah peta jalan resmi pengembangan OmsetPro, yang mencakup visi jangka panjang untuk menjadi platform SuperApp terpusat bagi UMKM di Indonesia.

| Fase | Nama Fase                        | Status         | Tujuan Utama                                                                 |
|------|-----------------------------------|---------------|------------------------------------------------------------------------------|
| 1    | Auth & User Management           | ✅ Selesai     | Membangun sistem registrasi dan login yang aman untuk pengguna.              |
| 2    | Manajemen Cabang & Produk        | ✅ Selesai     | Memberikan kemampuan bagi Owner untuk mengelola cabang dan produk.           |
| 3    | Transaksi & Mode Offline         | ✅ Selesai     | Memastikan operasional kasir bisa berjalan lancar, bahkan tanpa internet.    |
| 4    | Dasbor Smart AI                  | ✅ Selesai     | Memberikan insight bisnis otomatis berbasis AI kepada pengguna.              |
| 5A   | Fondasi CRM                      | ✅ Selesai     | Membangun sistem untuk mencatat dan mengelola data pelanggan.                |
| 5B   | Program Loyalitas & Poin         | ✅ Selesai     | Memberikan alat bagi Owner untuk membuat program retensi pelanggan.           |
| 5C   | Sistem Promo & Diskon            | ✅ Selesai     | Memberikan kemampuan untuk membuat promo dinamis untuk meningkatkan penjualan.|
| 6    | Integrasi Eksternal (Dasar)      | ⏳ Akan Datang | Membuka kanal pembayaran digital dan pengiriman pihak ketiga.                |
| 7    | Pemesanan Mandiri (Self-Service) | ⏳ Akan Datang | Mengurangi antrian dan meningkatkan efisiensi operasional di toko.           |
| 8    | Integrasi Marketplace (SuperApp Core) | ⏳ Akan Datang | Menjadikan OmsetPro sebagai pusat kendali penjualan multi-kanal.             |
| 9    | Fitur Lanjutan & Analitik        | ⏳ Akan Datang | Memberikan insight bisnis yang lebih dalam dan manajemen inventaris.         |
| Final| Monetisasi & Operasional         | ⏳ Akan Datang | Meluncurkan produk ke pasar dan mengelola platform secara internal.          |

### Detail Fase yang Akan Datang

#### Phase 5B: Program Loyalitas & Poin
- Status: Selesai
- Fitur: Pengaturan poin & hadiah oleh Owner, akumulasi poin otomatis, dan fitur penukaran poin oleh kasir.

#### Phase 5C: Sistem Promo & Diskon
- Status: Selesai
- Fitur: Owner bisa membuat berbagai jenis promo: diskon dalam bentuk persen (%) atau nominal (Rp), promo "Beli X Gratis Y", dan promo untuk produk atau kategori tertentu.

#### Phase 6: Integrasi Eksternal (Dasar)
- Fitur: Integrasi QRIS (Midtrans/Xendit) dan integrasi API jasa pengiriman (JNE, J&T, GoSend) untuk cek ongkir dan membuat order.

#### Phase 7: Pemesanan Mandiri (Self-Service)
- Fitur: Kemampuan bagi Owner untuk mencetak QR Code yang bisa di-scan pelanggan untuk memesan dan membayar langsung dari HP mereka.

#### Phase 8: Integrasi Marketplace (SuperApp Core)
- Fitur: Sinkronisasi stok dan produk dua arah dengan Shopee, Tokopedia, dll. Pesanan dari semua marketplace masuk ke dalam satu dasbor OmsetPro.

#### Phase 9: Fitur Lanjutan & Analitik
- Fitur: Manajemen inventaris (stock opname, transfer stok) dan analitik prediktif berbasis AI (misal: prediksi pelanggan churn).

#### Phase Final: Monetisasi & Operasional
- Fitur: Implementasi sistem langganan Freemium (Free & Premium).
- Fitur: Pembangunan Panel Kontrol Tim OmsetPro (Super Admin Dashboard) untuk manajemen pengguna, langganan, dan analitik platform.
