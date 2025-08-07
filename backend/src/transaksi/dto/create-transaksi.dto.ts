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
}