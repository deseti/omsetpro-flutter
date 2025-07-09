import { Role } from '@prisma/client'; // Import Enum Role dari Prisma

export class UndangUserDto {
  email: string;
  namaLengkap: string;
  password: string;
  role: Role; // Gunakan Enum Role
}