import { Controller, Get, Post, Body, UseGuards, Request, Query } from '@nestjs/common';
import { PelangganService } from './pelanggan.service';
import { CreatePelangganDto } from './dto/create-pelanggan.dto';
import { AuthGuard } from '@nestjs/passport';

@UseGuards(AuthGuard('jwt'))
@Controller('pelanggan')
export class PelangganController {
  constructor(private readonly pelangganService: PelangganService) {}

  @Post()
  create(@Body() createPelangganDto: CreatePelangganDto, @Request() req) {
    // req.user diambil dari token JWT yang sudah divalidasi
    return this.pelangganService.create(createPelangganDto, req.user);
  }


  @Get()
  findAll(@Request() req) {
    return this.pelangganService.findAll(req.user);
  }

  // [BARU] Endpoint untuk pencarian pelanggan
  @Get('search')
  search(@Query('q') query: string, @Request() req) {
    return this.pelangganService.search(query || '', req.user);
  }
}