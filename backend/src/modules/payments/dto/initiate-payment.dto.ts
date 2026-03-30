import { IsEnum, IsNotEmpty, IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PaymentGateway } from '../../../database/entities/payment.entity';

export class InitiatePaymentDto {
  @ApiProperty({ example: 'uuid-of-booking' })
  @IsUUID()
  bookingId: string;

  @ApiProperty({ enum: PaymentGateway })
  @IsEnum(PaymentGateway)
  method: PaymentGateway;

  @ApiProperty({ example: '03001234567', description: 'JazzCash or EasyPaisa number' })
  @IsString()
  @IsNotEmpty()
  mobileNumber: string;
}
