import { Module } from '@nestjs/common';
import { TokoOnlineController } from './toko-online.controller';
import { TokoOnlineService } from './toko-online.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [TokoOnlineController],
  providers: [TokoOnlineService, PrismaService],
})
export class TokoOnlineModule {}
