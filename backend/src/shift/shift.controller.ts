import { Controller, Get, Post, Put, Delete, Body, Request, Query, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ShiftService } from './shift.service';
import { CreateShiftDto, UpdateShiftDto, CreateJadwalTimDto, GetJadwalDto } from './dto/shift.dto';

@Controller('shift')
@UseGuards(AuthGuard('jwt'))
export class ShiftController {
  constructor(private readonly shiftService: ShiftService) {}

  // CRUD Shift
  @Post()
  async createShift(@Request() req, @Body() createShiftDto: CreateShiftDto) {
    return this.shiftService.createShift(req.user, createShiftDto);
  }

  @Get()
  async getShifts(@Request() req, @Query('cabangId') cabangId?: string) {
    const cabangIdNum = cabangId ? parseInt(cabangId) : undefined;
    return this.shiftService.getShifts(req.user, cabangIdNum);
  }

  @Put(':id')
  async updateShift(@Request() req, @Param('id') id: string, @Body() updateShiftDto: UpdateShiftDto) {
    return this.shiftService.updateShift(req.user, parseInt(id), updateShiftDto);
  }

  @Delete(':id')
  async deleteShift(@Request() req, @Param('id') id: string) {
    return this.shiftService.deleteShift(req.user, parseInt(id));
  }

  // CRUD Jadwal Tim
  @Post('jadwal')
  async createJadwalTim(@Request() req, @Body() createJadwalDto: CreateJadwalTimDto) {
    return this.shiftService.createJadwalTim(req.user, createJadwalDto);
  }

  @Get('jadwal')
  async getJadwalTim(@Request() req, @Query() query: GetJadwalDto) {
    return this.shiftService.getJadwalTim(req.user, query);
  }

  @Get('jadwal/hari-ini')
  async getJadwalHariIni(@Request() req) {
    return this.shiftService.getJadwalHariIni(req.user);
  }

  @Delete('jadwal/:id')
  async deleteJadwalTim(@Request() req, @Param('id') id: string) {
    return this.shiftService.deleteJadwalTim(req.user, parseInt(id));
  }
}
