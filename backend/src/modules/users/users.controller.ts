import {
  Controller, Get, Patch, Post, Delete,
  Body, Param, UseGuards, Query, BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';
import { StorageService } from '../storage/storage.service';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(
    private usersService: UsersService,
    private storageService: StorageService,
  ) {}

  // ─── Profile ────────────────────────────────────────────────────────────────

  @Get('me')
  @ApiOperation({ summary: 'Get my full profile' })
  getMyProfile(@CurrentUser() user: User) {
    return this.usersService.getProfile(user.id);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update my profile' })
  updateProfile(@CurrentUser() user: User, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Post('me/avatar-upload-url')
  @ApiOperation({ summary: 'Get pre-signed URL to upload avatar directly to R2' })
  async getAvatarUploadUrl(
    @CurrentUser() user: User,
    @Body('fileName') fileName: string,
    @Body('mimeType') mimeType: string,
  ) {
    const result = await this.storageService.getPresignedUploadUrl('avatars', fileName, mimeType);
    return { data: result };
  }

  @Post('me/vehicle-document-upload-url')
  @ApiOperation({ summary: 'Get pre-signed URL to upload vehicle document to R2' })
  async getVehicleDocumentUploadUrl(
    @CurrentUser() user: User,
    @Body('fileName') fileName: string,
    @Body('mimeType') mimeType: string,
  ) {
    const result = await this.storageService.getPresignedUploadUrl('documents', fileName, mimeType);
    return { data: result };
  }

  @Post('me/id-document-upload-url')
  @ApiOperation({ summary: 'Get pre-signed URL to upload CNIC or student ID card photo' })
  async getIdDocumentUploadUrl(
    @CurrentUser() user: User,
    @Body('fileName') fileName: string,
    @Body('mimeType') mimeType: string,
  ) {
    const result = await this.storageService.getPresignedUploadUrl('documents', fileName, mimeType);
    return { data: result };
  }

  @Post('me/send-phone-otp')
  @ApiOperation({ summary: 'Send OTP to phone number for verification' })
  async sendPhoneOtp(
    @CurrentUser() user: User,
    @Body('phoneNumber') phoneNumber: string,
  ) {
    if (!phoneNumber) throw new BadRequestException('phoneNumber is required');
    await this.usersService.sendPhoneOtp(user.id, phoneNumber);
    return { message: 'OTP sent' };
  }

  @Post('me/verify-phone-otp')
  @ApiOperation({ summary: 'Verify phone OTP and mark phone as verified' })
  async verifyPhoneOtp(
    @CurrentUser() user: User,
    @Body('phoneNumber') phoneNumber: string,
    @Body('otp') otp: string,
  ) {
    return this.usersService.verifyPhoneOtp(user.id, phoneNumber, otp);
  }

  @Post('me/submit-verification')
  @ApiOperation({ summary: 'Submit profile for admin verification review' })
  async submitVerification(@CurrentUser() user: User) {
    return this.usersService.submitVerification(user.id);
  }

  @Patch('me/avatar')
  @ApiOperation({ summary: 'Save avatar URL after successful upload' })
  async saveAvatarUrl(@CurrentUser() user: User, @Body('avatarUrl') avatarUrl: string) {
    await this.usersService.updateProfile(user.id, { avatarUrl } as any);
    return { message: 'Avatar updated' };
  }

  @Patch('me/fcm-token')
  @ApiOperation({ summary: 'Update FCM push token' })
  async updateFcmToken(@CurrentUser() user: User, @Body('fcmToken') fcmToken: string) {
    await this.usersService.updateFcmToken(user.id, fcmToken);
    return { message: 'FCM token updated' };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get public profile of any user' })
  getPublicProfile(@Param('id') id: string) {
    return this.usersService.getPublicProfile(id);
  }

  // ─── Vehicles ───────────────────────────────────────────────────────────────

  @Get('me/vehicles')
  @ApiOperation({ summary: 'Get my vehicles' })
  getMyVehicles(@CurrentUser() user: User) {
    return this.usersService.getMyVehicles(user.id);
  }

  @Post('me/vehicles')
  @ApiOperation({ summary: 'Add a vehicle' })
  addVehicle(@CurrentUser() user: User, @Body() dto: CreateVehicleDto) {
    return this.usersService.addVehicle(user.id, dto);
  }

  @Patch('me/vehicles/:vehicleId')
  @ApiOperation({ summary: 'Update a vehicle' })
  updateVehicle(
    @CurrentUser() user: User,
    @Param('vehicleId') vehicleId: string,
    @Body() dto: Partial<CreateVehicleDto>,
  ) {
    return this.usersService.updateVehicle(user.id, vehicleId, dto);
  }

  @Delete('me/vehicles/:vehicleId')
  @ApiOperation({ summary: 'Remove a vehicle' })
  deleteVehicle(
    @CurrentUser() user: User,
    @Param('vehicleId') vehicleId: string,
  ) {
    return this.usersService.deleteVehicle(user.id, vehicleId);
  }
}
