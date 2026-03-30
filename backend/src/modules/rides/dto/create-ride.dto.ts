import {
  IsArray, IsBoolean, IsDateString, IsEnum, IsNotEmpty,
  IsNumber, IsOptional, IsString, IsUUID, Max, Min, ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RideType, RecurringDay } from '../../../database/entities/ride.entity';

export class CreateRideDto {
  @ApiProperty({ enum: RideType })
  @IsEnum(RideType)
  rideType: RideType;

  @ApiProperty({ example: 'uuid-of-vehicle' })
  @IsUUID()
  vehicleId: string;

  @ApiProperty({ example: 'DHA Phase 5, Lahore' })
  @IsString()
  @IsNotEmpty()
  originAddress: string;

  @ApiProperty({ example: 31.4815 })
  @IsNumber()
  originLat: number;

  @ApiProperty({ example: 74.3984 })
  @IsNumber()
  originLng: number;

  @ApiProperty({ example: 'Gulberg III, Lahore' })
  @IsString()
  @IsNotEmpty()
  destinationAddress: string;

  @ApiProperty({ example: 31.5109 })
  @IsNumber()
  destinationLat: number;

  @ApiProperty({ example: 74.3436 })
  @IsNumber()
  destinationLng: number;

  @ApiProperty({ example: '2026-03-25T08:00:00.000Z' })
  @IsDateString()
  departureTime: string;

  @ApiProperty({ example: 3, description: 'Seats available for riders' })
  @IsNumber()
  @Min(1)
  @Max(8)
  totalSeats: number;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;

  @ApiPropertyOptional({ enum: RecurringDay, isArray: true })
  @IsOptional()
  @IsArray()
  @IsEnum(RecurringDay, { each: true })
  recurringDays?: RecurringDay[];

  @ApiPropertyOptional({ example: 'Prefer quiet mornings' })
  @IsOptional()
  @IsString()
  notes?: string;

  // ─── Discussion Ride only ───────────────────────────────────────────────────

  @ApiPropertyOptional({ example: 'Product-Market Fit strategies for startups' })
  @ValidateIf((o) => o.rideType === RideType.DISCUSSION)
  @IsString()
  @IsNotEmpty()
  discussionTopic?: string;

  @ApiPropertyOptional({ example: 500, description: 'Fee in PKR (0 = free)' })
  @ValidateIf((o) => o.rideType === RideType.DISCUSSION)
  @IsNumber()
  @Min(0)
  discussionFee?: number;

  @ApiPropertyOptional({ example: 'Product Management, SaaS' })
  @ValidateIf((o) => o.rideType === RideType.DISCUSSION)
  @IsString()
  hostExpertise?: string;
}
