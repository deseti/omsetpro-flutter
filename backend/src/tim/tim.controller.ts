import { Controller, Post, Body, UseGuards, Request, Get, Delete } from '@nestjs/common';
import { TimService } from './tim.service';
import { UndangUserDto } from './dto/undang-user.dto';
import { TugaskanAksesDto } from './dto/tugaskan-akses.dto';
import { AuthGuard } from '@nestjs/passport';

@UseGuards(AuthGuard('jwt'))
@Controller('tim')
export class TimController {
  constructor(private readonly timService: TimService) {}

  // Endpoint baru untuk melihat daftar tim
  @Get()
  findAll(@Request() req) {
    return this.timService.findAll(req.user);
  }

  @Post('undang')
  undangUser(@Body() undangUserDto: UndangUserDto, @Request() req) {
    return this.timService.undangUser(undangUserDto, req.user);
  }

  @Post('tugaskan-akses')
  tugaskanAkses(@Body() tugaskanAksesDto: TugaskanAksesDto, @Request() req) {
    return this.timService.tugaskanAkses(tugaskanAksesDto, req.user);
  }

  // Endpoint baru untuk menghapus akses
  @Delete('hapus-akses')
  hapusAkses(@Body() tugaskanAksesDto: TugaskanAksesDto, @Request() req) {
    return this.timService.hapusAkses(tugaskanAksesDto, req.user);
  }
}