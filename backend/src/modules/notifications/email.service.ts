import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private resend: Resend | null = null;
  private fromEmail: string;

  constructor(private config: ConfigService) {
    const apiKey = this.config.get<string>('resend.apiKey');
    this.fromEmail = this.config.get<string>('resend.fromEmail') ?? 'noreply@ridesync.pk';

    if (apiKey) {
      this.resend = new Resend(apiKey);
    } else {
      this.logger.warn('RESEND_API_KEY not set — emails will be logged to console only');
    }
  }

  async sendOtp(to: string, otp: string, type: 'primary' | 'company' | 'university') {
    const subject = {
      primary: 'Verify your RideSync account',
      company: 'Verify your company email — RideSync',
      university: 'Verify your university email — RideSync',
    }[type];

    const label = {
      primary: 'account',
      company: 'company email',
      university: 'university email',
    }[type];

    const html = this.otpTemplate(otp, label);

    if (!this.resend) {
      this.logger.log(`[EMAIL OTP] To: ${to} | Subject: ${subject} | OTP: ${otp}`);
      return;
    }

    try {
      await this.resend.emails.send({ from: this.fromEmail, to, subject, html });
    } catch (err) {
      this.logger.error(`Failed to send OTP email to ${to}`, err);
      // Don't throw — OTP is still saved in DB, user can request resend
    }
  }

  async sendBookingConfirmation(to: string, params: {
    riderName: string;
    driverName: string;
    origin: string;
    destination: string;
    departureTime: Date;
    pricePerSeat: number;
  }) {
    const subject = 'Booking confirmed — RideSync';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #2563EB;">Booking Confirmed!</h2>
        <p>Hi ${params.riderName},</p>
        <p>Your booking with <strong>${params.driverName}</strong> is confirmed.</p>
        <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
          <tr><td style="padding: 8px; color: #6B7280;">From</td><td style="padding: 8px; font-weight: 500;">${params.origin}</td></tr>
          <tr><td style="padding: 8px; color: #6B7280;">To</td><td style="padding: 8px; font-weight: 500;">${params.destination}</td></tr>
          <tr><td style="padding: 8px; color: #6B7280;">Departure</td><td style="padding: 8px; font-weight: 500;">${params.departureTime.toLocaleString('en-PK', { timeZone: 'Asia/Karachi' })}</td></tr>
          <tr><td style="padding: 8px; color: #6B7280;">Amount</td><td style="padding: 8px; font-weight: 500; color: #2563EB;">PKR ${params.pricePerSeat.toLocaleString()}</td></tr>
        </table>
        <p style="color: #6B7280; font-size: 13px;">RideSync — Professional carpooling in Lahore</p>
      </div>
    `;

    if (!this.resend) {
      this.logger.log(`[EMAIL] Booking confirmation to ${to}`);
      return;
    }

    try {
      await this.resend.emails.send({ from: this.fromEmail, to, subject, html });
    } catch (err) {
      this.logger.error(`Failed to send booking confirmation to ${to}`, err);
    }
  }

  private otpTemplate(otp: string, label: string): string {
    return `
      <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto;">
        <div style="background: #2563EB; padding: 24px; border-radius: 8px 8px 0 0; text-align: center;">
          <h2 style="color: #fff; margin: 0;">RideSync</h2>
        </div>
        <div style="background: #fff; padding: 24px; border: 1px solid #E5E7EB; border-top: none; border-radius: 0 0 8px 8px;">
          <p style="color: #374151;">Use this code to verify your ${label}:</p>
          <div style="background: #F3F4F6; border-radius: 8px; padding: 20px; text-align: center; margin: 16px 0;">
            <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #111827;">${otp}</span>
          </div>
          <p style="color: #6B7280; font-size: 13px;">This code expires in 15 minutes. Do not share it with anyone.</p>
        </div>
      </div>
    `;
  }
}
