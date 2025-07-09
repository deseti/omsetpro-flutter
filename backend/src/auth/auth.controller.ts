import { Controller, Post, Body, HttpCode, HttpStatus, Get, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterUserDto, LoginUserDto } from './auth.dto';
import { AuthGuard } from '@nestjs/passport'; // Import AuthGuard

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() registerUserDto: RegisterUserDto) {
    return this.authService.create(registerUserDto);
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  login(@Body() loginUserDto: LoginUserDto) {
    return this.authService.login(loginUserDto);
  }

  // --- TAMBAHKAN ENDPOINT BARU YANG TERPROTEKSI INI ---
  @UseGuards(AuthGuard('jwt')) // Terapkan "penjaga" di sini
  @Get('profile')
  getProfile(@Request() req) {
    // `req.user` akan berisi data user yang sudah divalidasi oleh JwtStrategy
    return {
      message: 'Berhasil mengambil data profile',
      user: req.user,
    };
  }
}
