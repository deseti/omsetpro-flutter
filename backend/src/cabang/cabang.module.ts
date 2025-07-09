import { Module } from '@nestjs/common';
import { CabangService } from './cabang.service';
import { CabangController } from './cabang.controller';
import { PrismaService } from '../prisma.service'; // Import

@Module({
  controllers: [CabangController],
  providers: [CabangService, PrismaService], // Daftarkan di sini
})
export class CabangModule {}