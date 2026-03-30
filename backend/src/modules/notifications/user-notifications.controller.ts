import { Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';
import { UserNotificationsService } from './user-notifications.service';

@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class UserNotificationsController {
  constructor(private readonly service: UserNotificationsService) {}

  @Get('unread-count')
  async unreadCount(@CurrentUser() user: User) {
    const count = await this.service.getUnreadCount(user.id);
    return { count };
  }

  @Patch('mark-all-read')
  async markAllRead(@CurrentUser() user: User) {
    await this.service.markAllRead(user.id);
    return { message: 'All notifications marked as read' };
  }
}
