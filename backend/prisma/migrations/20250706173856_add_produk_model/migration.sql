-- CreateTable
CREATE TABLE "Produk" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nama" TEXT NOT NULL,
    "harga" INTEGER NOT NULL,
    "stok" INTEGER NOT NULL DEFAULT 0,
    "barcode" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "cabangId" INTEGER NOT NULL,
    CONSTRAINT "Produk_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "Produk_barcode_key" ON "Produk"("barcode");
