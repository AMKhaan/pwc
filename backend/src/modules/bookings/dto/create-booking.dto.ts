import {
  IsEnum, IsInt, IsNumber, IsOptional, IsString, IsUUID, Min, Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../../database/entities/booking.entity';

export class CreateBookingDto {
  @ApiProperty({ example: 'uuid-of-ride' })
  @IsUUID()
  rideId: string;

  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(4)
  seatsBooked?: number;

  @ApiPropertyOptional({ enum: PaymentMethod })
  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ example: 'DHA Phase 5, Lahore' })
  @IsOptional()
  @IsString()
  pickupAddress?: string;

  @ApiPropertyOptional({ example: 31.4816 })
  @IsOptional()
  @IsNumber()
  pickupLat?: number;

  @ApiPropertyOptional({ example: 74.4013 })
  @IsOptional()
  @IsNumber()
  pickupLng?: number;
}
