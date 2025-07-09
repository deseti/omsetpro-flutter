import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
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
}
