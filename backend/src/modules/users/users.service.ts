import {
  Injectable, NotFoundException, BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, VerificationStatus } from '../../database/entities/user.entity';
import { Vehicle } from '../../database/entities/vehicle.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { RedisService } from '../redis/redis.service';

const DEV_OTP = '112233';
const OTP_TTL = 300; // 5 minutes

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,

    @InjectRepository(Vehicle)
    private vehicleRepo: Repository<Vehicle>,

    private redis: RedisService,
  ) {}

  // ─── Profile ──────────────────────────────────────────────────────────────────

  async getProfile(userId: string): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async getPublicProfile(userId: string) {
    const user = await this.userRepo.findOne({ where: { id: userId, isActive: true } });
    if (!user) throw new NotFoundException('User not found');

    // Return only safe public fields
    return {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      avatarUrl: user.avatarUrl,
      userType: user.userType,
      verificationStatus: user.verificationStatus,
      linkedinUrl: user.linkedinUrl,
      trustScore: user.trustScore,
      companyEmail: user.companyEmail ? `***@${user.companyEmail.split('@')[1]}` : null,
      universityEmail: user.universityEmail ? `***@${user.universityEmail.split('@')[1]}` : null,
      createdAt: user.createdAt,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<User> {
    await this.userRepo.update(userId, dto);
    return this.getProfile(userId);
  }

  // ─── Vehicles ─────────────────────────────────────────────────────────────────

  async getMyVehicles(userId: string): Promise<Vehicle[]> {
    return this.vehicleRepo.find({
      where: { userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async addVehicle(userId: string, dto: CreateVehicleDto): Promise<Vehicle> {
    const vehicle = this.vehicleRepo.create({ ...dto, userId });
    return this.vehicleRepo.save(vehicle);
  }

  async updateVehicle(
    userId: string,
    vehicleId: string,
    dto: Partial<CreateVehicleDto>,
  ): Promise<Vehicle> {
    const vehicle = await this.vehicleRepo.findOne({
      where: { id: vehicleId, userId },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    await this.vehicleRepo.update(vehicleId, dto);
    return this.vehicleRepo.findOne({ where: { id: vehicleId } }) as Promise<Vehicle>;
  }

  async deleteVehicle(userId: string, vehicleId: string): Promise<void> {
    const vehicle = await this.vehicleRepo.findOne({
      where: { id: vehicleId, userId },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    // Soft delete
    await this.vehicleRepo.update(vehicleId, { isActive: false });
  }

  async updateFcmToken(userId: string, fcmToken: string): Promise<void> {
    await this.userRepo.update(userId, { fcmToken });
  }

  // ─── Phone OTP ───────────────────────────────────────────────────────────────

  async sendPhoneOtp(userId: string, phoneNumber: string): Promise<void> {
    // Check if this phone is already used by a different account
    const existing = await this.userRepo.findOne({ where: { phone: phoneNumber } });
    if (existing && existing.id !== userId) {
      throw new BadRequestException('This phone number is already linked to another account.');
    }

    // In dev, always use 112233. In prod, integrate an SMS provider here.
    const otp = DEV_OTP;
    await this.redis.set(`phone_otp:${userId}`, JSON.stringify({ otp, phone: phoneNumber }), OTP_TTL);
    // TODO (prod): send SMS via Twilio/Telenor etc with `otp`
  }

  async verifyPhoneOtp(userId: string, phoneNumber: string, otp: string): Promise<User> {
    const raw = await this.redis.get(`phone_otp:${userId}`);
    if (!raw) throw new BadRequestException('OTP expired. Please request a new one.');

    const stored = JSON.parse(raw) as { otp: string; phone: string };
    if (stored.phone !== phoneNumber) throw new BadRequestException('Phone number mismatch.');
    if (stored.otp !== otp) throw new BadRequestException('Incorrect OTP.');

    await this.redis.del(`phone_otp:${userId}`);
    await this.userRepo.update(userId, { phone: phoneNumber, isPhoneVerified: true });
    return this.getProfile(userId);
  }

  async submitVerification(userId: string): Promise<User> {
    await this.userRepo.update(userId, {
      verificationSubmittedAt: new Date(),
      verificationStatus: VerificationStatus.PENDING,
      rejectionReason: undefined,
    });
    return this.getProfile(userId);
  }
}
