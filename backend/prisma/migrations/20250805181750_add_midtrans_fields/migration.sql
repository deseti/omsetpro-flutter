-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Transaksi" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "total" INTEGER NOT NULL,
    "metodeBayar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "orderId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "potongan" INTEGER NOT NULL DEFAULT 0,
    "cabangId" INTEGER NOT NULL,
    "kasirId" INTEGER NOT NULL,
    "pelangganId" INTEGER,
    CONSTRAINT "Transaksi_cabangId_fkey" FOREIGN KEY ("cabangId") REFERENCES "Cabang" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_kasirId_fkey" FOREIGN KEY ("kasirId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_pelangganId_fkey" FOREIGN KEY ("pelangganId") REFERENCES "Pelanggan" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Transaksi" ("cabangId", "createdAt", "id", "kasirId", "metodeBayar", "pelangganId", "potongan", "total") SELECT "cabangId", "createdAt", "id", "kasirId", "metodeBayar", "pelangganId", "potongan", "total" FROM "Transaksi";
DROP TABLE "Transaksi";
ALTER TABLE "new_Transaksi" RENAME TO "Transaksi";
CREATE UNIQUE INDEX "Transaksi_orderId_key" ON "Transaksi"("orderId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
