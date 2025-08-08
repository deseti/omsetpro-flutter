import { TipeIzin, StatusIzin } from '@prisma/client';

export class CreateIzinTimDto {
  tipe: TipeIzin;
  tanggalMulai: string; // Format: "YYYY-MM-DD"
  tanggalSelesai: string; // Format: "YYYY-MM-DD"
  alasan: string;
}

export class UpdateStatusIzinDto {
  status: StatusIzin;
  catatan?: string;
}

export class GetIzinTimDto {
  tanggalMulai?: string;
  tanggalSelesai?: string;
  userId?: number;
  tipe?: TipeIzin;
  status?: StatusIzin;
}
