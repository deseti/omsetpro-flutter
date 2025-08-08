interface CartItemDto {
  produkId: number;
  jumlah: number;
}

export class CreateTransaksiDto {
  cabangId: number;
  metodeBayar: string; // Misal: "Tunai"
  items: CartItemDto[];
  pelangganId?: number; // [BARU] Tambahkan field ini (opsional)
  orderId?: string; // [BARU] Untuk pembayaran digital/Midtrans
  // [BARU] Fields untuk Toko Online
  sumberTransaksi?: string; // "Kasir" atau "TokoOnline"
  tipePengiriman?: string; // "Diambil" atau "Diantar"
  namaPelangganOnline?: string; // Nama pelanggan untuk toko online
  noHpPelangganOnline?: string; // No HP pelanggan untuk toko online
}