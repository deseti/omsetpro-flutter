import { PromoTipe } from '@prisma/client';

export class CreatePromoDto {
  nama: string;
  deskripsi?: string;
  tipe: PromoTipe; // 'PERCENTAGE' atau 'NOMINAL'
  nilai: number;
  startDate?: Date;
  endDate?: Date;
  produkIds: number[]; // Daftar ID produk yang berlaku untuk promo ini
}

export class UpdatePromoDto {
  nama?: string;
  deskripsi?: string;
  tipe?: PromoTipe;
  nilai?: number;
  startDate?: Date;
  endDate?: Date;
  isActive?: boolean;
  produkIds?: number[];
}