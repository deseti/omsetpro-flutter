import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { StorageService } from '../storage/storage.service';

export interface AkunTokoData {
  nama: string;
  logoUrl?: string;
  alamat: string;
  telepon: string;
  email: string;
  kategoriBisnis: string;
}

@Injectable()
export class PengaturanService {
  constructor(
    private prisma: PrismaService,
    private storageService: StorageService,
  ) {}

  async getAkunToko(ownerId: number) {
    console.log('🔍 Getting akun toko for owner ID:', ownerId);
    
    const akunToko = await this.prisma.akunToko.findUnique({
      where: { ownerId },
    });

    console.log('📋 Found akun toko:', akunToko);

    if (!akunToko) {
      // Return default empty data if not found
      console.log('❌ No akun toko found, returning empty data');
      return {
        nama: '',
        logoUrl: null,
        alamat: '',
        telepon: '',
        email: '',
        kategoriBisnis: '',
      };
    }

    console.log('✅ Returning akun toko with logoUrl:', akunToko.logoUrl);
    return akunToko;
  }

  async updateAkunToko(
    ownerId: number,
    updateData: AkunTokoData,
    logoFile?: Express.Multer.File,
  ) {
    console.log('🔄 Updating akun toko for owner ID:', ownerId);
    console.log('📝 Update data:', updateData);
    console.log('🖼️ Logo file:', logoFile ? `${logoFile.originalname} (${logoFile.size} bytes)` : 'No file');

    const data: any = {
      nama: updateData.nama,
      alamat: updateData.alamat,
      telepon: updateData.telepon,
      email: updateData.email,
      kategoriBisnis: updateData.kategoriBisnis,
    };

    // If logo file is uploaded, save to GCP Storage
    if (logoFile) {
      try {
        console.log('📤 Uploading logo to GCP Storage...');
        const logoUrl = await this.storageService.uploadFile(logoFile);
        console.log('✅ Logo uploaded successfully, URL:', logoUrl);
        data.logoUrl = logoUrl;
      } catch (error) {
        console.error('❌ Error uploading logo to GCP:', error);
        // Jika upload gagal, jangan set logoUrl (akan tetap menggunakan yang lama)
      }
    }

    console.log('💾 Final data to save:', data);

    const akunToko = await this.prisma.akunToko.upsert({
      where: { ownerId },
      create: {
        ownerId,
        ...data,
      },
      update: data,
    });

    console.log('✅ Akun toko saved:', akunToko);
    return akunToko;
  }
}
