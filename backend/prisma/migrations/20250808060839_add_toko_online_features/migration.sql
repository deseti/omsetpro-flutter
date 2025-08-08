-- CreateTable
CREATE TABLE "RekeningBank" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "akunTokoId" INTEGER NOT NULL,
    "namaBank" TEXT NOT NULL,
    "nomorRekening" TEXT NOT NULL,
    "namaPemilik" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "RekeningBank_akunTokoId_fkey" FOREIGN KEY ("akunTokoId") REFERENCES "AkunToko" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_AkunToko" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "ownerId" INTEGER NOT NULL,
    "nama" TEXT NOT NULL,
    "logoUrl" TEXT,
    "alamat" TEXT NOT NULL,
    "telepon" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "kategoriBisnis" TEXT NOT NULL,
    "tokoOnlineSlug" TEXT,
    "isTokoOnlineActive" BOOLEAN NOT NULL DEFAULT false,
    "allowPickup" BOOLEAN NOT NULL DEFAULT true,
    "allowDelivery" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "AkunToko_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_AkunToko" ("alamat", "createdAt", "email", "id", "kategoriBisnis", "logoUrl", "nama", "ownerId", "telepon", "updatedAt") SELECT "alamat", "createdAt", "email", "id", "kategoriBisnis", "logoUrl", "nama", "ownerId", "telepon", "updatedAt" FROM "AkunToko";
DROP TABLE "AkunToko";
ALTER TABLE "new_AkunToko" RENAME TO "AkunToko";
CREATE UNIQUE INDEX "AkunToko_ownerId_key" ON "AkunToko"("ownerId");
CREATE UNIQUE INDEX "AkunToko_tokoOnlineSlug_key" ON "AkunToko"("tokoOnlineSlug");
CREATE TABLE "new_Transaksi" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "total" INTEGER NOT NULL,
    "metodeBayar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "orderId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "potongan" INTEGER NOT NULL DEFAULT 0,
    "sumberTransaksi" TEXT NOT NULL DEFAULT 'Kasir',
    "tipePengiriman" TEXT,
    "namaPelangganOnline" TEXT,
    "noHpPelangganOnline" TEXT,
    "cabangId" INTEGER NOT NULL,
    "kasirId" INTEGER NOT NULL,
    "pelangganId" INTEGER,
    CONSTRAINT "Transaksi_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_kasirId_fkey" FOREIGN KEY ("kasirId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_pelangganId_fkey" FOREIGN KEY ("pelangganId") REFERENCES "Pelanggan" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Transaksi" ("cabangId", "createdAt", "id", "kasirId", "metodeBayar", "orderId", "pelangganId", "potongan", "status", "total") SELECT "cabangId", "createdAt", "id", "kasirId", "metodeBayar", "orderId", "pelangganId", "potongan", "status", "total" FROM "Transaksi";
DROP TABLE "Transaksi";
ALTER TABLE "new_Transaksi" RENAME TO "Transaksi";
CREATE UNIQUE INDEX "Transaksi_orderId_key" ON "Transaksi"("orderId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
