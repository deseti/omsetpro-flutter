-- CreateTable
CREATE TABLE "Promo" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "ownerId" INTEGER NOT NULL,
    "nama" TEXT NOT NULL,
    "deskripsi" TEXT,
    "tipe" TEXT NOT NULL,
    "nilai" REAL NOT NULL,
    "startDate" DATETIME,
    "endDate" DATETIME,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Promo_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ProdukPromo" (
    "promoId" INTEGER NOT NULL,
    "produkId" INTEGER NOT NULL,

    PRIMARY KEY ("promoId", "produkId"),
    CONSTRAINT "ProdukPromo_promoId_fkey" FOREIGN KEY ("promoId") REFERENCES "Promo" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "ProdukPromo_produkId_fkey" FOREIGN KEY ("produkId") REFERENCES "Produk" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Transaksi" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "total" INTEGER NOT NULL,
    "metodeBayar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "potongan" INTEGER NOT NULL DEFAULT 0,
    "cabangId" INTEGER NOT NULL,
    "kasirId" INTEGER NOT NULL,
    "pelangganId" INTEGER,
    CONSTRAINT "Transaksi_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_kasirId_fkey" FOREIGN KEY ("kasirId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_pelangganId_fkey" FOREIGN KEY ("pelangganId") REFERENCES "Pelanggan" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Transaksi" ("cabangId", "createdAt", "id", "kasirId", "metodeBayar", "pelangganId", "total") SELECT "cabangId", "createdAt", "id", "kasirId", "metodeBayar", "pelangganId", "total" FROM "Transaksi";
DROP TABLE "Transaksi";
ALTER TABLE "new_Transaksi" RENAME TO "Transaksi";
CREATE TABLE "new_TransaksiDetail" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "jumlah" INTEGER NOT NULL,
    "hargaSaatItu" INTEGER NOT NULL,
    "potonganItem" INTEGER NOT NULL DEFAULT 0,
    "transaksiId" INTEGER NOT NULL,
    "produkId" INTEGER NOT NULL,
    CONSTRAINT "TransaksiDetail_transaksiId_fkey" FOREIGN KEY ("transaksiId") REFERENCES "Transaksi" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "TransaksiDetail_produkId_fkey" FOREIGN KEY ("produkId") REFERENCES "Produk" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_TransaksiDetail" ("hargaSaatItu", "id", "jumlah", "produkId", "transaksiId") SELECT "hargaSaatItu", "id", "jumlah", "produkId", "transaksiId" FROM "TransaksiDetail";
DROP TABLE "TransaksiDetail";
ALTER TABLE "new_TransaksiDetail" RENAME TO "TransaksiDetail";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
