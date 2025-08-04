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
  Response,
  ParseIntPipe,
  Query,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
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

  // --- ENDPOINT BARU UNTUK EXPORT DATA PRODUK ---
  @Get('export/:cabangId')
  async exportProduk(
    @Param('cabangId', ParseIntPipe) cabangId: number,
    @Request() req,
    @Response() res,
  ) {
    const userId = req.user.id;
    
    console.log('📥 Export produk called for cabangId:', cabangId, 'userId:', userId);
    
    try {
      const buffer = await this.produkService.exportToExcel(cabangId, userId);
      
      res.set({
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="data_produk_cabang_${cabangId}_${new Date().toISOString().split('T')[0]}.xlsx"`,
        'Content-Length': buffer.length,
      });
      
      res.end(buffer);
    } catch (error) {
      console.error('❌ Error in export produk:', error);
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Gagal mengexport data produk: ${error.message}`);
    }
  }

  // --- ENDPOINT BARU UNTUK UPLOAD MASSAL ---
  @Post('upload-massal')
  @UseInterceptors(FileInterceptor('file'))
  async uploadMassal(
    @UploadedFile() file: Express.Multer.File,
    @Body('cabangId') cabangIdRaw: string, // Ambil sebagai string dulu untuk validation manual
    @Request() req,
  ) {
    const userId = req.user.id;
    
    console.log('🔍 Upload massal called with:');
    console.log('- File:', file?.originalname, file?.size, 'bytes');
    console.log('- CabangId raw:', cabangIdRaw);
    console.log('- UserId:', userId);
    
    if (!file) {
      throw new BadRequestException('File Excel harus di-upload');
    }
    
    // Validasi cabangId secara manual
    const cabangId = parseInt(cabangIdRaw);
    if (isNaN(cabangId)) {
      throw new BadRequestException('cabangId harus berupa angka yang valid');
    }
    
    try {
      console.log('📁 Processing Excel file...');
      
      // Baca file buffer dari Excel menggunakan ExcelJS
      const workbook = new ExcelJS.Workbook();
      await workbook.xlsx.load(file.buffer);
      console.log('✅ Excel file loaded successfully');
      
      // Ambil worksheet pertama
      const worksheet = workbook.worksheets[0];
      
      if (!worksheet) {
        console.error('❌ No worksheet found');
        throw new Error('Worksheet tidak ditemukan');
      }
      console.log(`📊 Worksheet found with ${worksheet.rowCount} rows`);

      // Konversi worksheet menjadi array of objects
      const data: any[] = [];
      const headers: string[] = [];
      
      // Ambil headers dari baris pertama
      worksheet.getRow(1).eachCell((cell, colNumber) => {
        headers[colNumber - 1] = cell.value?.toString() || '';
      });
      console.log('📋 Headers found:', headers);
      
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

      console.log(`📦 Processed ${data.length} data rows:`, data);
      
      return this.produkService.createMany(data, cabangId, userId);
    } catch (error) {
      console.error('❌ Error in upload massal:', error);
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Gagal memproses file Excel: ${error.message}`);
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
  async findAllByCabang(@Query('cabangId') cabangIdRaw: string, @Request() req) {
    const userId = req.user.id;
    console.log('🔍 GET /produk called with raw cabangId:', cabangIdRaw, 'userId:', userId);
    
    try {
      // Validasi manual untuk cabangId
      const cabangId = parseInt(cabangIdRaw);
      if (isNaN(cabangId)) {
        console.error('❌ Invalid cabangId format:', cabangIdRaw);
        throw new BadRequestException('cabangId harus berupa angka yang valid');
      }
      
      const produkList = await this.produkService.findAllByCabang(cabangId, userId);
      console.log(`✅ Returning ${produkList.length} products`);
      return produkList;
    } catch (error) {
      console.error('❌ Error in findAllByCabang controller:', error);
      throw error;
    }
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
