import {
  Controller, Post, Get, Patch,
  Body, Param, UseGuards, HttpCode, HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';

@ApiTags('Payments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Post('initiate')
  @ApiOperation({ summary: 'Initiate payment for a Discussion Ride booking' })
  initiatePayment(@CurrentUser() user: User, @Body() dto: InitiatePaymentDto) {
    return this.paymentsService.initiatePayment(user.id, dto);
  }

  @Get('booking/:bookingId')
  @ApiOperation({ summary: 'Get payment status for a booking' })
  getPayment(@CurrentUser() user: User, @Param('bookingId') bookingId: string) {
    return this.paymentsService.getPaymentByBooking(bookingId, user.id);
  }

  @Patch('booking/:bookingId/release')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Release held payment to host (triggered after ride completion)' })
  releasePayment(
    @CurrentUser() user: User,
    @Param('bookingId') bookingId: string,
  ) {
    return this.paymentsService.releasePayment(bookingId);
  }

  @Patch('booking/:bookingId/refund')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refund a held payment (cancelled Discussion Ride)' })
  refundPayment(@Param('bookingId') bookingId: string) {
    return this.paymentsService.refundPayment(bookingId);
  }
}
