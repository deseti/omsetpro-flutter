import * as dotenv from 'dotenv';
dotenv.config();

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Tambahkan baris ini untuk mengaktifkan CORS
  // Ini mengizinkan permintaan dari sumber (origin) manapun.
  // Untuk produksi, ini harus lebih spesifik, tapi untuk pengembangan ini sudah cukup.
  app.enableCors();

  await app.listen(3000, '0.0.0.0');
}
bootstrap();
