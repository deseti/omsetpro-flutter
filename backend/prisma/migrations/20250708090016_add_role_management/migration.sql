-- CreateTable
CREATE TABLE "AksesCabang" (
    "userId" INTEGER NOT NULL,
    "cabangId" INTEGER NOT NULL,

    PRIMARY KEY ("userId", "cabangId"),
    CONSTRAINT "AksesCabang_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "AksesCabang_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Produk" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nama" TEXT NOT NULL,
    "hargaBeli" INTEGER NOT NULL DEFAULT 0,
    "harga" INTEGER NOT NULL,
    "stok" INTEGER NOT NULL DEFAULT 0,
    "barcode" TEXT,
    "fotoUrl" TEXT,
    "isArsip" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "cabangId" INTEGER NOT NULL,
    CONSTRAINT "Produk_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_Produk" ("barcode", "cabangId", "createdAt", "fotoUrl", "harga", "hargaBeli", "id", "isArsip", "nama", "stok", "updatedAt") SELECT "barcode", "cabangId", "createdAt", "fotoUrl", "harga", "hargaBeli", "id", "isArsip", "nama", "stok", "updatedAt" FROM "Produk";
DROP TABLE "Produk";
ALTER TABLE "new_Produk" RENAME TO "Produk";
CREATE UNIQUE INDEX "Produk_barcode_key" ON "Produk"("barcode");
CREATE TABLE "new_Transaksi" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "total" INTEGER NOT NULL,
    "metodeBayar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "cabangId" INTEGER NOT NULL,
    "kasirId" INTEGER NOT NULL,
    CONSTRAINT "Transaksi_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_kasirId_fkey" FOREIGN KEY ("kasirId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Transaksi" ("cabangId", "createdAt", "id", "kasirId", "metodeBayar", "total") SELECT "cabangId", "createdAt", "id", "kasirId", "metodeBayar", "total" FROM "Transaksi";
DROP TABLE "Transaksi";
ALTER TABLE "new_Transaksi" RENAME TO "Transaksi";
CREATE TABLE "new_TransaksiDetail" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "jumlah" INTEGER NOT NULL,
    "hargaSaatItu" INTEGER NOT NULL,
    "transaksiId" INTEGER NOT NULL,
    "produkId" INTEGER NOT NULL,
    CONSTRAINT "TransaksiDetail_transaksiId_fkey" FOREIGN KEY ("transaksiId") REFERENCES "Transaksi" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "TransaksiDetail_produkId_fkey" FOREIGN KEY ("produkId") REFERENCES "Produk" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_TransaksiDetail" ("hargaSaatItu", "id", "jumlah", "produkId", "transaksiId") SELECT "hargaSaatItu", "id", "jumlah", "produkId", "transaksiId" FROM "TransaksiDetail";
DROP TABLE "TransaksiDetail";
ALTER TABLE "new_TransaksiDetail" RENAME TO "TransaksiDetail";
CREATE TABLE "new_User" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "email" TEXT NOT NULL,
    "namaLengkap" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'OWNER',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_User" ("createdAt", "email", "id", "namaLengkap", "password", "updatedAt") SELECT "createdAt", "email", "id", "namaLengkap", "password", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
