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

      // Mengembalikan snap_token dan snap_url untuk web
      console.log('Snap transaction created successfully:', {
        token: response.data.token,
        redirect_url: response.data.redirect_url
      });
      
      return { 
        snap_token: response.data.token,
        snap_url: response.data.redirect_url 
      };
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
    try {
      console.log('📨 Webhook diterima dari Midtrans:', payload);
      
      const orderId = payload.order_id;
      const transactionStatus = payload.transaction_status;
      const fraudStatus = payload.fraud_status;
      const paymentType = payload.payment_type;
      const grossAmount = payload.gross_amount;
      
      console.log(`🔍 Processing webhook for order ${orderId} with status ${transactionStatus}`);
      
      // Validasi signature dari Midtrans (untuk keamanan)
      const serverKey = this.serverKey;
      const signatureKey = payload.signature_key;
      const expectedSignature = require('crypto')
        .createHash('sha512')
        .update(orderId + payload.status_code + grossAmount + serverKey)
        .digest('hex');
      
      if (signatureKey !== expectedSignature) {
        console.error('❌ Invalid signature from Midtrans webhook');
        throw new Error('Invalid signature');
      }
      
      // Proses berdasarkan status transaksi
      if (transactionStatus === 'capture') {
        if (fraudStatus === 'challenge') {
          // TODO: Set transaction status to challenge
          console.log('⚠️ Transaction challenged, need manual review');
        } else if (fraudStatus === 'accept') {
          // TODO: Set transaction status to success
          console.log('✅ Transaction captured and accepted');
          await this.updateTransactionStatus(orderId, 'paid', paymentType);
        }
      } else if (transactionStatus === 'settlement') {
        // TODO: Set transaction status to success
        console.log('✅ Transaction settled');
        await this.updateTransactionStatus(orderId, 'paid', paymentType);
      } else if (transactionStatus === 'cancel' || 
                 transactionStatus === 'deny' || 
                 transactionStatus === 'expire') {
        // TODO: Set transaction status to failure
        console.log('❌ Transaction failed/cancelled');
        await this.updateTransactionStatus(orderId, 'failed', paymentType);
      } else if (transactionStatus === 'pending') {
        // TODO: Set transaction status to pending
        console.log('⏳ Transaction pending');
        await this.updateTransactionStatus(orderId, 'pending', paymentType);
      }
      
      return { status: 'ok' };
    } catch (error) {
      console.error('❌ Error processing webhook:', error);
      throw error;
    }
  }
  
  /**
   * Helper function untuk update status transaksi di database
   */
  private async updateTransactionStatus(orderId: string, status: string, paymentMethod: string) {
    try {
      // Cari transaksi berdasarkan orderId atau metadata lain
      // Karena orderId dari Midtrans mungkin berbeda dengan ID transaksi internal
      console.log(`🔄 Updating transaction status for ${orderId} to ${status}`);
      
      // Implementasi update ke database
      const transaction = await this.prisma.transaksi.findFirst({
        where: { 
          orderId: orderId 
        }
      });
      
      if (transaction) {
        await this.prisma.transaksi.update({
          where: { id: transaction.id },
          data: { 
            status: status,
            metodeBayar: paymentMethod
          }
        });
        console.log(`✅ Transaction ${orderId} status updated to ${status} in database`);
      } else {
        console.log(`⚠️ Transaction ${orderId} not found in database`);
      }
      
    } catch (error) {
      console.error(`❌ Error updating transaction ${orderId}:`, error);
      throw error;
    }
  }
}
