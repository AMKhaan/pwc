import {
  IsEnum, IsInt, IsNotEmpty, IsOptional,
  IsString, Max, Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FuelType, VehicleType } from '../../../database/entities/vehicle.entity';

export class CreateVehicleDto {
  @ApiProperty({ enum: VehicleType })
  @IsEnum(VehicleType)
  vehicleType: VehicleType;

  @ApiProperty({ example: 'Toyota' })
  @IsString()
  @IsNotEmpty()
  make: string;

  @ApiProperty({ example: 'Corolla' })
  @IsString()
  @IsNotEmpty()
  model: string;

  @ApiProperty({ example: 2020 })
  @IsInt()
  @Min(2000)
  @Max(2030)
  year: number;

  @ApiProperty({ example: 'White' })
  @IsString()
  @IsNotEmpty()
  color: string;

  @ApiProperty({ example: 'LHR-123-AB' })
  @IsString()
  @IsNotEmpty()
  licensePlate: string;

  @ApiProperty({ example: 3, description: 'Passenger seats excluding driver' })
  @IsInt()
  @Min(1)
  @Max(10)
  totalSeats: number;

  @ApiProperty({ enum: FuelType })
  @IsEnum(FuelType)
  fuelType: FuelType;

  @ApiPropertyOptional({ example: 1000, description: 'Engine CC (not required for ELECTRIC)' })
  @IsOptional()
  @IsInt()
  @Min(50)
  @Max(5000)
  engineCC?: number;

  @ApiProperty({ example: 'Muhammad Ali' })
  @IsString()
  @IsNotEmpty()
  ownerName: string;

  @ApiProperty({ example: 'ABC123456789' })
  @IsString()
  @IsNotEmpty()
  chassisNumber: string;

  @ApiPropertyOptional({ example: 'https://r2.ridesync.pk/docs/vehicle.jpg' })
  @IsOptional()
  @IsString()
  documentUrl?: string;
}
