import * as dotenv from 'dotenv';
dotenv.config();

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Tambahkan baris ini untuk mengaktifkan CORS
  // Ini mengizinkan permintaan dari sumber (origin) manapun.
  // Untuk produksi, ini harus lebih spesifik, tapi untuk pengembangan ini sudah cukup.
  app.enableCors();

  // Serve static files (untuk uploads)
  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads/',
  });

  await app.listen(3000, '0.0.0.0');
}
bootstrap();
