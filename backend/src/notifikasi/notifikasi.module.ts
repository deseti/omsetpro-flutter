import { Module } from '@nestjs/common';
import { NotifikasiController } from './notifikasi.controller';
import { NotifikasiService } from './notifikasi.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [NotifikasiController],
  providers: [NotifikasiService, PrismaService],
  exports: [NotifikasiService], // Export agar bisa digunakan di module lain
})
export class NotifikasiModule {}
