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
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
