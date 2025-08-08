import { Module } from '@nestjs/common';
import { AbsensiController } from './absensi.controller';
import { AbsensiService } from './absensi.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [AbsensiController],
  providers: [AbsensiService, PrismaService],
})
export class AbsensiModule {}
