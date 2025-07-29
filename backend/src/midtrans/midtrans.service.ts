import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { PrismaService } from '../prisma.service';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class MidtransService {
  private readonly midtransApiUrl = 'https://api.sandbox.midtrans.com';
  private readonly serverKey = process.env.MIDTRANS_SERVER_KEY;

  constructor(
    private readonly httpService: HttpService,
    private prisma: PrismaService,
  ) {}

  /**
   * Fungsi lama, tetap dipertahankan untuk kompatibilitas (jika masih dipakai mobile)
   */
  async createSnapTransaction(orderId: string, totalAmount: number) {
    const authString = Buffer.from(this.serverKey + ':').toString('base64');

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.midtransApiUrl}/snap/v1/transactions`,
          {
            transaction_details: {
              order_id: orderId,
              gross_amount: totalAmount,
            },
          },
          {
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
              Authorization: `Basic ${authString}`,
            },
          },
        ),
      );
      return response.data;
    } catch (error) {
      console.error(
        'Error saat membuat transaksi Snap:',
        error.response?.data || error.message,
      );
      throw new Error('Gagal membuat transaksi Snap');
    }
  }

  /**
   * [FUNGSI BARU] Dibuat khusus untuk menangani permintaan dari web.
   * Menerima detail item dan pelanggan.
   */
  async createSnapUrlForWeb(body: {
    orderId: string;
    totalAmount: number;
    items: any[];
    customerDetails: any;
  }) {
    const authString = Buffer.from(this.serverKey + ':').toString('base64');

    try {
      console.log('Creating Snap URL for web with data:', body); // Log untuk debug

      const response = await firstValueFrom(
        this.httpService.post(
          `${this.midtransApiUrl}/snap/v1/transactions`,
          {
            transaction_details: {
              order_id: body.orderId,
              gross_amount: body.totalAmount,
            },
            item_details: body.items, // Menggunakan detail item dari body
            customer_details: body.customerDetails, // Menggunakan detail pelanggan dari body
          },
          {
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
              Authorization: `Basic ${authString}`,
            },
          },
        ),
      );

      // Mengembalikan hanya URL redirect (snap_url)
      console.log('Snap URL created successfully:', response.data.redirect_url);
      return { snap_url: response.data.redirect_url };
    } catch (error) {
      console.error(
        'Error saat membuat Snap URL untuk web:',
        error.response?.data || error.message,
      );
      throw new Error('Gagal membuat Snap URL untuk web');
    }
  }

  /**
   * Fungsi untuk menangani notifikasi (webhook) dari Midtrans.
   */
  async handleWebhook(payload: any) {
    // TODO: Tambahkan logika untuk memvalidasi notifikasi
    // dan mengupdate status transaksi di database Anda.
    console.log('Webhook diterima:', payload);
    return { status: 'ok' };
  }
}
