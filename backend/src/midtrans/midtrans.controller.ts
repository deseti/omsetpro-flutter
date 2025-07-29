import { Controller, Post, Body, Get } from '@nestjs/common';
import { MidtransService } from './midtrans.service';

@Controller('midtrans')
export class MidtransController {
  constructor(private readonly midtransService: MidtransService) {}

  /**
   * Endpoint lama, untuk membuat token transaksi Snap.
   * Dipakai oleh mobile.
   */
  @Post('create-transaction')
  async createTransaction(
    @Body() body: { orderId: string; totalAmount: number },
  ) {
    return this.midtransService.createSnapTransaction(
      body.orderId,
      body.totalAmount,
    );
  }

  /**
   * [ENDPOINT BARU] Endpoint khusus untuk membuat Snap URL untuk web.
   * Menerima detail yang lebih lengkap dari frontend web.
   */
  @Post('create-snap-url')
  async createSnapUrlForWeb(
    @Body()
    body: {
      orderId: string;
      totalAmount: number;
      items: any[];
      customerDetails: any;
    },
  ) {
    return this.midtransService.createSnapUrlForWeb(body);
  }

  /**
   * Endpoint untuk menerima notifikasi dari Midtrans (webhook).
   */
  @Post('webhook')
  handleWebhook(@Body() payload: any) {
    return this.midtransService.handleWebhook(payload);
  }
}
