import { Controller, Get, Post, Put, Delete, Body, Request, Query, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { GajiService } from './gaji.service';
import { CreateGajiTimDto, UpdateGajiTimDto, GetLaporanGajiDto } from './dto/gaji.dto';

@Controller('gaji')
@UseGuards(AuthGuard('jwt'))
export class GajiController {
  constructor(private readonly gajiService: GajiService) {}

  @Post()
  async createGajiTim(@Request() req, @Body() createGajiDto: CreateGajiTimDto) {
    return this.gajiService.createGajiTim(req.user, createGajiDto);
  }

  @Get('tim')
  async getGajiTim(@Request() req) {
    return this.gajiService.getGajiTim(req.user);
  }

  @Get('my')
  async getMyGaji(@Request() req) {
    return this.gajiService.getMyGaji(req.user);
  }

  @Get('laporan')
  async getLaporanGaji(@Request() req, @Query() query: GetLaporanGajiDto) {
    return this.gajiService.getLaporanGaji(req.user, query);
  }

  @Put(':userId')
  async updateGajiTim(@Request() req, @Param('userId') userId: string, @Body() updateGajiDto: UpdateGajiTimDto) {
    return this.gajiService.updateGajiTim(req.user, parseInt(userId), updateGajiDto);
  }

  @Delete(':userId')
  async deleteGajiTim(@Request() req, @Param('userId') userId: string) {
    return this.gajiService.deleteGajiTim(req.user, parseInt(userId));
  }
}
