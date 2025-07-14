import { Controller, Post, Body, Get } from '@nestjs/common';
import { MidtransService } from './midtrans.service';

@Controller('midtrans')
export class MidtransController {
  constructor(private readonly midtransService: MidtransService) {}

  /**
   * Endpoint untuk membuat token transaksi Snap.
   * Nanti akan dipanggil dari aplikasi Flutter sebelum menampilkan halaman pembayaran.
   */
  @Post('create-transaction')
  async createTransaction(@Body() body: { orderId: string; totalAmount: number }) {
    return this.midtransService.createSnapTransaction(body.orderId, body.totalAmount);
  }

  /**
   * Endpoint untuk menerima notifikasi dari Midtrans (webhook).
   */
  @Post('webhook')
  handleWebhook(@Body() payload: any) {
    return this.midtransService.handleWebhook(payload);
  }
}