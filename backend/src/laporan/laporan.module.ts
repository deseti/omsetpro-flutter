import { Module } from '@nestjs/common';
import { LaporanController } from './laporan.controller';
import { LaporanService } from './laporan.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [LaporanController],
  providers: [LaporanService, PrismaService],
  exports: [LaporanService], // Export service jika dibutuhkan module lain
})
export class LaporanModule {}
