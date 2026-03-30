import {
  Controller, Get, Post, Patch, Body,
  Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { RidesService } from './rides.service';
import { CreateRideDto } from './dto/create-ride.dto';
import { SearchRidesDto } from './dto/search-rides.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';

@ApiTags('Rides')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('rides')
export class RidesController {
  constructor(private ridesService: RidesService) {}

  @Post()
  @ApiOperation({ summary: 'Post a new ride' })
  createRide(@CurrentUser() user: User, @Body() dto: CreateRideDto) {
    return this.ridesService.createRide(user, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Search available rides' })
  searchRides(@Query() dto: SearchRidesDto, @CurrentUser() user: User) {
    return this.ridesService.searchRides(dto, user);
  }

  @Get('my')
  @ApiOperation({ summary: 'Get my rides as driver' })
  getMyRides(@CurrentUser() user: User) {
    return this.ridesService.getMyRides(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get ride details by ID' })
  getRide(@Param('id') id: string) {
    return this.ridesService.getRideById(id);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel a ride (driver only)' })
  cancelRide(@CurrentUser() user: User, @Param('id') id: string) {
    return this.ridesService.cancelRide(user.id, id);
  }

  @Patch(':id/start')
  @ApiOperation({ summary: 'Start a ride (driver only)' })
  startRide(@CurrentUser() user: User, @Param('id') id: string) {
    return this.ridesService.startRide(user.id, id);
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: 'Complete a ride (driver only)' })
  completeRide(@CurrentUser() user: User, @Param('id') id: string) {
    return this.ridesService.completeRide(user.id, id);
  }
}
