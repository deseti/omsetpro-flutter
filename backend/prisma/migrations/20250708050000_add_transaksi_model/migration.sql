-- CreateTable
CREATE TABLE "Transaksi" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "total" INTEGER NOT NULL,
    "metodeBayar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "cabangId" INTEGER NOT NULL,
    "kasirId" INTEGER NOT NULL,
    CONSTRAINT "Transaksi_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_kasirId_fkey" FOREIGN KEY ("kasirId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "TransaksiDetail" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "jumlah" INTEGER NOT NULL,
    "hargaSaatItu" INTEGER NOT NULL,
    "transaksiId" INTEGER NOT NULL,
    "produkId" INTEGER NOT NULL,
    CONSTRAINT "TransaksiDetail_transaksiId_fkey" FOREIGN KEY ("transaksiId") REFERENCES "Transaksi" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "TransaksiDetail_produkId_fkey" FOREIGN KEY ("produkId") REFERENCES "Produk" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
