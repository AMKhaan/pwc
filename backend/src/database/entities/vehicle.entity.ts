import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

export enum FuelType {
  PETROL = 'PETROL',
  DIESEL = 'DIESEL',
  CNG = 'CNG',
  ELECTRIC = 'ELECTRIC',
  HYBRID = 'HYBRID',
}

export enum VehicleType {
  CAR = 'CAR',
  BIKE = 'BIKE',
}

@Entity('vehicles')
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'vehicle_type', type: 'enum', enum: VehicleType, default: VehicleType.CAR })
  vehicleType: VehicleType;

  @Column()
  make: string;

  @Column()
  model: string;

  @Column()
  year: number;

  @Column()
  color: string;

  @Column({ name: 'license_plate' })
  licensePlate: string;

  @Column({ name: 'total_seats' })
  totalSeats: number;

  @Column({ name: 'fuel_type', type: 'enum', enum: FuelType, default: FuelType.PETROL })
  fuelType: FuelType;

  @Column({ name: 'engine_cc', nullable: true })
  engineCC: number;

  @Column({ name: 'owner_name', nullable: true })
  ownerName: string;

  @Column({ name: 'chassis_number', nullable: true })
  chassisNumber: string;

  @Column({ name: 'document_url', nullable: true })
  documentUrl: string;

  @Column({
    name: 'avg_fuel_consumption',
    type: 'decimal',
    precision: 5,
    scale: 2,
    nullable: true,
  })
  avgFuelConsumption: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
