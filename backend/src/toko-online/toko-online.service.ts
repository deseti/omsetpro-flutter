import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

export interface TokoOnlineOrderDto {
  items: Array<{
    produkId: number;
    jumlah: number;
  }>;
  namaPelanggan: string;
  noHpPelanggan: string;
  tipePengiriman: 'Diambil' | 'Diantar';
}

@Injectable()
export class TokoOnlineService {
  constructor(private prisma: PrismaService) {}

  // Mendapatkan data toko online berdasarkan slug
  async getTokoBySlug(slug: string) {
    const akunToko = await this.prisma.akunToko.findFirst({
      where: {
        tokoOnlineSlug: slug,
        isTokoOnlineActive: true,
      },
      include: {
        owner: {
          include: {
            cabangDimiliki: {
              include: {
                produk: {
                  where: {
                    isArsip: false,
                    stok: {
                      gt: 0, // Hanya produk yang masih ada stok
                    },
                  },
                  orderBy: {
                    nama: 'asc',
                  },
                },
              },
            },
          },
        },
        rekeningBank: {
          where: {
            isActive: true,
          },
          orderBy: {
            createdAt: 'asc',
          },
        },
      },
    });

    if (!akunToko) {
      throw new NotFoundException('Toko online tidak ditemukan atau tidak aktif');
    }

    // Gabungkan semua produk dari semua cabang
    const allProduk = akunToko.owner.cabangDimiliki.reduce((acc, cabang) => {
      const produkDenganCabang = cabang.produk.map(produk => ({
        ...produk,
        cabangId: cabang.id,
        cabangNama: cabang.nama,
      }));
      return [...acc, ...produkDenganCabang];
    }, []);

    return {
      id: akunToko.id,
      nama: akunToko.nama,
      logoUrl: akunToko.logoUrl,
      alamat: akunToko.alamat,
      telepon: akunToko.telepon,
      email: akunToko.email,
      allowPickup: akunToko.allowPickup,
      allowDelivery: akunToko.allowDelivery,
      produk: allProduk,
      rekeningBank: akunToko.rekeningBank,
      ownerId: akunToko.ownerId,
    };
  }

  // Membuat pesanan baru dari toko online
  async createOrder(slug: string, orderData: TokoOnlineOrderDto) {
    const toko = await this.getTokoBySlug(slug);

    // Validasi tipe pengiriman yang diizinkan
    if (orderData.tipePengiriman === 'Diambil' && !toko.allowPickup) {
      throw new BadRequestException('Toko tidak melayani pickup');
    }
    if (orderData.tipePengiriman === 'Diantar' && !toko.allowDelivery) {
      throw new BadRequestException('Toko tidak melayani delivery');
    }

    // Validasi produk dan stok
    const produkIds = orderData.items.map(item => item.produkId);
    const produkList = await this.prisma.produk.findMany({
      where: {
        id: { in: produkIds },
        isArsip: false,
        cabang: {
          ownerId: toko.ownerId,
        },
      },
      include: {
        cabang: true,
      },
    });

    if (produkList.length !== produkIds.length) {
      throw new BadRequestException('Beberapa produk tidak ditemukan');
    }

    // Cek stok dan hitung total
    let totalHarga = 0;
    const transaksiDetails: Array<{
      produkId: number;
      jumlah: number;
      hargaSaatItu: number;
      potonganItem: number;
    }> = [];

    for (const item of orderData.items) {
      const produk = produkList.find(p => p.id === item.produkId);
      if (!produk) {
        throw new BadRequestException(`Produk dengan ID ${item.produkId} tidak ditemukan`);
      }

      if (produk.stok < item.jumlah) {
        throw new BadRequestException(`Stok untuk produk "${produk.nama}" tidak mencukupi`);
      }

      const subtotal = produk.harga * item.jumlah;
      totalHarga += subtotal;

      transaksiDetails.push({
        produkId: produk.id,
        jumlah: item.jumlah,
        hargaSaatItu: produk.harga,
        potonganItem: 0,
      });
    }

    // Gunakan cabang dari produk pertama sebagai default
    const defaultCabangId = produkList[0].cabangId;

    // Buat transaksi
    return this.prisma.$transaction(async (tx) => {
      const transaksi = await tx.transaksi.create({
        data: {
          total: totalHarga,
          potongan: 0,
          metodeBayar: 'Transfer Manual',
          sumberTransaksi: 'TokoOnline',
          tipePengiriman: orderData.tipePengiriman,
          namaPelangganOnline: orderData.namaPelanggan,
          noHpPelangganOnline: orderData.noHpPelanggan,
          status: 'pending',
          cabangId: defaultCabangId,
          kasirId: toko.ownerId, // Owner sebagai kasir untuk transaksi online
          detail: {
            create: transaksiDetails,
          },
        },
        include: {
          detail: {
            include: {
              produk: {
                select: {
                  id: true,
                  nama: true,
                  fotoUrl: true,
                },
              },
            },
          },
          cabang: {
            select: {
              id: true,
              nama: true,
            },
          },
        },
      });

      // Update stok produk
      for (const item of orderData.items) {
        await tx.produk.update({
          where: { id: item.produkId },
          data: { stok: { decrement: item.jumlah } },
        });
      }

      return transaksi;
    });
  }
}
