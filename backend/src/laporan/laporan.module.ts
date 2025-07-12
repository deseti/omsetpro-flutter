import { Module } from '@nestjs/common';
import { LaporanController } from './laporan.controller';
import { LaporanService } from './laporan.service';
import { InsightService } from './insight.service';
import { PrismaService } from '../prisma.service';
import { LaporanGateway } from './laporan.gateway'; // <-- 1. Import Gateway

@Module({
  controllers: [LaporanController],
  providers: [LaporanService, InsightService, PrismaService, LaporanGateway], // <-- 2. Tambahkan InsightService
  exports: [LaporanService, InsightService, LaporanGateway], // Export juga InsightService
})
export class LaporanModule {}
