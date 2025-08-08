export class CreateShiftDto {
  nama: string;
  jamMulai: string; // Format: "08:00"
  jamSelesai: string; // Format: "16:00"
  cabangId: number;
}

export class UpdateShiftDto {
  nama?: string;
  jamMulai?: string;
  jamSelesai?: string;
}

export class CreateJadwalTimDto {
  userId: number;
  shiftId: number;
  tanggal: string; // Format: "YYYY-MM-DD"
}

export class GetJadwalDto {
  tanggalMulai?: string;
  tanggalSelesai?: string;
  cabangId?: number;
  userId?: number;
  shiftId?: number;
}
