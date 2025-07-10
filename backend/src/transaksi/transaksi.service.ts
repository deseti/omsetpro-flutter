import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateTransaksiDto } from './dto/create-transaksi.dto';

@Injectable()
export class TransaksiService {
  constructor(private prisma: PrismaService) {}

  private async verifyCabangAccess(cabangId: number, kasirId: number) {
    // 1. Cari cabang dan kasir
    const cabang = await this.prisma.cabang.findUnique({
      where: { id: cabangId },
    });
    if (!cabang) {
      throw new NotFoundException(`Cabang dengan ID ${cabangId} tidak ditemukan`);
    }

    const kasir = await this.prisma.user.findUnique({
      where: { id: kasirId },
    });
    if (!kasir) {
      throw new NotFoundException('Kasir tidak ditemukan');
    }

    // 2. Jika kasir adalah OWNER, cek kepemilikan cabang
    if (kasir.role === 'OWNER') {
      if (cabang.ownerId !== kasirId) {
        throw new ForbiddenException('Anda bukan pemilik cabang ini');
      }
      return { cabang, kasir };
    }

    // 3. Jika kasir adalah ADMIN atau KASIR, cek akses melalui tabel AksesCabang
    const akses = await this.prisma.aksesCabang.findUnique({
      where: {
        userId_cabangId: {
          userId: kasirId,
          cabangId: cabangId,
        },
      },
    });

    if (!akses) {
      throw new ForbiddenException('Anda tidak memiliki akses untuk melakukan transaksi di cabang ini');
    }

    return { cabang, kasir };
  }

  async create(createTransaksiDto: CreateTransaksiDto, kasirId: number) {
    const { cabangId, metodeBayar, items } = createTransaksiDto;

    // === VALIDASI AKSES CABANG BARU ===
    await this.verifyCabangAccess(cabangId, kasirId);

    if (!items || items.length === 0) {
      throw new BadRequestException('Keranjang belanja tidak boleh kosong.');
    }

    // Ambil semua ID produk dari keranjang untuk divalidasi
    const produkIds = items.map((item) => item.produkId);
    const produkDiDb = await this.prisma.produk.findMany({
      where: {
        id: { in: produkIds },
        cabangId: cabangId, // Pastikan semua produk dari cabang yang sama
      },
    });

    // Cek jika ada produk di keranjang yang tidak ada di database
    if (produkDiDb.length !== produkIds.length) {
      throw new BadRequestException('Beberapa produk tidak ditemukan di cabang ini.');
    }

    // Hitung total harga dan siapkan data untuk detail transaksi
    let totalHarga = 0;
    const transaksiDetailData = produkDiDb.map((produk) => {
      const itemDiKeranjang = items.find((item) => item.produkId === produk.id)!;
      
      // Cek stok
      if (produk.stok < itemDiKeranjang.jumlah) {
        throw new BadRequestException(`Stok untuk produk "${produk.nama}" tidak mencukupi.`);
      }

      totalHarga += produk.harga * itemDiKeranjang.jumlah;
      return {
        produkId: produk.id,
        jumlah: itemDiKeranjang.jumlah,
        hargaSaatItu: produk.harga,
      };
    });

    // Gunakan Prisma Transaction untuk memastikan semua operasi berhasil atau semua gagal
    return this.prisma.$transaction(async (tx) => {
      console.log('💳 === CREATING TRANSAKSI ===');
      console.log('Kasir ID:', kasirId);
      console.log('Cabang ID:', cabangId);
      console.log('Total harga:', totalHarga);
      
      // 1. Buat catatan transaksi utama
      const transaksi = await tx.transaksi.create({
        data: {
          total: totalHarga,
          metodeBayar,
          cabangId,
          kasirId,
          detail: {
            create: transaksiDetailData, // Buat semua detail transaksi sekaligus
          },
        },
        include: {
          detail: true, // Sertakan detail dalam respons
        },
      });

      console.log('✅ Transaksi created:', {
        id: transaksi.id,
        kasirId: transaksi.kasirId,
        cabangId: transaksi.cabangId,
        total: transaksi.total,
        createdAt: transaksi.createdAt
      });

      // 2. Update (kurangi) stok untuk setiap produk
      for (const item of items) {
        await tx.produk.update({
          where: { id: item.produkId },
          data: {
            stok: {
              decrement: item.jumlah,
            },
          },
        });
      }

      return transaksi;
    });
  }
}
