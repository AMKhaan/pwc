import {
  Injectable, NotFoundException, BadRequestException,
  ForbiddenException, Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { Payment, PaymentStatus, PaymentGateway } from '../../database/entities/payment.entity';
import { Booking, BookingStatus, PaymentType } from '../../database/entities/booking.entity';
import { JazzCashService } from './gateways/jazzcash.service';
import { EasypaisaService } from './gateways/easypaisa.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    @InjectRepository(Payment)
    private paymentRepo: Repository<Payment>,

    @InjectRepository(Booking)
    private bookingRepo: Repository<Booking>,

    private jazzCash: JazzCashService,
    private easypaisa: EasypaisaService,
    private config: ConfigService,
  ) {}

  // ─── Initiate Payment (Discussion Rides only) ─────────────────────────────────

  async initiatePayment(riderId: string, dto: InitiatePaymentDto): Promise<Payment> {
    const booking = await this.bookingRepo.findOne({
      where: { id: dto.bookingId, riderId },
      relations: ['ride'],
    });

    if (!booking) throw new NotFoundException('Booking not found');

    if (booking.paymentType !== PaymentType.ESCROW) {
      throw new BadRequestException(
        'Payment is only required for Discussion Rides. Regular rides are paid directly.',
      );
    }

    if (booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException('Booking is not in pending status');
    }

    // Check no existing payment
    const existing = await this.paymentRepo.findOne({
      where: { bookingId: dto.bookingId },
    });
    if (existing && existing.status !== PaymentStatus.FAILED) {
      throw new BadRequestException('Payment already initiated for this booking');
    }

    const commissionRate = this.config.get<number>('platform.commissionRate') || 0.12;
    const platformFee = parseFloat((booking.totalAmount * commissionRate).toFixed(2));
    const hostAmount = parseFloat((booking.totalAmount - platformFee).toFixed(2));

    // Unique transaction reference
    const txnRef = `RS-${Date.now()}-${dto.bookingId.slice(0, 8).toUpperCase()}`;

    // Call the appropriate gateway
    let gatewayResult;

    if (dto.method === PaymentGateway.JAZZCASH) {
      gatewayResult = await this.jazzCash.initiatePayment({
        mobileNumber: dto.mobileNumber,
        amount: booking.totalAmount,
        txnRefNo: txnRef,
        description: `RideSync Discussion Ride — ${booking.ride.discussionTopic || 'Booking'}`,
        billReference: dto.bookingId,
      });
    } else {
      gatewayResult = await this.easypaisa.initiatePayment({
        mobileNumber: dto.mobileNumber,
        amount: booking.totalAmount,
        orderRefNum: txnRef,
        description: `RideSync — ${booking.ride.discussionTopic || 'Booking'}`,
      });
    }

    // Save payment record
    const payment = this.paymentRepo.create({
      bookingId: dto.bookingId,
      amount: booking.totalAmount,
      platformFee,
      hostAmount,
      method: dto.method,
      transactionReference: gatewayResult.transactionReference,
      gatewayResponse: gatewayResult.raw,
      status: gatewayResult.success ? PaymentStatus.HELD : PaymentStatus.FAILED,
      heldAt: gatewayResult.success ? new Date() : undefined,
    });

    await this.paymentRepo.save(payment);

    // If payment successful, confirm the booking
    if (gatewayResult.success) {
      await this.bookingRepo.update(dto.bookingId, {
        status: BookingStatus.CONFIRMED,
        confirmedAt: new Date(),
        paymentMethod: dto.method as any,
      });
      this.logger.log(`Payment held for booking ${dto.bookingId} — PKR ${booking.totalAmount}`);
    } else {
      this.logger.warn(
        `Payment failed [${dto.bookingId}]: ${gatewayResult.responseCode} — ${gatewayResult.responseMessage}`,
      );
      throw new BadRequestException(
        `Payment failed: ${gatewayResult.responseMessage}. Please try again.`,
      );
    }

    return payment;
  }

  // ─── Get Payment by Booking ───────────────────────────────────────────────────

  async getPaymentByBooking(bookingId: string, userId: string): Promise<Payment> {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['ride'],
    });
    if (!booking) throw new NotFoundException('Booking not found');

    if (booking.riderId !== userId && booking.ride.driverId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (!payment) throw new NotFoundException('No payment found for this booking');

    return payment;
  }

  // ─── Manual Release (admin or post-ride trigger) ──────────────────────────────

  async releasePayment(bookingId: string): Promise<Payment> {
    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (!payment) throw new NotFoundException('Payment not found');

    if (payment.status !== PaymentStatus.HELD) {
      throw new BadRequestException(`Payment is not in HELD status (current: ${payment.status})`);
    }

    // TODO Phase 7: Actual disbursement to host via JazzCash/EasyPaisa
    // For now: mark released — disbursement tracked manually via admin dashboard
    await this.paymentRepo.update(payment.id, {
      status: PaymentStatus.RELEASED,
      releasedAt: new Date(),
    });

    this.logger.log(
      `Payment released for booking ${bookingId} — PKR ${payment.hostAmount} to host`,
    );

    return { ...payment, status: PaymentStatus.RELEASED };
  }

  // ─── Refund ───────────────────────────────────────────────────────────────────

  async refundPayment(bookingId: string): Promise<Payment> {
    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (!payment) throw new NotFoundException('Payment not found');

    if (payment.status !== PaymentStatus.HELD) {
      throw new BadRequestException('Only held payments can be refunded');
    }

    // TODO Phase 7: Call gateway refund API
    await this.paymentRepo.update(payment.id, {
      status: PaymentStatus.REFUNDED,
      refundedAt: new Date(),
    });

    this.logger.log(`Payment refunded for booking ${bookingId}`);
    return { ...payment, status: PaymentStatus.REFUNDED };
  }

  // ─── Auto-release held payments after 24 hours ────────────────────────────────
  // Runs every hour, releases payments held for 24+ hours on completed bookings

  @Cron(CronExpression.EVERY_HOUR)
  async autoReleaseHeldPayments() {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago

    const heldPayments = await this.paymentRepo
      .createQueryBuilder('payment')
      .innerJoin('payment.booking', 'booking')
      .where('payment.status = :status', { status: PaymentStatus.HELD })
      .andWhere('payment.held_at < :cutoff', { cutoff })
      .andWhere('booking.status = :bookingStatus', { bookingStatus: BookingStatus.COMPLETED })
      .getMany();

    if (heldPayments.length === 0) return;

    this.logger.log(`Auto-releasing ${heldPayments.length} held payment(s)...`);

    for (const payment of heldPayments) {
      try {
        await this.releasePayment(payment.bookingId);
      } catch (err) {
        this.logger.error(`Failed to auto-release payment ${payment.id}`, err);
      }
    }
  }

  // ─── Platform earnings summary ────────────────────────────────────────────────

  async getPlatformEarnings() {
    const result = await this.paymentRepo
      .createQueryBuilder('payment')
      .select('SUM(payment.platform_fee)', 'totalEarnings')
      .addSelect('SUM(payment.amount)', 'totalVolume')
      .addSelect('COUNT(*)', 'totalTransactions')
      .where('payment.status IN (:...statuses)', {
        statuses: [PaymentStatus.RELEASED, PaymentStatus.HELD],
      })
      .getRawOne();

    return {
      totalEarnings: parseFloat(result.totalEarnings || '0'),
      totalVolume: parseFloat(result.totalVolume || '0'),
      totalTransactions: parseInt(result.totalTransactions || '0'),
    };
  }
}
