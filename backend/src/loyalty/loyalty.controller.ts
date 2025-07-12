import { Controller, Post, Body, Get, Patch, Param, UseGuards, Request, ParseIntPipe } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { LoyaltyService } from './loyalty.service';
import { SetLoyaltyRuleDto, CreateRewardDto, UpdateRewardDto, RedeemRewardDto } from './dto/loyalty.dto';

@UseGuards(AuthGuard('jwt'))
@Controller('loyalty')
export class LoyaltyController {
  constructor(private readonly loyaltyService: LoyaltyService) {}

  // Endpoint untuk mengatur aturan perolehan poin
  @Post('rules')
  setRule(@Body() setLoyaltyRuleDto: SetLoyaltyRuleDto, @Request() req) {
    return this.loyaltyService.setRule(setLoyaltyRuleDto, req.user);
  }

  // Endpoint untuk mendapatkan aturan poin saat ini
  @Get('rules')
  getRule(@Request() req) {
    return this.loyaltyService.getRule(req.user);
  }

  // Endpoint untuk menambah hadiah baru
  @Post('rewards')
  createReward(@Body() createRewardDto: CreateRewardDto, @Request() req) {
    return this.loyaltyService.createReward(createRewardDto, req.user);
  }

  // Endpoint untuk mendapatkan semua hadiah
  @Get('rewards')
  findAllRewards(@Request() req) {
    return this.loyaltyService.findAllRewards(req.user);
  }

  // Endpoint untuk mengupdate hadiah
  @Patch('rewards/:id')
  updateReward(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateRewardDto: UpdateRewardDto,
    @Request() req,
  ) {
    return this.loyaltyService.updateReward(id, updateRewardDto, req.user);
  }

  // Endpoint untuk menukarkan poin dengan hadiah
  @Post('redeem')
  redeemReward(@Body() redeemRewardDto: RedeemRewardDto, @Request() req) {
    return this.loyaltyService.redeemReward(redeemRewardDto, req.user);
  }
}