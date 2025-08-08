import { Module } from '@nestjs/common';
import { ShiftController } from './shift.controller';
import { ShiftService } from './shift.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [ShiftController],
  providers: [ShiftService, PrismaService],
})
export class ShiftModule {}
