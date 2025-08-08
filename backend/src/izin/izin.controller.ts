import { Controller, Get, Post, Put, Delete, Body, Request, Query, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { IzinService } from './izin.service';
import { CreateIzinTimDto, UpdateStatusIzinDto, GetIzinTimDto } from './dto/izin.dto';

@Controller('izin')
@UseGuards(AuthGuard('jwt'))
export class IzinController {
  constructor(private readonly izinService: IzinService) {}

  @Post()
  async createIzinTim(@Request() req, @Body() createIzinDto: CreateIzinTimDto) {
    return this.izinService.createIzinTim(req.user, createIzinDto);
  }

  @Get()
  async getIzinTim(@Request() req, @Query() query: GetIzinTimDto) {
    return this.izinService.getIzinTim(req.user, query);
  }

  @Get('pending')
  async getIzinPending(@Request() req) {
    return this.izinService.getIzinPending(req.user);
  }

  @Get('statistik')
  async getStatistikIzin(@Request() req, @Query('tahun') tahun?: string, @Query('bulan') bulan?: string) {
    const tahunNum = tahun ? parseInt(tahun) : undefined;
    const bulanNum = bulan ? parseInt(bulan) : undefined;
    return this.izinService.getStatistikIzin(req.user, tahunNum, bulanNum);
  }

  @Put(':id/status')
  async updateStatusIzin(@Request() req, @Param('id') id: string, @Body() updateDto: UpdateStatusIzinDto) {
    return this.izinService.updateStatusIzin(req.user, parseInt(id), updateDto);
  }

  @Delete(':id')
  async deleteIzinTim(@Request() req, @Param('id') id: string) {
    return this.izinService.deleteIzinTim(req.user, parseInt(id));
  }
}
