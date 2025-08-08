import { TipeNotifikasi } from '@prisma/client';

export class CreateNotifikasiDto {
  userId: number;
  tipe: TipeNotifikasi;
  judul: string;
  pesan: string;
  data?: string; // JSON string
}

export class GetNotifikasiDto {
  isRead?: boolean;
  tipe?: TipeNotifikasi;
  limit?: number;
  offset?: number;
}

export class MarkAsReadDto {
  notifikasiIds: number[];
}
