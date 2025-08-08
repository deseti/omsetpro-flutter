import { AbsensiStatus } from '@prisma/client';

export class CheckInDto {
  cabangId: number;
  catatan?: string;
}

export class CheckOutDto {
  absensiId: number;
  catatan?: string;
}

export class UpdateAbsensiDto {
  status: AbsensiStatus;
  catatan?: string;
}

export class GetAbsensiDto {
  tanggalMulai?: string;
  tanggalSelesai?: string;
  cabangId?: number;
  userId?: number;
  status?: AbsensiStatus;
}
