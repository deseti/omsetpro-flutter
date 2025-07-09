import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
  ParseIntPipe,
} from '@nestjs/common';
import { CabangService } from './cabang.service';
import { CreateCabangDto } from './dto/create-cabang.dto';
import { UpdateCabangDto } from './dto/update-cabang.dto';
import { AuthGuard } from '@nestjs/passport';

@UseGuards(AuthGuard('jwt'))
@Controller('cabang')
export class CabangController {
  constructor(private readonly cabangService: CabangService) {}

  @Post()
  create(@Body() createCabangDto: CreateCabangDto, @Request() req) {
    return this.cabangService.create(createCabangDto, req.user);
  }

  @Get()
  findAll(@Request() req) {
    return this.cabangService.findAll(req.user);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @Request() req) {
    return this.cabangService.findOne(id, req.user);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateCabangDto: UpdateCabangDto,
    @Request() req,
  ) {
    return this.cabangService.update(id, updateCabangDto, req.user);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @Request() req) {
    return this.cabangService.remove(id, req.user);
  }
}