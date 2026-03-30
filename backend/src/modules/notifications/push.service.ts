import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class PushService implements OnModuleInit {
  private readonly logger = new Logger(PushService.name);
  private initialized = false;

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const projectId = this.config.get<string>('firebase.projectId');
    const privateKey = this.config.get<string>('firebase.privateKey');
    const clientEmail = this.config.get<string>('firebase.clientEmail');

    if (!projectId || !privateKey || !clientEmail ||
        projectId === 'placeholder' || privateKey === 'placeholder') {
      this.logger.warn('Firebase credentials not set — push notifications disabled');
      return;
    }

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          privateKey: privateKey.replace(/\\n/g, '\n'),
          clientEmail,
        }),
      });
    }

    this.initialized = true;
  }

  async sendToDevice(fcmToken: string, payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }) {
    if (!this.initialized || !fcmToken) return;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title: payload.title, body: payload.body },
        data: payload.data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (err) {
      this.logger.warn(`Push failed for token ${fcmToken.slice(0, 20)}…: ${err}`);
    }
  }

  async sendToMultiple(fcmTokens: string[], payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }) {
    if (!this.initialized || fcmTokens.length === 0) return;

    const messages: admin.messaging.Message[] = fcmTokens.map((token) => ({
      token,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
      android: { priority: 'high' as const },
      apns: { payload: { aps: { sound: 'default' } } },
    }));

    try {
      const response = await admin.messaging().sendEach(messages);
      if (response.failureCount > 0) {
        this.logger.warn(`${response.failureCount}/${messages.length} push notifications failed`);
      }
    } catch (err) {
      this.logger.error('Batch push failed', err);
    }
  }
}
