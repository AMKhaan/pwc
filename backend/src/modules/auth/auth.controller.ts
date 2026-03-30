import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register a new user' })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email + password' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('admin/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin login' })
  adminLogin(@Body() dto: LoginDto) {
    return this.authService.adminLogin(dto).then((data) => ({ data }));
  }

  @Post('verify-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify primary email with OTP' })
  verifyEmail(@Body() dto: VerifyEmailDto) {
    return this.authService.verifyEmail(dto);
  }

  @Post('resend-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resend email verification OTP' })
  resendOtp(@Body('email') email: string) {
    return this.authService.resendOtp(email);
  }

  // ─── Company Email Verification ──────────────────────────────────────────────

  @Post('verify-company-email/send')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Send OTP to company email for verification' })
  sendCompanyOtp(
    @CurrentUser() user: User,
    @Body('companyEmail') companyEmail: string,
  ) {
    return this.authService.sendCompanyEmailOtp(user.id, companyEmail);
  }

  @Post('verify-company-email/confirm')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Confirm company email OTP' })
  verifyCompanyEmail(@CurrentUser() user: User, @Body() dto: VerifyEmailDto) {
    return this.authService.verifyCompanyEmail(user.id, dto);
  }

  // ─── University Email Verification ───────────────────────────────────────────

  @Post('verify-university-email/send')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Send OTP to university email for verification' })
  sendUniversityOtp(
    @CurrentUser() user: User,
    @Body('universityEmail') universityEmail: string,
  ) {
    return this.authService.sendUniversityEmailOtp(user.id, universityEmail);
  }

  @Post('verify-university-email/confirm')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Confirm university email OTP' })
  verifyUniversityEmail(@CurrentUser() user: User, @Body() dto: VerifyEmailDto) {
    return this.authService.verifyUniversityEmail(user.id, dto);
  }

  // ─── LinkedIn OAuth ───────────────────────────────────────────────────────────

  @Get('linkedin')
  @UseGuards(AuthGuard('linkedin'))
  @ApiOperation({ summary: 'Initiate LinkedIn OAuth login' })
  linkedinLogin() {
    // Passport redirects to LinkedIn
  }

  @Get('linkedin/callback')
  @UseGuards(AuthGuard('linkedin'))
  @ApiOperation({ summary: 'LinkedIn OAuth callback' })
  linkedinCallback(@Req() req: any) {
    return this.authService.handleLinkedInCallback(req.user);
  }

  // ─── Me ──────────────────────────────────────────────────────────────────────

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current authenticated user' })
  me(@CurrentUser() user: User) {
    return user;
  }
}
