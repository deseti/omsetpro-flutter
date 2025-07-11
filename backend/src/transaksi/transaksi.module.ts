import { Module } from '@nestjs/common';
import { TransaksiService } from './transaksi.service';
import { TransaksiController } from './transaksi.controller';
import { PrismaService } from '../prisma.service';
import { LaporanModule } from '../laporan/laporan.module'; // Import LaporanModule

@Module({
  imports: [LaporanModule], // Tambahkan LaporanModule di sini
  controllers: [TransaksiController],
  providers: [TransaksiService, PrismaService],
})
export class TransaksiModule {}
