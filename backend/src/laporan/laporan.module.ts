import { Module } from '@nestjs/common';
import { LaporanController } from './laporan.controller';
import { LaporanService } from './laporan.service';
import { PrismaService } from '../prisma.service';
import { LaporanGateway } from './laporan.gateway'; // <-- 1. Import Gateway

@Module({
  controllers: [LaporanController],
  providers: [LaporanService, PrismaService, LaporanGateway], // <-- 2. Tambahkan di sini
  exports: [LaporanService, LaporanGateway], // Export juga LaporanGateway
})
export class LaporanModule {}
