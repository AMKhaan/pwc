import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Vehicle } from './vehicle.entity';

export enum RideType {
  OFFICE = 'OFFICE',
  UNIVERSITY = 'UNIVERSITY',
  DISCUSSION = 'DISCUSSION',
}

export enum RideStatus {
  ACTIVE = 'ACTIVE',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum RecurringDay {
  MON = 'MON',
  TUE = 'TUE',
  WED = 'WED',
  THU = 'THU',
  FRI = 'FRI',
  SAT = 'SAT',
  SUN = 'SUN',
}

@Entity('rides')
export class Ride {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'driver_id' })
  driver: User;

  @Column({ name: 'driver_id' })
  driverId: string;

  @ManyToOne(() => Vehicle)
  @JoinColumn({ name: 'vehicle_id' })
  vehicle: Vehicle;

  @Column({ name: 'vehicle_id' })
  vehicleId: string;

  @Column({ name: 'ride_type', type: 'enum', enum: RideType })
  rideType: RideType;

  @Column({ type: 'enum', enum: RideStatus, default: RideStatus.ACTIVE })
  status: RideStatus;

  @Column({ name: 'origin_address', type: 'text' })
  originAddress: string;

  @Column({ name: 'origin_lat', type: 'decimal', precision: 10, scale: 8 })
  originLat: number;

  @Column({ name: 'origin_lng', type: 'decimal', precision: 11, scale: 8 })
  originLng: number;

  @Column({ name: 'destination_address', type: 'text' })
  destinationAddress: string;

  @Column({ name: 'destination_lat', type: 'decimal', precision: 10, scale: 8 })
  destinationLat: number;

  @Column({ name: 'destination_lng', type: 'decimal', precision: 11, scale: 8 })
  destinationLng: number;

  @Column({ name: 'departure_time', type: 'timestamp' })
  departureTime: Date;

  @Column({ name: 'estimated_duration_mins', nullable: true })
  estimatedDurationMins: number;

  @Column({
    name: 'distance_km',
    type: 'decimal',
    precision: 8,
    scale: 2,
    nullable: true,
  })
  distanceKm: number;

  @Column({ name: 'route_polyline', type: 'jsonb', nullable: true })
  routePolyline: Array<{ lat: number; lng: number }>;

  @Column({ name: 'total_seats' })
  totalSeats: number;

  @Column({ name: 'available_seats' })
  availableSeats: number;

  @Column({
    name: 'price_per_seat',
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  pricePerSeat: number;

  @Column({ name: 'is_recurring', default: false })
  isRecurring: boolean;

  @Column({ name: 'recurring_days', type: 'text', array: true, nullable: true })
  recurringDays: RecurringDay[];

  @Column({ type: 'text', nullable: true })
  notes: string;

  // Discussion Ride fields
  @Column({ name: 'discussion_topic', nullable: true })
  discussionTopic: string;

  @Column({
    name: 'discussion_fee',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  discussionFee: number;

  @Column({ name: 'host_expertise', nullable: true })
  hostExpertise: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
