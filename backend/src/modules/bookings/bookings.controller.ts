import {
  Controller, Get, Post, Patch, Body,
  Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';

@ApiTags('Bookings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('bookings')
export class BookingsController {
  constructor(private bookingsService: BookingsService) {}

  @Post()
  @ApiOperation({ summary: 'Book a ride' })
  createBooking(@CurrentUser() user: User, @Body() dto: CreateBookingDto) {
    return this.bookingsService.createBooking(user, dto);
  }

  @Get('my')
  @ApiOperation({ summary: 'Get my bookings as rider' })
  getMyBookings(@CurrentUser() user: User) {
    return this.bookingsService.getMyBookings(user.id);
  }

  @Get('pending-count')
  @ApiOperation({ summary: 'Count of pending booking requests on my rides (driver)' })
  getPendingCount(@CurrentUser() user: User) {
    return this.bookingsService.getPendingRequestsCount(user.id);
  }

  @Get('pending-per-ride')
  @ApiOperation({ summary: 'Pending request count per ride { rideId: count }' })
  getPendingPerRide(@CurrentUser() user: User) {
    return this.bookingsService.getPendingCountsPerRide(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get booking details' })
  getBooking(@CurrentUser() user: User, @Param('id') id: string) {
    return this.bookingsService.getBookingById(id, user.id);
  }

  @Get('ride/:rideId')
  @ApiOperation({ summary: 'Get all bookings for my ride (driver view)' })
  getRideBookings(@CurrentUser() user: User, @Param('rideId') rideId: string) {
    return this.bookingsService.getRideBookings(rideId, user.id);
  }

  @Patch(':id/confirm')
  @ApiOperation({ summary: 'Confirm a booking (driver only)' })
  confirmBooking(@CurrentUser() user: User, @Param('id') id: string) {
    return this.bookingsService.confirmBooking(user.id, id);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel a booking (rider or driver)' })
  cancelBooking(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body('reason') reason?: string,
  ) {
    return this.bookingsService.cancelBooking(user.id, id, reason);
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: 'Mark booking complete (driver only)' })
  completeBooking(@CurrentUser() user: User, @Param('id') id: string) {
    return this.bookingsService.completeBooking(user.id, id);
  }
}
