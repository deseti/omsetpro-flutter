import { Controller, Get, Post, Put, Delete, Body, Request, Query, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { NotifikasiService } from './notifikasi.service';
import { GetNotifikasiDto, MarkAsReadDto } from './dto/notifikasi.dto';

@Controller('notifikasi')
@UseGuards(AuthGuard('jwt'))
export class NotifikasiController {
  constructor(private readonly notifikasiService: NotifikasiService) {}

  @Get()
  async getNotifikasi(@Request() req, @Query() query: GetNotifikasiDto) {
    return this.notifikasiService.getNotifikasi(req.user, query);
  }

  @Put('mark-as-read')
  async markAsRead(@Request() req, @Body() markAsReadDto: MarkAsReadDto) {
    return this.notifikasiService.markAsRead(req.user, markAsReadDto);
  }

  @Put('mark-all-as-read')
  async markAllAsRead(@Request() req) {
    return this.notifikasiService.markAllAsRead(req.user);
  }

  @Delete(':id')
  async deleteNotifikasi(@Request() req, @Param('id') id: string) {
    return this.notifikasiService.deleteNotifikasi(req.user, parseInt(id));
  }
}
