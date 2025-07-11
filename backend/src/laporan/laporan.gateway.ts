import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

// @WebSocketGateway() akan memberi tahu NestJS bahwa kelas ini adalah sebuah Gateway.
// Opsi CORS mengizinkan koneksi dari semua sumber (penting untuk pengembangan).
@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class LaporanGateway implements OnGatewayConnection, OnGatewayDisconnect {
  // @WebSocketServer() memberi kita akses ke instance server Socket.IO
  // untuk bisa mengirim event ke semua klien yang terhubung.
  @WebSocketServer()
  server: Server;

  // Fungsi ini akan dipanggil setiap kali ada klien baru (frontend) yang terhubung.
  handleConnection(client: Socket, ...args: any[]) {
    console.log(`🔌 Klien terhubung: ${client.id}`);
  }

  // Fungsi ini akan dipanggil saat klien terputus.
  handleDisconnect(client: Socket) {
    console.log(`🔌 Klien terputus: ${client.id}`);
  }

  /**
   * Fungsi utama kita. Fungsi ini akan kita panggil dari service lain
   * untuk memberi tahu semua klien bahwa ada update laporan.
   * @param data - Payload yang ingin kita kirim, misal: { message: 'Transaksi baru!' }
   */
  kirimUpdateLaporan(data: any) {
    // this.server.emit() akan mengirim event 'laporan_updated' ke SEMUA klien
    // yang sedang terhubung ke gateway ini.
    this.server.emit('laporan_updated', data);
    console.log('🚀 Mengirim event laporan_updated ke semua klien.');
  }

  // Contoh fungsi untuk handle pesan dari klien (jika dibutuhkan di masa depan)
  @SubscribeMessage('pesanDariKlien')
  handleMessage(client: Socket, payload: any): string {
    console.log(`Pesan diterima dari ${client.id}:`, payload);
    return 'Pesan diterima oleh server!';
  }
}
