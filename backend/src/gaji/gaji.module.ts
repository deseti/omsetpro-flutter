import { Module } from '@nestjs/common';
import { GajiController } from './gaji.controller';
import { GajiService } from './gaji.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [GajiController],
  providers: [GajiService, PrismaService],
})
export class GajiModule {}
