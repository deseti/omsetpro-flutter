import { Module } from '@nestjs/common';
import { IzinController } from './izin.controller';
import { IzinService } from './izin.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [IzinController],
  providers: [IzinService, PrismaService],
})
export class IzinModule {}
