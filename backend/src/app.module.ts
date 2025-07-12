import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { CabangModule } from './cabang/cabang.module';
import { ProdukModule } from './produk/produk.module';
import { TransaksiModule } from './transaksi/transaksi.module';
import { TimModule } from './tim/tim.module';
import { LaporanModule } from './laporan/laporan.module';

@Module({
  imports: [AuthModule, CabangModule, ProdukModule, TransaksiModule, TimModule, LaporanModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
