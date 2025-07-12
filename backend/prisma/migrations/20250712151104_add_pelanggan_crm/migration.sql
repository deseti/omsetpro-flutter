-- CreateTable
CREATE TABLE "Pelanggan" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nama" TEXT NOT NULL,
    "noHp" TEXT NOT NULL,
    "email" TEXT,
    "alamat" TEXT,
    "totalPoin" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "ownerId" INTEGER NOT NULL,
    CONSTRAINT "Pelanggan_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Transaksi" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "total" INTEGER NOT NULL,
    "metodeBayar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "cabangId" INTEGER NOT NULL,
    "kasirId" INTEGER NOT NULL,
    "pelangganId" INTEGER,
    CONSTRAINT "Transaksi_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_kasirId_fkey" FOREIGN KEY ("kasirId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_pelangganId_fkey" FOREIGN KEY ("pelangganId") REFERENCES "Pelanggan" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Transaksi" ("cabangId", "createdAt", "id", "kasirId", "metodeBayar", "total") SELECT "cabangId", "createdAt", "id", "kasirId", "metodeBayar", "total" FROM "Transaksi";
DROP TABLE "Transaksi";
ALTER TABLE "new_Transaksi" RENAME TO "Transaksi";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE UNIQUE INDEX "Pelanggan_ownerId_noHp_key" ON "Pelanggan"("ownerId", "noHp");
