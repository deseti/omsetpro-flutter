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
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "cabangId" INTEGER NOT NULL,
    CONSTRAINT "Produk_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Produk" ("barcode", "cabangId", "createdAt", "fotoUrl", "harga", "id", "nama", "stok", "updatedAt") SELECT "barcode", "cabangId", "createdAt", "fotoUrl", "harga", "id", "nama", "stok", "updatedAt" FROM "Produk";
DROP TABLE "Produk";
ALTER TABLE "new_Produk" RENAME TO "Produk";
CREATE UNIQUE INDEX "Produk_barcode_key" ON "Produk"("barcode");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
