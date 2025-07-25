import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import { PengaturanService } from './pengaturan.service';
import { Role } from '@prisma/client';

@Controller('pengaturan')
@UseGuards(AuthGuard('jwt'))
export class PengaturanController {
  constructor(private readonly pengaturanService: PengaturanService) {}

  @Get('akun-toko')
  async getAkunToko(@Request() req) {
    return this.pengaturanService.getAkunToko(req.user.id);
  }

  @Post('akun-toko')
  @UseInterceptors(
    FileInterceptor('logo', {
      fileFilter: (req, file, callback) => {
        if (!file.originalname.match(/\.(jpg|jpeg|png)$/)) {
          return callback(
            new BadRequestException('Hanya file JPG, JPEG, dan PNG yang diizinkan'),
            false,
          );
        }
        callback(null, true);
      },
      limits: {
        fileSize: 2 * 1024 * 1024, // 2MB
      },
    }),
  )
  async updateAkunToko(
    @Request() req,
    @Body() updateData: any,
    @UploadedFile() logo?: Express.Multer.File,
  ) {
    return this.pengaturanService.updateAkunToko(req.user.id, updateData, logo);
  }
}
