import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmailService } from './email.service';
import { PushService } from './push.service';
import { UserNotificationsService } from './user-notifications.service';
import { UserNotificationsController } from './user-notifications.controller';
import { Notification } from '../../database/entities/notification.entity';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([Notification])],
  controllers: [UserNotificationsController],
  providers: [EmailService, PushService, UserNotificationsService],
  exports: [EmailService, PushService, UserNotificationsService],
})
export class NotificationsModule {}
