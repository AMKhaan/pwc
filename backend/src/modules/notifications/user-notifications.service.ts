import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from '../../database/entities/notification.entity';

@Injectable()
export class UserNotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notifRepo: Repository<Notification>,
  ) {}

  async create(
    userId: string,
    title: string,
    body: string,
    type: NotificationType,
    data?: Record<string, any>,
  ): Promise<void> {
    const notif = this.notifRepo.create({ userId, title, body, type, data });
    await this.notifRepo.save(notif);
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notifRepo.count({ where: { userId, isRead: false } });
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notifRepo.update({ userId, isRead: false }, { isRead: true });
  }
}
