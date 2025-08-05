import { Controller, Post, Body, Get } from '@nestjs/common';
import { MidtransService } from './midtrans.service';

@Controller('midtrans')
export class MidtransController {
  constructor(private readonly midtransService: MidtransService) {}

  /**
   * Endpoint lama, untuk membuat token transaksi Snap.
   * Dipakai oleh mobile. Updated untuk handle data lengkap.
   */
  @Post('create-transaction')
  async createTransaction(
    @Body() body: { 
      orderId: string; 
      totalAmount: number;
      items?: any[];
      customerDetails?: any;
      platform?: string;
    },
  ) {
    // Jika ada items dan customerDetails, gunakan service web yang lengkap
    if (body.items && body.customerDetails) {
      const result = await this.midtransService.createSnapUrlForWeb({
        orderId: body.orderId,
        totalAmount: body.totalAmount,
        items: body.items,
        customerDetails: body.customerDetails,
      });
      
      // Return format yang konsisten untuk mobile
      return {
        token: result.snap_token,
        snap_url: result.snap_url,
        redirect_url: result.snap_url, // Backward compatibility
      };
    }
    
    // Fallback ke service lama untuk compatibility
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
