export class CreateGajiTimDto {
  userId: number;
  gajiPokok: number;
  komisiPersen?: number;
  komisiNominal?: number;
  tunjangan?: number;
}

export class UpdateGajiTimDto {
  gajiPokok?: number;
  komisiPersen?: number;
  komisiNominal?: number;
  tunjangan?: number;
  isActive?: boolean;
}

export class GetLaporanGajiDto {
  userId?: number;
  bulan?: number; // 1-12
  tahun?: number; // 2024, 2025, etc
  cabangId?: number;
}
