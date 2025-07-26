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
    const fileName = `${Date.now()}-${file.originalname}`;
    const blob = bucket.file(fileName);
    
    const blobStream = blob.createWriteStream({
      resumable: false,
      metadata: {
        contentType: file.mimetype,
        cacheControl: 'public, max-age=31536000',
      },
    });

    return new Promise((resolve, reject) => {
      blobStream.on('error', (err) => {
        console.error('❌ Error uploading file:', err);
        reject(new InternalServerErrorException('Gagal mengunggah file ke storage'));
      });

      blobStream.on('finish', async () => {
        try {
          console.log('📁 File uploaded successfully to GCS');
          
          // Coba membuat file public
          try {
            await blob.makePublic();
            console.log('✅ File made public successfully');
          } catch (publicError) {
            console.log('⚠️ Cannot make file public (likely uniform bucket-level access):', publicError.message);
            // Lanjutkan dengan URL public (asumsi bucket sudah dikonfigurasi public)
          }
          
          const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
          console.log('✅ Upload completed! Public URL:', publicUrl);
          resolve(publicUrl);
        } catch (error) {
          console.error('❌ Error processing uploaded file:', error);
          reject(new InternalServerErrorException('Gagal memproses file yang diunggah'));
        }
      });

      blobStream.end(file.buffer);
    });
  }
}