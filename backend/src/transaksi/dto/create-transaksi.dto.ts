interface CartItemDto {
  produkId: number;
  jumlah: number;
}

export class CreateTransaksiDto {
  cabangId: number;
  metodeBayar: string; // Misal: "Tunai"
  items: CartItemDto[];
}