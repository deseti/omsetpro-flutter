export class CreateProdukDto {
  nama: string;
  kategori?: string;
  hargaBeli: number; // Tambahkan hargaBeli
  harga: number;
  stok: number;
  barcode?: string;
  cabangId: number;
}