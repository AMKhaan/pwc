import {
  IsDateString, IsEnum, IsNumber, IsOptional, IsString, Max, Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { RideType } from '../../../database/entities/ride.entity';

export class SearchRidesDto {
  @ApiPropertyOptional({ enum: RideType })
  @IsOptional()
  @IsEnum(RideType)
  rideType?: RideType;

  // Rider's pickup location
  @ApiPropertyOptional({ example: 31.4815 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  originLat?: number;

  @ApiPropertyOptional({ example: 74.3984 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  originLng?: number;

  // Rider's drop-off location
  @ApiPropertyOptional({ example: 31.5109 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  destinationLat?: number;

  @ApiPropertyOptional({ example: 74.3436 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  destinationLng?: number;

  @ApiPropertyOptional({ example: '2026-03-25', description: 'Date (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  date?: string;

  @ApiPropertyOptional({ example: 3, description: 'Proximity radius in KM', default: 3 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(20)
  radiusKm?: number;

  // Discussion ride filter
  @ApiPropertyOptional({ example: 'Product Management' })
  @IsOptional()
  @IsString()
  expertise?: string;
}
