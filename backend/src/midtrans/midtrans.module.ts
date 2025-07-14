import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios'; // <-- 1. Import HttpModule
import { MidtransService } from './midtrans.service';
import { MidtransController } from './midtrans.controller';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [HttpModule], // <-- 2. Daftarkan HttpModule di sini
  controllers: [MidtransController],
  providers: [MidtransService, PrismaService],
})
export class MidtransModule {}