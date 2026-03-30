import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, ILike } from 'typeorm';
import { User, VerificationStatus } from '../../database/entities/user.entity';
import { Ride, RideStatus, RideType } from '../../database/entities/ride.entity';
import { Payment, PaymentStatus } from '../../database/entities/payment.entity';
import { Booking, BookingStatus } from '../../database/entities/booking.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Ride) private ridesRepo: Repository<Ride>,
    @InjectRepository(Payment) private paymentsRepo: Repository<Payment>,
    @InjectRepository(Booking) private bookingsRepo: Repository<Booking>,
  ) {}

  async getDashboardStats() {
    const [
      totalUsers,
      verifiedUsers,
      activeRides,
      totalRides,
      totalBookings,
      completedBookings,
      pendingVerifications,
    ] = await Promise.all([
      this.usersRepo.count(),
      this.usersRepo.count({ where: { verificationStatus: VerificationStatus.VERIFIED } }),
      this.ridesRepo.count({ where: { status: RideStatus.IN_PROGRESS as any } }),
      this.ridesRepo.count(),
      this.bookingsRepo.count(),
      this.bookingsRepo.count({ where: { status: BookingStatus.COMPLETED } }),
      this.usersRepo.count({ where: { verificationStatus: VerificationStatus.PENDING } }),
    ]);

    const earningsResult = await this.paymentsRepo
      .createQueryBuilder('p')
      .select('COALESCE(SUM(p.platform_fee), 0)', 'total')
      .where('p.status IN (:...statuses)', {
        statuses: [PaymentStatus.RELEASED],
      })
      .getRawOne<{ total: string }>();

    return {
      totalUsers,
      verifiedUsers,
      activeRides,
      totalRides,
      totalBookings,
      completedBookings,
      platformEarnings: parseFloat(earningsResult?.total ?? '0'),
      pendingVerifications,
    };
  }

  async getUsers(params: {
    page: number;
    limit: number;
    search?: string;
    verificationStatus?: string;
    userType?: string;
  }) {
    const { page, limit, search, verificationStatus, userType } = params;
    const qb = this.usersRepo.createQueryBuilder('u');

    if (search) {
      qb.andWhere(
        '(LOWER(u.first_name) LIKE :s OR LOWER(u.last_name) LIKE :s OR LOWER(u.email) LIKE :s)',
        { s: `%${search.toLowerCase()}%` },
      );
    }
    if (verificationStatus) {
      qb.andWhere('u.verification_status = :vs', { vs: verificationStatus });
    }
    if (userType) {
      qb.andWhere('u.user_type = :ut', { ut: userType });
    }

    const [users, total] = await qb
      .orderBy('u.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { users, total };
  }

  async suspendUser(id: string) {
    await this.usersRepo.update(id, { isSuspended: true, isActive: false });
  }

  async unsuspendUser(id: string) {
    await this.usersRepo.update(id, { isSuspended: false, isActive: true });
  }

  async getRides(params: {
    page: number;
    limit: number;
    search?: string;
    type?: string;
    status?: string;
  }) {
    const { page, limit, search, type, status } = params;
    const qb = this.ridesRepo
      .createQueryBuilder('r')
      .leftJoinAndSelect('r.driver', 'd');

    if (search) {
      qb.andWhere(
        '(LOWER(r.origin_address) LIKE :s OR LOWER(r.destination_address) LIKE :s OR LOWER(d.first_name) LIKE :s OR LOWER(d.last_name) LIKE :s)',
        { s: `%${search.toLowerCase()}%` },
      );
    }
    if (type) qb.andWhere('r.type = :type', { type });
    if (status) qb.andWhere('r.status = :status', { status });

    const [rides, total] = await qb
      .orderBy('r.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { rides, total };
  }

  async getPayments(params: { page: number; limit: number; status?: string }) {
    const { page, limit, status } = params;
    const qb = this.paymentsRepo
      .createQueryBuilder('p')
      .leftJoinAndSelect('p.booking', 'b')
      .leftJoinAndSelect('b.rider', 'rider')
      .leftJoinAndSelect('b.ride', 'ride');

    if (status) qb.andWhere('p.status = :status', { status });

    const [payments, total] = await qb
      .orderBy('p.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { payments, total };
  }

  async getVerificationQueue(params: { page: number; limit: number; type?: string }) {
    const { page, limit, type } = params;
    const qb = this.usersRepo
      .createQueryBuilder('u')
      .where('u.verification_status = :status', { status: VerificationStatus.PENDING });

    if (type) {
      qb.andWhere('u.user_type = :type', { type });
    }

    const [items, total] = await qb
      .orderBy('u.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { items, total };
  }

  async approveVerification(id: string) {
    await this.usersRepo.update(id, {
      verificationStatus: VerificationStatus.VERIFIED,
      rejectionReason: undefined,
    });
  }

  async rejectVerification(id: string, reason: string) {
    await this.usersRepo.update(id, {
      verificationStatus: VerificationStatus.REJECTED,
      rejectionReason: reason,
      verificationSubmittedAt: undefined,
    });
  }

  async getVerificationUser(id: string) {
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new Error('User not found');
    return user;
  }
}
