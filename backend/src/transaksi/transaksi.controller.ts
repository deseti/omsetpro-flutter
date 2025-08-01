import { Controller, Post, Body, UseGuards, Request, Get, Query } from '@nestjs/common';
import { TransaksiService } from './transaksi.service';
import { CreateTransaksiDto } from './dto/create-transaksi.dto';
import { AuthGuard } from '@nestjs/passport';

@UseGuards(AuthGuard('jwt'))
@Controller('transaksi')
export class TransaksiController {
  constructor(private readonly transaksiService: TransaksiService) {}

  @Post()
  create(@Body() createTransaksiDto: CreateTransaksiDto, @Request() req) {
    const kasirId = req.user.id; // ID kasir diambil dari token JWT
    return this.transaksiService.create(createTransaksiDto, kasirId);
  }

  @Get('riwayat')
  getRiwayatTransaksi(
    @Query('cabangId') cabangId?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Request() req?
  ) {
    const userId = req.user.id;
    return this.transaksiService.getRiwayatTransaksi({
      cabangId: cabangId ? parseInt(cabangId) : undefined,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      limit: limit ? parseInt(limit) : 20,
      offset: offset ? parseInt(offset) : 0,
      userId
    });
  }
}
