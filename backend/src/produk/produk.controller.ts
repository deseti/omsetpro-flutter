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
  Query,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ProdukService } from './produk.service';
import { CreateProdukDto } from './dto/create-produk.dto';
import { UpdateProdukDto } from './dto/update-produk.dto';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import * as xlsx from 'xlsx'; // Import xlsx

@UseGuards(AuthGuard('jwt'))
@Controller('produk')
export class ProdukController {
  constructor(private readonly produkService: ProdukService) {}

  // --- ENDPOINT BARU UNTUK UPLOAD MASSAL ---
  @Post('upload-massal')
  @UseInterceptors(FileInterceptor('file'))
  uploadMassal(
    @UploadedFile() file: Express.Multer.File,
    @Body('cabangId', ParseIntPipe) cabangId: number, // Ambil cabangId dari body form-data
    @Request() req,
  ) {
    const userId = req.user.id;
    // Baca file buffer dari Excel
    const workbook = xlsx.read(file.buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0]; // Ambil sheet pertama
    const sheet = workbook.Sheets[sheetName];
    const data = xlsx.utils.sheet_to_json(sheet); // Ubah sheet menjadi JSON

    return this.produkService.createMany(data, cabangId, userId);
  }

  // Endpoint untuk upload foto (tidak berubah)
  @Post(':id/upload-foto')
  @UseInterceptors(FileInterceptor('file'))
  uploadFoto(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
    @Request() req,
  ) {
    const userId = req.user.id;
    return this.produkService.uploadFoto(id, file, userId);
  }

  // Endpoint untuk membuat satu produk (tidak berubah)
  @Post()
  create(@Body() createProdukDto: CreateProdukDto, @Request() req) {
    const userId = req.user.id;
    return this.produkService.create(createProdukDto, userId);
  }

  // Endpoint untuk mengambil semua produk per cabang (tidak berubah)
  @Get()
  findAllByCabang(@Query('cabangId', ParseIntPipe) cabangId: number, @Request() req) {
    const userId = req.user.id;
    return this.produkService.findAllByCabang(cabangId, userId);
  }

  // Endpoint untuk mengupdate satu produk (tidak berubah)
  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateProdukDto: UpdateProdukDto,
    @Request() req,
  ) {
    const userId = req.user.id;
    return this.produkService.update(id, updateProdukDto, userId);
  }

  // Endpoint untuk menghapus satu produk (tidak berubah)
  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @Request() req) {
    const userId = req.user.id;
    return this.produkService.remove(id, userId);
  }
}
