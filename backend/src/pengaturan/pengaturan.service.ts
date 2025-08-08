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
  // [BARU] Pengaturan Toko Online
  tokoOnlineSlug?: string;
  isTokoOnlineActive?: boolean;
  allowPickup?: boolean;
  allowDelivery?: boolean;
}

export interface RekeningBankData {
  namaBank: string;
  nomorRekening: string;
  namaPemilik: string;
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
      include: {
        rekeningBank: {
          where: { isActive: true },
          orderBy: { createdAt: 'asc' }
        }
      }
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
        tokoOnlineSlug: null,
        isTokoOnlineActive: false,
        allowPickup: true,
        allowDelivery: false,
        rekeningBank: []
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

    const data: any = {};

    // Only add fields that are provided (not undefined)
    if (updateData.nama !== undefined) data.nama = updateData.nama;
    if (updateData.alamat !== undefined) data.alamat = updateData.alamat;
    if (updateData.telepon !== undefined) data.telepon = updateData.telepon;
    if (updateData.email !== undefined) data.email = updateData.email;
    if (updateData.kategoriBisnis !== undefined) data.kategoriBisnis = updateData.kategoriBisnis;
    
    // Handle toko online fields
    if (updateData.tokoOnlineSlug !== undefined) data.tokoOnlineSlug = updateData.tokoOnlineSlug;
    if (updateData.isTokoOnlineActive !== undefined) data.isTokoOnlineActive = updateData.isTokoOnlineActive;
    if (updateData.allowPickup !== undefined) data.allowPickup = updateData.allowPickup;
    if (updateData.allowDelivery !== undefined) data.allowDelivery = updateData.allowDelivery;

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

    // Check if akun toko exists
    const existingAkunToko = await this.prisma.akunToko.findUnique({
      where: { ownerId }
    });

    let akunToko;
    if (existingAkunToko) {
      // If exists, just update with provided fields
      akunToko = await this.prisma.akunToko.update({
        where: { ownerId },
        data: data,
      });
    } else {
      // If not exists, create with required fields + provided data
      const createData = {
        ownerId,
        nama: data.nama || 'Nama Toko', // Default value if not provided
        alamat: data.alamat || '',
        telepon: data.telepon || '',
        email: data.email || '',
        kategoriBisnis: data.kategoriBisnis || 'Lainnya',
        ...data, // Override with any provided data
      };
      
      akunToko = await this.prisma.akunToko.create({
        data: createData,
      });
    }

    console.log('✅ Akun toko saved:', akunToko);
    return akunToko;
  }

  // [BARU] Mendapatkan rekening bank
  async getRekeningBank(ownerId: number) {
    const akunToko = await this.prisma.akunToko.findUnique({
      where: { ownerId },
      include: {
        rekeningBank: {
          where: { isActive: true },
          orderBy: { createdAt: 'asc' }
        }
      }
    });
    
    return akunToko?.rekeningBank || [];
  }

  // [BARU] Menambah rekening bank
  async addRekeningBank(ownerId: number, rekeningData: RekeningBankData) {
    // Pastikan akun toko sudah ada
    const akunToko = await this.prisma.akunToko.findUnique({
      where: { ownerId }
    });
    
    if (!akunToko) {
      throw new NotFoundException('Akun toko belum diatur');
    }

    return this.prisma.rekeningBank.create({
      data: {
        akunTokoId: akunToko.id,
        namaBank: rekeningData.namaBank,
        nomorRekening: rekeningData.nomorRekening,
        namaPemilik: rekeningData.namaPemilik,
      }
    });
  }

  // [BARU] Menghapus rekening bank
  async deleteRekeningBank(ownerId: number, rekeningId: number) {
    // Verifikasi ownership
    const rekening = await this.prisma.rekeningBank.findFirst({
      where: {
        id: rekeningId,
        akunToko: {
          ownerId: ownerId
        }
      }
    });

    if (!rekening) {
      throw new NotFoundException('Rekening bank tidak ditemukan');
    }

    return this.prisma.rekeningBank.update({
      where: { id: rekeningId },
      data: { isActive: false }
    });
  }
}
