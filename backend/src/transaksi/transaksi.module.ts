import { Module } from '@nestjs/common';
import { TransaksiService } from './transaksi.service';
import { TransaksiController } from './transaksi.controller';
import { PrismaService } from '../prisma.service'; // Import

@Module({
  controllers: [TransaksiController],
  providers: [TransaksiService, PrismaService], // Daftarkan di sini
})
export class TransaksiModule {}
