import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios'; // <-- Import dari @nestjs/axios
import { PrismaService } from '../prisma.service';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class MidtransService {
  private readonly midtransApiUrl = 'https://api.sandbox.midtrans.com';
  private readonly serverKey = process.env.MIDTRANS_SERVER_KEY;

  // Inject HttpService dan PrismaService di constructor
  constructor(
    private readonly httpService: HttpService, // <-- 1. Inject HttpService
    private prisma: PrismaService,
  ) {}

  /**
   * Fungsi untuk membuat transaksi Snap (halaman pembayaran Midtrans).
   * Ini adalah contoh pertama yang bisa kita coba.
   * @param orderId ID unik untuk transaksi Anda
   * @param totalAmount Jumlah total yang harus dibayar
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
            // Tambahkan detail customer jika ada
            // customer_details: { ... }
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': `Basic ${authString}`,
            },
          },
        ),
      );

      // Mengembalikan token atau URL redirect dari Midtrans
      return response.data;
    } catch (error) {
      console.error('Error saat membuat transaksi Snap:', error.response?.data || error.message);
      throw new Error('Gagal membuat transaksi Snap');
    }
  }

  /**
   * Fungsi untuk menangani notifikasi (webhook) dari Midtrans.
   * @param payload Data yang dikirim oleh Midtrans
   */
  async handleWebhook(payload: any) {
    // TODO: Tambahkan logika untuk memvalidasi notifikasi
    // dan mengupdate status transaksi di database Anda.
    console.log('Webhook diterima:', payload);
    return { status: 'ok' };
  }
}