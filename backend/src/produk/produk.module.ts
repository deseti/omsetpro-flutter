import { Module } from '@nestjs/common';
import { ProdukService } from './produk.service';
import { ProdukController } from './produk.controller';
import { PrismaService } from '../prisma.service';
import { MulterModule } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { StorageService } from '../storage/storage.service'; // Import StorageService

@Module({
  imports: [
    MulterModule.register({
      storage: memoryStorage(), // Simpan file di memori sebelum di-upload
      limits: {
        fileSize: 5 * 1024 * 1024, // Batas ukuran file 5MB
      },
    }),
  ],
  controllers: [ProdukController],
  providers: [ProdukService, PrismaService, StorageService], // Daftarkan StorageService
})
export class ProdukModule {}