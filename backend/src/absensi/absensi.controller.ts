import { Controller, Get, Post, Put, Body, Request, Query, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AbsensiService } from './absensi.service';
import { CheckInDto, CheckOutDto, UpdateAbsensiDto, GetAbsensiDto } from './dto/absensi.dto';

@Controller('absensi')
@UseGuards(AuthGuard('jwt'))
export class AbsensiController {
  constructor(private readonly absensiService: AbsensiService) {}

  @Post('check-in')
  async checkIn(@Request() req, @Body() checkInDto: CheckInDto) {
    return this.absensiService.checkIn(req.user, checkInDto);
  }

  @Post('check-out')
  async checkOut(@Request() req, @Body() checkOutDto: CheckOutDto) {
    return this.absensiService.checkOut(req.user, checkOutDto);
  }

  @Get('riwayat')
  async getRiwayatAbsensi(@Request() req, @Query() query: GetAbsensiDto) {
    return this.absensiService.getRiwayatAbsensi(req.user, query);
  }

  @Get('hari-ini/:cabangId')
  async getAbsensiHariIni(@Request() req, @Param('cabangId') cabangId: string) {
    return this.absensiService.getAbsensiHariIni(req.user, parseInt(cabangId));
  }

  @Put(':id')
  async updateStatusAbsensi(
    @Request() req, 
    @Param('id') id: string, 
    @Body() updateDto: UpdateAbsensiDto
  ) {
    return this.absensiService.updateStatusAbsensi(req.user, parseInt(id), updateDto);
  }
}
