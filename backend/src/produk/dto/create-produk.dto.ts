export class CreateProdukDto {
  nama: string;
  hargaBeli: number; // Tambahkan hargaBeli
  harga: number;
  stok: number;
  barcode?: string;
  cabangId: number;
}