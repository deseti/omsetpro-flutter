import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, ParseIntPipe } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PromoService } from './promo.service';
import { CreatePromoDto } from './dto/promo.dto';
import { UpdatePromoDto } from './dto/promo.dto';

@UseGuards(AuthGuard('jwt'))
@Controller('promo')
export class PromoController {
  constructor(private readonly promoService: PromoService) {}

  @Post()
  create(@Body() createPromoDto: CreatePromoDto, @Request() req) {
    return this.promoService.create(createPromoDto, req.user);
  }

  @Get()
  findAll(@Request() req) {
    return this.promoService.findAll(req.user);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @Request() req) {
    return this.promoService.findOne(id, req.user);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updatePromoDto: UpdatePromoDto,
    @Request() req,
  ) {
    return this.promoService.update(id, updatePromoDto, req.user);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @Request() req) {
    return this.promoService.remove(id, req.user);
  }
}