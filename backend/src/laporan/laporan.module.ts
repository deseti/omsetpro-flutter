import { Module } from '@nestjs/common';
import { LaporanController } from './laporan.controller';
// import { LaporanService } from './laporan.service'; // NONAKTIF - fitur laporan manual dihapus
import { InsightService } from './insight.service';
import { PrismaService } from '../prisma.service';
import { LaporanGateway } from './laporan.gateway'; // <-- 1. Import Gateway

@Module({
  controllers: [LaporanController],
  providers: [InsightService, PrismaService, LaporanGateway], // NONAKTIF LaporanService - fitur laporan manual dihapus
  exports: [InsightService, LaporanGateway], // NONAKTIF LaporanService - fitur laporan manual dihapus
})
export class LaporanModule {}
