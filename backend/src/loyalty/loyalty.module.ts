import { Module } from '@nestjs/common';
import { LoyaltyService } from './loyalty.service';
import { LoyaltyController } from './loyalty.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [LoyaltyController],
  providers: [LoyaltyService, PrismaService],
  exports: [LoyaltyService], // Ekspor service agar bisa dipakai di modul lain
})
export class LoyaltyModule {}