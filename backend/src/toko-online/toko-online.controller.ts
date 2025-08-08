import { Controller, Get, Post, Param, Body, BadRequestException } from '@nestjs/common';
import { TokoOnlineService, TokoOnlineOrderDto } from './toko-online.service';

@Controller('toko')
export class TokoOnlineController {
  constructor(private readonly tokoOnlineService: TokoOnlineService) {}

  // API publik untuk melihat toko online berdasarkan slug
  @Get(':slug')
  async getTokoBySlug(@Param('slug') slug: string) {
    if (!slug || slug.trim() === '') {
      throw new BadRequestException('Slug toko tidak boleh kosong');
    }
    
    return this.tokoOnlineService.getTokoBySlug(slug);
  }

  // API publik untuk membuat pesanan
  @Post(':slug/order')
  async createOrder(
    @Param('slug') slug: string,
    @Body() orderData: TokoOnlineOrderDto,
  ) {
    if (!slug || slug.trim() === '') {
      throw new BadRequestException('Slug toko tidak boleh kosong');
    }

    // Validasi data pesanan
    if (!orderData.items || orderData.items.length === 0) {
      throw new BadRequestException('Keranjang belanja tidak boleh kosong');
    }

    if (!orderData.namaPelanggan || orderData.namaPelanggan.trim() === '') {
      throw new BadRequestException('Nama pelanggan harus diisi');
    }

    if (!orderData.noHpPelanggan || orderData.noHpPelanggan.trim() === '') {
      throw new BadRequestException('Nomor HP pelanggan harus diisi');
    }

    if (!['Diambil', 'Diantar'].includes(orderData.tipePengiriman)) {
      throw new BadRequestException('Tipe pengiriman tidak valid');
    }

    return this.tokoOnlineService.createOrder(slug, orderData);
  }
}
