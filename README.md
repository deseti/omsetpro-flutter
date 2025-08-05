# 🚀 OmsetPro - SuperApp UMKM Indonesia

**OmsetPro** adalah platform digital modern berbasis teknologi tinggi yang dirancang khusus untuk membantu pelaku **UMKM di Indonesia** mengelola bisnis mereka secara efisien, terpusat, dan berbasis data. Dengan pendekatan **offline-first, multi-platform, dan AI-driven**, OmsetPro hadir sebagai solusi POS & manajemen bisnis masa depan untuk usaha mikro, retail, dan F&B skala kecil-menengah.

---

## 🌐 Arsitektur & Teknologi

### 🔧 Backend
- **Framework**: NestJS (Node.js)
- **ORM**: Prisma
- **Database**: SQLite (dev), siap migrasi ke **PostgreSQL** (production)
- **Fitur Inti**:
  - Multi-tenancy (satu platform, banyak bisnis)
  - Role-based access control (RBAC)
  - REST API dengan autentikasi JWT
  - Validasi input & keamanan data
  - Integrasi eksternal (Midtrans, pengiriman, marketplace – roadmap)

### 📱 Frontend
- **Framework**: Flutter (multi-platform)
- **Platform**: Android, iOS, Web, Desktop (Windows, macOS, Linux)
- **Fitur Utama**:
  - Antarmuka kasir modern
  - Manajemen produk, pelanggan, laporan
  - Mode offline dengan sinkronisasi otomatis
  - Terhubung ke backend via REST API

### 🔐 Keamanan
- Autentikasi JWT
- Enkripsi data sensitif
- Manajemen secrets (dotenv, environment isolation)
- Input validation & sanitization
- Audit log (roadmap)

---

## ✅ Fitur Utama (Sudah Diimplementasikan)

| Fitur | Deskripsi |
|------|---------|
| **🔐 Auth & User Management** | Registrasi, login aman, manajemen peran (owner, kasir, admin) |
| **🏢 Manajemen Cabang & Produk** | Owner bisa mengelola beberapa cabang dan produk secara terpusat |
| **💳 Transaksi & Mode Offline** | Kasir tetap bisa transaksi tanpa internet; data otomatis tersinkron saat kembali online |
| **📊 Dasbor Smart AI** | Insight otomatis: tren penjualan, produk terlaris, prediksi omzet (berbasis data historis) |
| **👥 Fondasi CRM & Loyalti** | Pencatatan pelanggan, riwayat pembelian, poin loyalitas dasar |
| **🎁 Promo & Diskon Dinamis** | Buat promo per item, nota, atau waktu tertentu (happy hour, flash sale) |
| **🖨️ Integrasi Hardware Dasar** | Dukungan printer struk (Bluetooth/USB, ESC/POS) dan barcode scanner |

---

## 🔍 Perbandingan Fitur: OmsetPro vs Moka POS Premium

| Fitur | OmsetPro | Moka POS (Premium) | Catatan |
|------|----------|---------------------|--------|
| **Akun Gratis & Premium** | ❌ Belum (roadmap) | ✅ Ada | Moka sudah punya model freemium |
| **Manajemen Produk & Stok** | ✅ | ✅ | Keduanya mendukung stok dasar |
| **Multi-cabang (Multi-outlet)** | ✅ | ✅ | OmsetPro dukung multi-tenancy penuh |
| **Transaksi & Mode Offline** | ✅ (offline-first design) | ✅ | OmsetPro desain offline dari awal |
| **Laporan Penjualan** | ✅ | ✅ | Moka lebih lengkap (custom report) |
| **Promo & Diskon Dinamis** | ✅ | ✅ | Keduanya mendukung aturan kompleks |
| **CRM & Loyalitas** | ✅ (dasar) | ✅ (lengkap) | Moka punya tier membership & campaign |
| **Pembayaran Digital (QRIS)** | ✅ (via Midtrans) | ✅ (Moka Pay + QRIS langsung) | Moka lebih terintegrasi dengan bank |
| **Integrasi Hardware** | ✅ (printer, scanner) | ✅ (lengkap: EDC, customer display, dll) | Moka lebih mature |
| **Self-service Ordering (QR Order)** | 🚧 Roadmap | ✅ | Moka sudah punya QR Order |
| **Manajemen Meja (Table Management)** | ❌ | ✅ | Fitur kunci untuk F&B |
| **Kitchen Display System (KDS)** | ❌ | ✅ | Moka unggul di restoran |
| **Refund & Multi-payment** | ❌ | ✅ | Moka mendukung split payment |
| **Inventori Lanjutan** | ❌ | ✅ | Transfer stok, mutasi, stock opname |
| **Shift & Absensi Karyawan** | ❌ | ✅ | Moka catat log kasir & jam kerja |
| **Integrasi Marketplace** | 🚧 (Shopee, Tokopedia) | ✅ | Moka sudah terhubung |
| **Analitik Lanjutan (AI, heatmap)** | 🚧 (roadmap) | ✅ | Moka punya dashboard prediktif |
| **Pajak & Service Charge Otomatis** | ❌ | ✅ | Fitur wajib di F&B |
| **Membership Tier Pelanggan** | ❌ | ✅ | Moka punya sistem tier berbasis poin |
| **Bundling/Combo Produk** | ❌ | ✅ | Moka mendukung paket promo |
| **Monitoring Hardware (Backend)** | ❌ | ✅ (Enterprise) | Moka bisa lacak status printer/EDC |
| **Multi-platform (Web, Desktop)** | ✅ (Flutter) | ⚠️ (terbatas) | **Keunggulan OmsetPro**: satu aplikasi untuk semua perangkat |

> ✅ = Sudah tersedia  
> 🚧 = Dalam pengembangan / roadmap  
> ❌ = Belum tersedia

---

## 🗺️ Roadmap Pengembangan (2025+)

### Fase 1: Fondasi & Fitur Dasar ✅ (Selesai)
- Auth, User & Role Management
- Manajemen Cabang & Produk
- Transaksi Offline & Sync
- CRM & Promo
- Dasbor Insight (AI-lite)

### Fase 2: Integrasi Eksternal 🚧 (Berjalan)
- Integrasi QRIS langsung (selain Midtrans)
- API pengiriman (JNE, J&T, GoSend, SiCepat)
- Integrasi marketplace: Shopee, Tokopedia, Bukalapak

### Fase 3: Fitur F&B & Restoran 🚧 (Roadmap)
- Manajemen meja (split/merge table, split bill)
- Kitchen Display System (KDS)
- Multi-payment & refund
- Bundling produk & paket menu
- Pajak & service charge otomatis

### Fase 4: Hardware & Operasional 🚧 (Berjalan)
- Dukungan printer, scanner, cash drawer
- Customer display & timbangan digital
- Manajemen shift & absensi karyawan
- Log aktivitas kasir

### Fase 5: Inventori & Analitik Lanjutan 🚧 (Roadmap)
- Transfer stok antar cabang
- Stock opname & notifikasi stok minimum
- Dashboard analitik interaktif
- Prediksi stok & churn pelanggan (dengan AI/ML)

### Fase 6: Ekosistem & Monetisasi 🚧 (Roadmap)
- **Model Freemium**: Akun Gratis + Premium
- **Super Admin Panel (Internal)**:
  - Monitoring semua tenant (bisnis, user, cabang)
  - Statistik pengguna aktif, pertumbuhan, billing
  - Audit log, kontrol akses internal
  - Export data, troubleshooting, support tools
  - Dashboard hanya untuk tim internal (engineering, support)
- Integrasi software akuntansi: Jurnal, Accurate, BukuWarung

> 📌 **Catatan**: Super Admin Panel akan dibangun sebagai modul terpisah dalam struktur **monorepo modular**, memudahkan pengembangan dan maintainability, namun tetap terintegrasi penuh dengan ekosistem.

---

## 🎯 Keunggulan Strategis OmsetPro

| Keunggulan | Penjelasan |
|-----------|------------|
| **Multi-platform Native** | Satu kode Flutter untuk Android, iOS, Web, **dan Desktop** — hemat biaya & mudah dikelola |
| **Offline-first Design** | Dirancang untuk daerah dengan internet tidak stabil |
| **Modern Tech Stack** | NestJS + Prisma + Flutter = cepat, skalabel, mudah dikembangkan |
| **Transparansi Roadmap** | Publik & terbuka — menarik developer & early adopter |
| **Fokus pada UMKM Mikro** | Solusi terjangkau untuk warung, toko kelontong, usaha rumahan |
| **Potensi Integrasi Lokal** | Bisa dikembangkan dengan mitra lokal (bank, logistik, pemerintah) |

---

## 🚀 Target Pengguna
- Warung & toko kelontong
- UMKM retail (fashion, aksesori, makanan kemasan)
- Kedai kopi & F&B skala kecil
- Usaha online (dropship, reseller)
- UMKM yang butuh solusi POS murah & fleksibel

---

## 🤝 Kontribusi & Kolaborasi

OmsetPro dibangun dengan semangat **open innovation**. Kami membuka peluang untuk:
- Developer lokal
- Mitra integrasi (pembayaran, logistik, akuntansi)
- UMKM sebagai early adopter
- Investor & ekosistem digital

---

## 📞 Kontak & Informasi Lebih Lanjut
📧 email@omsetpro.id  
🌐 www.omsetpro.id  
📱 @omsetpro_id (Instagram/TikTok)

---

> **OmsetPro – Membangkitkan Potensi UMKM Indonesia, Satu Teknologi pada Satu Waktu.**
```
