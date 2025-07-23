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
import * as ExcelJS from 'exceljs'; // Import ExcelJS

@UseGuards(AuthGuard('jwt'))
@Controller('produk')
export class ProdukController {
  constructor(private readonly produkService: ProdukService) {}

  // --- ENDPOINT BARU UNTUK UPLOAD MASSAL ---
  @Post('upload-massal')
  @UseInterceptors(FileInterceptor('file'))
  async uploadMassal(
    @UploadedFile() file: Express.Multer.File,
    @Body('cabangId', ParseIntPipe) cabangId: number, // Ambil cabangId dari body form-data
    @Request() req,
  ) {
    const userId = req.user.id;
    
    try {
      // Baca file buffer dari Excel menggunakan ExcelJS
      const workbook = new ExcelJS.Workbook();
      await workbook.xlsx.load(file.buffer);
      
      // Ambil worksheet pertama
      const worksheet = workbook.worksheets[0];
      
      if (!worksheet) {
        throw new Error('Worksheet tidak ditemukan');
      }

      // Konversi worksheet menjadi array of objects
      const data: any[] = [];
      const headers: string[] = [];
      
      // Ambil headers dari baris pertama
      worksheet.getRow(1).eachCell((cell, colNumber) => {
        headers[colNumber - 1] = cell.value?.toString() || '';
      });
      
      // Iterasi setiap baris mulai dari baris kedua
      worksheet.eachRow((row, rowNumber) => {
        if (rowNumber > 1) { // Skip header row
          const rowData: any = {};
          row.eachCell((cell, colNumber) => {
            const header = headers[colNumber - 1];
            if (header) {
              rowData[header] = cell.value;
            }
          });
          
          // Hanya tambahkan jika rowData tidak kosong
          if (Object.keys(rowData).length > 0) {
            data.push(rowData);
          }
        }
      });

      return this.produkService.createMany(data, cabangId, userId);
    } catch (error) {
      throw new Error(`Gagal memproses file Excel: ${error.message}`);
    }
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

  // ENDPOINT BARU: Mengambil semua produk dari semua cabang milik owner
  @Get('all-owner-products')
  findAllOwnerProducts(@Request() req) {
    const userId = req.user.id;
    return this.produkService.findAllOwnerProducts(userId);
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
