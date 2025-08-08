import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { CabangModule } from './cabang/cabang.module';
import { ProdukModule } from './produk/produk.module';
import { TransaksiModule } from './transaksi/transaksi.module';
import { TimModule } from './tim/tim.module';
import { LaporanModule } from './laporan/laporan.module';
import { PelangganModule } from './pelanggan/pelanggan.module';
import { LoyaltyModule } from './loyalty/loyalty.module';
import { PromoModule } from './promo/promo.module';
import { MidtransModule } from './midtrans/midtrans.module'; // <-- IMPORT MODUL BARU
import { PengaturanModule } from './pengaturan/pengaturan.module'; // <-- IMPORT MODUL PENGATURAN
import { DashboardModule } from './dashboard/dashboard.module'; // <-- IMPORT MODUL DASHBOARD
import { TokoOnlineModule } from './toko-online/toko-online.module'; // <-- IMPORT MODUL TOKO ONLINE
// Import modul fitur tambahan tim/karyawan
import { AbsensiModule } from './absensi/absensi.module';
import { ShiftModule } from './shift/shift.module';
import { GajiModule } from './gaji/gaji.module';
import { IzinModule } from './izin/izin.module';
import { AuditModule } from './audit/audit.module';
import { NotifikasiModule } from './notifikasi/notifikasi.module';

@Module({
  imports: [
    AuthModule,
    CabangModule,
    ProdukModule,
    TransaksiModule,
    TimModule,
    LaporanModule,
    PelangganModule,
    LoyaltyModule,
    PromoModule,
    MidtransModule, // <-- DAFTARKAN DI SINI
    PengaturanModule, // <-- DAFTARKAN MODUL PENGATURAN
    DashboardModule, // <-- DAFTARKAN MODUL DASHBOARD
    TokoOnlineModule, // <-- DAFTARKAN MODUL TOKO ONLINE
    // Daftarkan modul fitur tambahan tim/karyawan
    AbsensiModule,
    ShiftModule,
    GajiModule,
    IzinModule,
    AuditModule,
    NotifikasiModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
