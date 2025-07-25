import { Module } from '@nestjs/common';
import { PengaturanController } from './pengaturan.controller';
import { PengaturanService } from './pengaturan.service';
import { PrismaService } from '../prisma.service';
import { StorageService } from '../storage/storage.service';

@Module({
  controllers: [PengaturanController],
  providers: [PengaturanService, PrismaService, StorageService],
})
export class PengaturanModule {}
