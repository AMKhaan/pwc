import {
  Injectable, NotFoundException, BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThan } from 'typeorm';
import { Ride, RideStatus, RideType } from '../../database/entities/ride.entity';
import { Vehicle } from '../../database/entities/vehicle.entity';
import { User, VerificationStatus } from '../../database/entities/user.entity';
import { MatchingService } from '../matching/matching.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { CreateRideDto } from './dto/create-ride.dto';
import { SearchRidesDto } from './dto/search-rides.dto';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class RidesService {
  constructor(
    @InjectRepository(Ride)
    private rideRepo: Repository<Ride>,

    @InjectRepository(Vehicle)
    private vehicleRepo: Repository<Vehicle>,

    private matching: MatchingService,
    private realtime: RealtimeGateway,
    private config: ConfigService,
  ) {}

  // ─── Create Ride ──────────────────────────────────────────────────────────────

  async createRide(driver: User, dto: CreateRideDto): Promise<Ride> {
    // Must be verified to post rides (skip in development for testing)
    const isDev = this.config.get('app.nodeEnv') === 'development';
    if (!isDev && driver.verificationStatus !== VerificationStatus.VERIFIED) {
      throw new ForbiddenException(
        'Complete your profile verification before posting rides',
      );
    }

    // Vehicle must belong to driver
    const vehicle = await this.vehicleRepo.findOne({
      where: { id: dto.vehicleId, userId: driver.id, isActive: true },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    // University ride — must have university email
    if (dto.rideType === RideType.UNIVERSITY && !driver.universityEmail) {
      throw new ForbiddenException(
        'Verify your university email to post university rides',
      );
    }

    // Calculate road distance + fetch route polyline via OSRM
    const [distanceKm, routePolyline] = await Promise.all([
      this.matching.getRoadDistanceKm(
        dto.originLat, dto.originLng,
        dto.destinationLat, dto.destinationLng,
      ),
      this.matching.getRoutePolyline(
        dto.originLat, dto.originLng,
        dto.destinationLat, dto.destinationLng,
      ),
    ]);

    // Calculate price per seat using vehicle CC and type
    const pricePerSeat = dto.rideType === RideType.DISCUSSION && dto.discussionFee !== undefined
      ? dto.discussionFee
      : this.matching.calculatePricePerSeat(
          distanceKm,
          vehicle.vehicleType,
          vehicle.engineCC,
          dto.totalSeats,
        );

    const ride = this.rideRepo.create({
      driverId: driver.id,
      vehicleId: dto.vehicleId,
      rideType: dto.rideType,
      originAddress: dto.originAddress,
      originLat: dto.originLat,
      originLng: dto.originLng,
      destinationAddress: dto.destinationAddress,
      destinationLat: dto.destinationLat,
      destinationLng: dto.destinationLng,
      departureTime: new Date(dto.departureTime),
      totalSeats: dto.totalSeats,
      availableSeats: dto.totalSeats,
      pricePerSeat,
      distanceKm,
      routePolyline,
      isRecurring: dto.isRecurring || false,
      recurringDays: dto.recurringDays,
      notes: dto.notes,
      discussionTopic: dto.discussionTopic,
      discussionFee: dto.discussionFee,
      hostExpertise: dto.hostExpertise,
    });

    return this.rideRepo.save(ride);
  }

  // ─── Search Rides ─────────────────────────────────────────────────────────────

  async searchRides(dto: SearchRidesDto, currentUser: User): Promise<Ride[]> {
    const query = this.rideRepo.createQueryBuilder('ride')
      .leftJoinAndSelect('ride.driver', 'driver')
      .leftJoinAndSelect('ride.vehicle', 'vehicle')
      .where('ride.status = :status', { status: RideStatus.ACTIVE })
      .andWhere('ride.availableSeats > 0')
      .andWhere('ride.departureTime > :now', { now: new Date() })
      .andWhere('ride.driverId != :userId', { userId: currentUser.id });

    // Filter by ride type
    if (dto.rideType) {
      query.andWhere('ride.rideType = :rideType', { rideType: dto.rideType });
    }

    // Filter by date (same calendar day)
    if (dto.date) {
      const start = new Date(dto.date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(dto.date);
      end.setHours(23, 59, 59, 999);
      query.andWhere('ride.departureTime BETWEEN :start AND :end', { start, end });
    }

    // Filter by expertise (Discussion rides)
    if (dto.expertise) {
      query.andWhere('ride.hostExpertise ILIKE :expertise', {
        expertise: `%${dto.expertise}%`,
      });
    }

    // Gender preference filter
    if (currentUser.genderPreference === 'SAME_GENDER' && currentUser.gender) {
      query.andWhere('driver.gender = :gender', { gender: currentUser.gender });
    }

    query.orderBy('ride.departureTime', 'ASC').take(50);

    const rides = await query.getMany();

    // Apply route corridor matching if coordinates provided
    if (dto.originLat && dto.originLng) {
      return rides.filter((ride) => {
        // If ride has stored polyline — use corridor matching
        if (ride.routePolyline && ride.routePolyline.length > 1) {
          if (dto.destinationLat && dto.destinationLng) {
            // Full corridor match: pickup AND dropoff on route
            return this.matching.isRiderOnRoute(
              ride.routePolyline,
              dto.originLat!, dto.originLng!,
              dto.destinationLat!, dto.destinationLng!,
              1.5,
            );
          } else {
            // Pickup-only search: just check if pickup is near any route point
            return ride.routePolyline.some((point) =>
              this.matching.calculateDistance(
                point.lat, point.lng,
                dto.originLat!, dto.originLng!,
              ) <= 2,
            );
          }
        }

        // Fallback: legacy endpoint proximity for older rides without polyline
        return this.matching.isRouteMatch(
          Number(ride.originLat), Number(ride.originLng),
          Number(ride.destinationLat), Number(ride.destinationLng),
          dto.originLat!, dto.originLng!,
          dto.destinationLat ?? Number(ride.destinationLat),
          dto.destinationLng ?? Number(ride.destinationLng),
          3,
        );
      });
    }

    return rides;
  }

  // ─── Get Ride by ID ───────────────────────────────────────────────────────────

  async getRideById(rideId: string): Promise<Ride> {
    const ride = await this.rideRepo.findOne({
      where: { id: rideId },
      relations: ['driver', 'vehicle'],
    });
    if (!ride) throw new NotFoundException('Ride not found');
    return ride;
  }

  // ─── Get My Rides (as driver) ─────────────────────────────────────────────────

  async getMyRides(driverId: string): Promise<Ride[]> {
    return this.rideRepo.find({
      where: { driverId },
      relations: ['vehicle'],
      order: { departureTime: 'DESC' },
    });
  }

  // ─── Cancel Ride ──────────────────────────────────────────────────────────────

  async cancelRide(driverId: string, rideId: string): Promise<Ride> {
    const ride = await this.rideRepo.findOne({ where: { id: rideId, driverId } });
    if (!ride) throw new NotFoundException('Ride not found');

    if (ride.status === RideStatus.IN_PROGRESS) {
      throw new BadRequestException('Cannot cancel a ride that is in progress');
    }
    if (ride.status === RideStatus.COMPLETED) {
      throw new BadRequestException('Ride already completed');
    }

    await this.rideRepo.update(rideId, { status: RideStatus.CANCELLED });
    this.realtime.broadcastRideStatus(rideId, RideStatus.CANCELLED);
    return { ...ride, status: RideStatus.CANCELLED };
  }

  // ─── Start Ride ───────────────────────────────────────────────────────────────

  async startRide(driverId: string, rideId: string): Promise<Ride> {
    const ride = await this.rideRepo.findOne({ where: { id: rideId, driverId } });
    if (!ride) throw new NotFoundException('Ride not found');

    if (ride.status !== RideStatus.ACTIVE) {
      throw new BadRequestException('Ride is not in active status');
    }

    await this.rideRepo.update(rideId, { status: RideStatus.IN_PROGRESS });
    this.realtime.broadcastRideStatus(rideId, RideStatus.IN_PROGRESS);
    return { ...ride, status: RideStatus.IN_PROGRESS };
  }

  // ─── Complete Ride ────────────────────────────────────────────────────────────

  async completeRide(driverId: string, rideId: string): Promise<Ride> {
    const ride = await this.rideRepo.findOne({ where: { id: rideId, driverId } });
    if (!ride) throw new NotFoundException('Ride not found');

    if (ride.status !== RideStatus.IN_PROGRESS) {
      throw new BadRequestException('Ride is not in progress');
    }

    await this.rideRepo.update(rideId, { status: RideStatus.COMPLETED });
    this.realtime.broadcastRideStatus(rideId, RideStatus.COMPLETED);
    return { ...ride, status: RideStatus.COMPLETED };
  }

  // ─── Decrease available seats (called from BookingsService) ──────────────────

  async decrementSeats(rideId: string, seats: number): Promise<void> {
    await this.rideRepo.decrement({ id: rideId }, 'availableSeats', seats);
  }

  async incrementSeats(rideId: string, seats: number): Promise<void> {
    await this.rideRepo.increment({ id: rideId }, 'availableSeats', seats);
  }
}
