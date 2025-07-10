import { IsOptional, IsDateString, IsInt } from 'class-validator';

export class GetLaporanDto {
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsInt()
  cabangId?: number;

  @IsOptional()
  limit?: string; // untuk produk terlaris
}

export class RingkasanPenjualanDto {
  totalOmzet: number;
  totalLaba: number;
  totalTransaksi: number;
  totalBarangTerjual: number;
  rataRataTransaksi: number;
  periode: {
    startDate: string;
    endDate: string;
  };
}

export class ProdukTerlarisDto {
  produkId: number;
  namaProduk: string;
  totalTerjual: number;
  totalOmzet: number;
  totalLaba: number;
}

export class StatistikTransaksiDto {
  tanggal: string;
  jumlahTransaksi: number;
  totalOmzet: number;
  totalLaba: number;
}

export class LaporanLabaRugiDto {
  totalPendapatan: number;
  totalPenjualan: number; // Pendapatan kotor
  totalHPP: number; // Harga Pokok Penjualan
  totalLaba: number; // Laba bersih
  margin: number; // Persentase margin
  periode: {
    startDate: string;
    endDate: string;
  };
}
