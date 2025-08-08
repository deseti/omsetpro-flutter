export class CreateAuditLogDto {
  aksi: string;
  modul: string;
  detail?: string;
}

export class GetAuditLogDto {
  tanggalMulai?: string;
  tanggalSelesai?: string;
  userId?: number;
  aksi?: string;
  modul?: string;
  limit?: number;
  offset?: number;
}
