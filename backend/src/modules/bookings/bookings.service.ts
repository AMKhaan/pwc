import {
  Injectable, NotFoundException, BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Booking, BookingStatus, PaymentType,
} from '../../database/entities/booking.entity';
import { Ride, RideStatus, RideType } from '../../database/entities/ride.entity';
import { User } from '../../database/entities/user.entity';
import { RidesService } from '../rides/rides.service';
import { PushService } from '../notifications/push.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Injectable()
export class BookingsService {
  constructor(
    @InjectRepository(Booking)
    private bookingRepo: Repository<Booking>,

    @InjectRepository(Ride)
    private rideRepo: Repository<Ride>,

    private ridesService: RidesService,
    private pushService: PushService,
  ) {}

  // ─── Create Booking ───────────────────────────────────────────────────────────

  async createBooking(rider: User, dto: CreateBookingDto): Promise<Booking> {
    const seats = dto.seatsBooked || 1;

    const ride = await this.rideRepo.findOne({
      where: { id: dto.rideId },
      relations: ['driver'],
    });

    if (!ride) throw new NotFoundException('Ride not found');

    // Cannot book own ride
    if (ride.driverId === rider.id) {
      throw new BadRequestException('You cannot book your own ride');
    }

    // Ride must be active
    if (ride.status !== RideStatus.ACTIVE) {
      throw new BadRequestException('This ride is no longer available');
    }

    // Enough seats
    if (ride.availableSeats < seats) {
      throw new BadRequestException(
        `Only ${ride.availableSeats} seat(s) available`,
      );
    }

    // Departure time must be in future
    if (new Date(ride.departureTime) < new Date()) {
      throw new BadRequestException('This ride has already departed');
    }

    // No duplicate booking
    const existing = await this.bookingRepo.findOne({
      where: {
        rideId: dto.rideId,
        riderId: rider.id,
        status: BookingStatus.CONFIRMED,
      },
    });
    if (existing) throw new BadRequestException('You already have a booking for this ride');

    // Payment type
    const paymentType =
      ride.rideType === RideType.DISCUSSION ? PaymentType.ESCROW : PaymentType.DIRECT;

    const booking = this.bookingRepo.create({
      rideId: dto.rideId,
      riderId: rider.id,
      seatsBooked: seats,
      totalAmount: Number(ride.pricePerSeat) * seats,
      paymentType,
      paymentMethod: dto.paymentMethod,
      pickupAddress: dto.pickupAddress,
      pickupLat: dto.pickupLat,
      pickupLng: dto.pickupLng,
      status: BookingStatus.PENDING,
    });

    await this.bookingRepo.save(booking);

    // Decrement available seats
    await this.ridesService.decrementSeats(dto.rideId, seats);

    // Notify driver of new booking request
    if (ride.driver?.fcmToken) {
      await this.pushService.sendToDevice(ride.driver.fcmToken, {
        title: 'New Booking Request',
        body: `${rider.firstName} ${rider.lastName} wants to join your ride`,
        data: { bookingId: booking.id, rideId: ride.id, type: 'BOOKING_REQUEST' },
      });
    }

    return booking;
  }

  // ─── Pending requests count (driver badge) ───────────────────────────────────

  async getPendingRequestsCount(driverId: string): Promise<{ count: number }> {
    const count = await this.bookingRepo
      .createQueryBuilder('booking')
      .innerJoin('booking.ride', 'ride')
      .where('ride.driver_id = :driverId', { driverId })
      .andWhere('booking.status = :status', { status: BookingStatus.PENDING })
      .getCount();
    return { count };
  }

  // ─── Pending counts per ride (for per-ride badge in My Rides list) ───────────

  async getPendingCountsPerRide(driverId: string): Promise<Record<string, number>> {
    const rows = await this.bookingRepo
      .createQueryBuilder('booking')
      .select('booking.ride_id', 'rideId')
      .addSelect('COUNT(*)', 'cnt')
      .innerJoin('booking.ride', 'ride')
      .where('ride.driver_id = :driverId', { driverId })
      .andWhere('booking.status = :status', { status: BookingStatus.PENDING })
      .groupBy('booking.ride_id')
      .getRawMany();

    return rows.reduce<Record<string, number>>((acc, row) => {
      acc[row.rideId] = parseInt(row.cnt, 10);
      return acc;
    }, {});
  }

  // ─── Get My Bookings (as rider) ───────────────────────────────────────────────

  async getMyBookings(riderId: string): Promise<Booking[]> {
    return this.bookingRepo.find({
      where: { riderId },
      relations: ['ride', 'ride.driver', 'ride.vehicle'],
      order: { createdAt: 'DESC' },
    });
  }

  // ─── Get Booking by ID ────────────────────────────────────────────────────────

  async getBookingById(bookingId: string, userId: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['ride', 'ride.driver', 'ride.vehicle', 'rider'],
    });
    if (!booking) throw new NotFoundException('Booking not found');

    // Only rider or driver can view
    if (booking.riderId !== userId && booking.ride.driverId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return booking;
  }

  // ─── Get Ride Bookings (driver sees who booked their ride) ────────────────────

  async getRideBookings(rideId: string, driverId: string): Promise<Booking[]> {
    const ride = await this.rideRepo.findOne({ where: { id: rideId, driverId } });
    if (!ride) throw new NotFoundException('Ride not found');

    return this.bookingRepo.find({
      where: [
        { rideId, status: BookingStatus.PENDING },
        { rideId, status: BookingStatus.CONFIRMED },
      ],
      relations: ['rider'],
      order: { createdAt: 'ASC' },
    });
  }

  // ─── Driver confirms a booking ────────────────────────────────────────────────

  async confirmBooking(driverId: string, bookingId: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['ride'],
    });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.ride.driverId !== driverId) throw new ForbiddenException('Access denied');
    if (booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException('Booking is not in pending state');
    }

    await this.bookingRepo.update(bookingId, {
      status: BookingStatus.CONFIRMED,
      confirmedAt: new Date(),
    });

    // Notify rider their booking was confirmed
    const rider = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['rider'],
    });
    if (rider?.rider?.fcmToken) {
      await this.pushService.sendToDevice(rider.rider.fcmToken, {
        title: 'Booking Confirmed!',
        body: `Your seat is confirmed for the ride on ${new Date(booking.ride.departureTime).toLocaleDateString()}`,
        data: { bookingId: booking.id, type: 'BOOKING_CONFIRMED' },
      });
    }

    return { ...booking, status: BookingStatus.CONFIRMED };
  }

  // ─── Cancel Booking ───────────────────────────────────────────────────────────

  async cancelBooking(
    userId: string,
    bookingId: string,
    reason?: string,
  ): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['ride'],
    });
    if (!booking) throw new NotFoundException('Booking not found');

    // Only rider or driver can cancel
    const isRider = booking.riderId === userId;
    const isDriver = booking.ride.driverId === userId;
    if (!isRider && !isDriver) throw new ForbiddenException('Access denied');

    if (booking.status === BookingStatus.COMPLETED) {
      throw new BadRequestException('Cannot cancel a completed booking');
    }
    if (booking.status === BookingStatus.CANCELLED) {
      throw new BadRequestException('Booking already cancelled');
    }

    await this.bookingRepo.update(bookingId, {
      status: BookingStatus.CANCELLED,
      cancelledAt: new Date(),
      cancellationReason: reason,
    });

    // Restore seats
    await this.ridesService.incrementSeats(booking.rideId, booking.seatsBooked);

    return { ...booking, status: BookingStatus.CANCELLED };
  }

  // ─── Complete Booking ─────────────────────────────────────────────────────────

  async completeBooking(driverId: string, bookingId: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['ride'],
    });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.ride.driverId !== driverId) throw new ForbiddenException('Access denied');
    if (booking.status !== BookingStatus.CONFIRMED) {
      throw new BadRequestException('Booking must be confirmed before completing');
    }

    await this.bookingRepo.update(bookingId, {
      status: BookingStatus.COMPLETED,
      completedAt: new Date(),
    });

    return { ...booking, status: BookingStatus.COMPLETED };
  }
}
