import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateProdukDto } from './dto/create-produk.dto';
import { UpdateProdukDto } from './dto/update-produk.dto';
import { StorageService } from '../storage/storage.service';

@Injectable()
export class ProdukService {
  constructor(
    private prisma: PrismaService,
    private storageService: StorageService,
  ) {}

  private async verifyCabangAccess(cabangId: number, userId: number) {
    // LOG: Debug userId dan cabangId yang masuk
    console.log('[verifyCabangAccess] userId:', userId, 'cabangId:', cabangId);

    // 1. Cek apakah cabang ada
    const cabang = await this.prisma.cabang.findUnique({
      where: { id: cabangId },
    });
    if (!cabang) {
      console.log('[verifyCabangAccess] Cabang tidak ditemukan:', cabangId);
      throw new NotFoundException(`Cabang dengan ID ${cabangId} tidak ditemukan`);
    }

    // 2. Cek apakah user adalah owner cabang
    if (cabang.ownerId === userId) {
      console.log('[verifyCabangAccess] User adalah owner cabang');
      return cabang; // Owner punya akses penuh
    }

    // 3. Cek apakah user punya akses melalui tabel AksesCabang (untuk ADMIN/KASIR)
    const akses = await this.prisma.aksesCabang.findUnique({
      where: {
        userId_cabangId: {
          userId: userId,
          cabangId: cabangId,
        },
      },
    });

    if (!akses) {
      console.log('[verifyCabangAccess] Tidak ada akses di tabel AksesCabang:', { userId, cabangId });
      throw new ForbiddenException('Anda tidak memiliki akses ke cabang ini');
    }

    console.log('[verifyCabangAccess] Akses ditemukan, lanjutkan.');
    return cabang;
  }

  async createMany(produkData: any[], cabangId: number, userId: number) {
    // 1. Verifikasi akses cabang sekali saja
    await this.verifyCabangAccess(cabangId, userId);

    // 2. Validasi dan format data dari file Excel
    const validatedData = produkData.map((p) => {
      // Cek kolom wajib, sekarang termasuk hargaBeli
      if (!p.nama || p.harga === undefined || p.hargaBeli === undefined) {
        throw new BadRequestException(
          'Setiap baris di file Excel harus memiliki kolom "nama", "harga", dan "hargaBeli".',
        );
      }
      return {
        nama: String(p.nama),
        hargaBeli: Number(p.hargaBeli), // Tambahkan ini
        harga: Number(p.harga),
        stok: p.stok ? Number(p.stok) : 0,
        barcode: p.barcode ? String(p.barcode) : null,
        cabangId: cabangId,
      };
    });

    // 3. Gunakan createMany dari Prisma untuk efisiensi
    const result = await this.prisma.produk.createMany({
      data: validatedData,
    });

    return {
      message: `${result.count} produk berhasil ditambahkan.`,
    };
  }

  // Fungsi upload foto (tidak berubah)
  async uploadFoto(produkId: number, file: Express.Multer.File, userId: number) {
    const produk = await this.prisma.produk.findUnique({ where: { id: produkId } });
    if (!produk) {
      throw new NotFoundException(`Produk dengan ID ${produkId} tidak ditemukan`);
    }
    await this.verifyCabangAccess(produk.cabangId, userId);
    const fotoUrl = await this.storageService.uploadFile(file);
    console.log(`Upload berhasil! URL Publik: ${fotoUrl}`);
    return this.prisma.produk.update({
      where: { id: produkId },
      data: { fotoUrl: fotoUrl },
    });
  }

  // Fungsi membuat satu produk (tidak berubah)
  async create(createProdukDto: CreateProdukDto, userId: number) {
    const { cabangId, ...produkData } = createProdukDto;
    await this.verifyCabangAccess(cabangId, userId);
    return this.prisma.produk.create({
      data: { ...produkData, cabang: { connect: { id: cabangId } } },
    });
  }

  // Fungsi mengambil semua produk per cabang (hanya yang tidak diarsip)
  async findAllByCabang(cabangId: number, userId: number) {
    await this.verifyCabangAccess(cabangId, userId);
    return this.prisma.produk.findMany({
      where: {
        cabangId,
        isArsip: false, // hanya produk yang tidak diarsip
      },
    });
  }

  // FUNGSI BARU: Mengambil semua produk dari semua cabang milik owner
  async findAllOwnerProducts(userId: number) {
    // 1. Ambil semua cabang milik owner
    const cabangList = await this.prisma.cabang.findMany({
      where: { ownerId: userId },
      select: { id: true, nama: true }
    });

    if (cabangList.length === 0) {
      return [];
    }

    // 2. Ambil semua produk dari cabang-cabang tersebut
    const cabangIds = cabangList.map(cabang => cabang.id);
    
    const produkList = await this.prisma.produk.findMany({
      where: {
        cabangId: { in: cabangIds },
        isArsip: false, // hanya produk yang tidak diarsip
      },
      include: {
        cabang: {
          select: { id: true, nama: true }
        }
      },
      orderBy: [
        { cabang: { nama: 'asc' } }, // urutkan berdasarkan nama cabang
        { nama: 'asc' } // kemudian nama produk
      ]
    });

    return produkList;
  }

  // Fungsi mengupdate satu produk (tidak berubah)
  async update(id: number, updateProdukDto: UpdateProdukDto, userId: number) {
    const produk = await this.prisma.produk.findUnique({ where: { id } });
    if (!produk) throw new NotFoundException(`Produk dengan ID ${id} tidak ditemukan`);
    await this.verifyCabangAccess(produk.cabangId, userId);
    return this.prisma.produk.update({ where: { id }, data: updateProdukDto });
  }

  // Fungsi archive (soft delete): update isArsip menjadi true
  async remove(id: number, userId: number) {
    const produk = await this.prisma.produk.findUnique({ where: { id } });
    if (!produk) {
      throw new NotFoundException(`Produk dengan ID ${id} tidak ditemukan`);
    }
    await this.verifyCabangAccess(produk.cabangId, userId);
    // Soft delete: update isArsip
    return this.prisma.produk.update({
      where: { id },
      data: {
        isArsip: true,
      },
    });
  }
}