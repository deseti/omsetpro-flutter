import { Module } from '@nestjs/common';
import { TransaksiService } from './transaksi.service';
import { TransaksiController } from './transaksi.controller';
import { PrismaService } from '../prisma.service';
import { LaporanModule } from '../laporan/laporan.module';
import { LoyaltyModule } from '../loyalty/loyalty.module'; // <-- IMPORT MODUL BARU

@Module({
  imports: [LaporanModule, LoyaltyModule], // <-- TAMBAHKAN LoyaltyModule DI SINI
  controllers: [TransaksiController],
  providers: [TransaksiService, PrismaService],
})
export class TransaksiModule {}
