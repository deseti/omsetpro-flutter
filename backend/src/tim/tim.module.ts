import { Module } from '@nestjs/common';
import { TimService } from './tim.service';
import { TimController } from './tim.controller';
import { PrismaService } from '../prisma.service'; // Import

@Module({
  controllers: [TimController],
  providers: [TimService, PrismaService], // Daftarkan di sini
})
export class TimModule {}