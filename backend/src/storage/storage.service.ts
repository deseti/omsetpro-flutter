import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { Storage } from '@google-cloud/storage';
import { format } from 'util';

@Injectable()
export class StorageService {
  private readonly storage: Storage;
  private readonly bucketName: string;

  constructor() {
    // --- PERBAIKAN DI SINI ---
    // Cek apakah variabel environment sudah di-set. Jika belum, lempar error.
    if (!process.env.GOOGLE_CLOUD_KEYFILE_PATH || !process.env.GCS_BUCKET_NAME) {
      throw new InternalServerErrorException(
        'Pastikan GOOGLE_CLOUD_KEYFILE_PATH dan GCS_BUCKET_NAME sudah diatur di file .env',
      );
    }

    this.storage = new Storage({
      keyFilename: process.env.GOOGLE_CLOUD_KEYFILE_PATH,
    });
    this.bucketName = process.env.GCS_BUCKET_NAME;
  }

  /**
   * Mengunggah file ke Google Cloud Storage dan mengembalikan URL publiknya.
   * @param file Objek file dari Multer
   * @returns URL publik dari file yang diunggah
   */
  async uploadFile(file: Express.Multer.File): Promise<string> {
    const bucket = this.storage.bucket(this.bucketName);
    const blob = bucket.file(`${Date.now()}-${file.originalname}`);
    
    const blobStream = blob.createWriteStream({
      resumable: false,
    });

    return new Promise((resolve, reject) => {
      blobStream.on('error', (err) => {
        reject(err);
      });

      blobStream.on('finish', () => {
        const publicUrl = format(
          `https://storage.googleapis.com/${bucket.name}/${blob.name}`,
        );
        resolve(publicUrl);
      });

      blobStream.end(file.buffer);
    });
  }
}