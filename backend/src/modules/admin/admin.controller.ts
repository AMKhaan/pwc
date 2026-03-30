import {
  Controller,
  Get,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';

function requireAdmin(user: User) {
  if (!user.isAdmin) throw new ForbiddenException('Admin access required');
}

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  async getStats(@CurrentUser() user: User) {
    requireAdmin(user);
    const data = await this.adminService.getDashboardStats();
    return { data };
  }

  @Get('users')
  async getUsers(
    @CurrentUser() user: User,
    @Query('page') page = '1',
    @Query('limit') limit = '15',
    @Query('search') search?: string,
    @Query('verificationStatus') verificationStatus?: string,
    @Query('userType') userType?: string,
  ) {
    requireAdmin(user);
    const data = await this.adminService.getUsers({
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      search,
      verificationStatus,
      userType,
    });
    return { data };
  }

  @Patch('users/:id/suspend')
  async suspend(@CurrentUser() user: User, @Param('id') id: string) {
    requireAdmin(user);
    await this.adminService.suspendUser(id);
    return { message: 'User suspended' };
  }

  @Patch('users/:id/unsuspend')
  async unsuspend(@CurrentUser() user: User, @Param('id') id: string) {
    requireAdmin(user);
    await this.adminService.unsuspendUser(id);
    return { message: 'User unsuspended' };
  }

  @Get('rides')
  async getRides(
    @CurrentUser() user: User,
    @Query('page') page = '1',
    @Query('limit') limit = '15',
    @Query('search') search?: string,
    @Query('type') type?: string,
    @Query('status') status?: string,
  ) {
    requireAdmin(user);
    const data = await this.adminService.getRides({
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      search,
      type,
      status,
    });
    return { data };
  }

  @Get('payments')
  async getPayments(
    @CurrentUser() user: User,
    @Query('page') page = '1',
    @Query('limit') limit = '15',
    @Query('status') status?: string,
  ) {
    requireAdmin(user);
    const data = await this.adminService.getPayments({
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      status,
    });
    return { data };
  }

  @Get('verification-queue')
  async getVerificationQueue(
    @CurrentUser() user: User,
    @Query('page') page = '1',
    @Query('limit') limit = '15',
    @Query('type') type?: string,
  ) {
    requireAdmin(user);
    const data = await this.adminService.getVerificationQueue({
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      type,
    });
    return { data };
  }

  @Get('verification/:id')
  async getVerificationUser(@CurrentUser() user: User, @Param('id') id: string) {
    requireAdmin(user);
    const data = await this.adminService.getVerificationUser(id);
    return { data };
  }

  @Patch('verification/:id/approve')
  async approve(@CurrentUser() user: User, @Param('id') id: string) {
    requireAdmin(user);
    await this.adminService.approveVerification(id);
    return { message: 'Verification approved' };
  }

  @Patch('verification/:id/reject')
  async reject(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body('reason') reason: string,
  ) {
    requireAdmin(user);
    await this.adminService.rejectVerification(id, reason || 'Verification rejected by admin');
    return { message: 'Verification rejected' };
  }
}
