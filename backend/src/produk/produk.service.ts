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

  private async verifyCabangOwnership(cabangId: number, userId: number) {
    const cabang = await this.prisma.cabang.findUnique({
      where: { id: cabangId },
    });
    if (!cabang) {
      throw new NotFoundException(`Cabang dengan ID ${cabangId} tidak ditemukan`);
    }
    if (cabang.ownerId !== userId) {
      throw new ForbiddenException('Anda tidak memiliki akses ke cabang ini');
    }
    return cabang;
  }

  async createMany(produkData: any[], cabangId: number, userId: number) {
    // 1. Verifikasi kepemilikan cabang sekali saja
    await this.verifyCabangOwnership(cabangId, userId);

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
    await this.verifyCabangOwnership(produk.cabangId, userId);
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
    await this.verifyCabangOwnership(cabangId, userId);
    return this.prisma.produk.create({
      data: { ...produkData, cabang: { connect: { id: cabangId } } },
    });
  }

  // Fungsi mengambil semua produk per cabang (hanya yang tidak diarsip)
  async findAllByCabang(cabangId: number, userId: number) {
    await this.verifyCabangOwnership(cabangId, userId);
    return this.prisma.produk.findMany({
      where: {
        cabangId,
        isArsip: false, // hanya produk yang tidak diarsip
      },
    });
  }

  // Fungsi mengupdate satu produk (tidak berubah)
  async update(id: number, updateProdukDto: UpdateProdukDto, userId: number) {
    const produk = await this.prisma.produk.findUnique({ where: { id } });
    if (!produk) throw new NotFoundException(`Produk dengan ID ${id} tidak ditemukan`);
    await this.verifyCabangOwnership(produk.cabangId, userId);
    return this.prisma.produk.update({ where: { id }, data: updateProdukDto });
  }

  // Fungsi archive (soft delete): update isArsip menjadi true
  async remove(id: number, userId: number) {
    const produk = await this.prisma.produk.findUnique({ where: { id } });
    if (!produk) {
      throw new NotFoundException(`Produk dengan ID ${id} tidak ditemukan`);
    }
    await this.verifyCabangOwnership(produk.cabangId, userId);
    // Soft delete: update isArsip
    return this.prisma.produk.update({
      where: { id },
      data: {
        isArsip: true,
      },
    });
  }
}