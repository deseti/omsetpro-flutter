export class SetLoyaltyRuleDto {
  kelipatanRp: number;
  dapatPoin: number;
}

export class CreateRewardDto {
  namaHadiah: string;
  poinDibutuhkan: number;
  deskripsi?: string;
}

export class UpdateRewardDto {
  namaHadiah?: string;
  poinDibutuhkan?: number;
  deskripsi?: string;
  isActive?: boolean;
}

export class RedeemRewardDto {
  pelangganId: number;
  rewardId: number;
}