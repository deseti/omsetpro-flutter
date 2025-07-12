-- CreateTable
CREATE TABLE "LoyaltyRule" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "ownerId" INTEGER NOT NULL,
    "kelipatanRp" INTEGER NOT NULL,
    "dapatPoin" INTEGER NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "LoyaltyRule_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Reward" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "ownerId" INTEGER NOT NULL,
    "namaHadiah" TEXT NOT NULL,
    "poinDibutuhkan" INTEGER NOT NULL,
    "deskripsi" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Reward_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "PointHistory" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "pelangganId" INTEGER NOT NULL,
    "poin" INTEGER NOT NULL,
    "tipe" TEXT NOT NULL,
    "deskripsi" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "transaksiId" INTEGER,
    CONSTRAINT "PointHistory_pelangganId_fkey" FOREIGN KEY ("pelangganId") REFERENCES "Pelanggan" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PointHistory_transaksiId_fkey" FOREIGN KEY ("transaksiId") REFERENCES "Transaksi" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "LoyaltyRule_ownerId_key" ON "LoyaltyRule"("ownerId");

-- CreateIndex
CREATE UNIQUE INDEX "PointHistory_transaksiId_key" ON "PointHistory"("transaksiId");
