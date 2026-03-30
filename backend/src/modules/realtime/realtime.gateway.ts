import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
  WsException,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UseGuards } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { Booking, BookingStatus } from '../../database/entities/booking.entity';
import { Ride, RideStatus } from '../../database/entities/ride.entity';

// ─── Event names ──────────────────────────────────────────────────────────────
export const EVENTS = {
  // Client → Server
  JOIN_RIDE: 'join_ride',
  LEAVE_RIDE: 'leave_ride',
  LOCATION_UPDATE: 'location_update',
  SOS_ALERT: 'sos_alert',

  // Server → Client
  RIDER_JOINED: 'rider_joined',
  LOCATION_RECEIVED: 'location_received',
  RIDE_STATUS_CHANGED: 'ride_status_changed',
  SOS_RECEIVED: 'sos_received',
  ERROR: 'error',
};

@WebSocketGateway({
  cors: {
    origin: '*', // tightened in production via config
  },
  namespace: '/realtime',
})
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RealtimeGateway.name);

  // Map: socketId → userId (for tracking connected users)
  private connectedUsers = new Map<string, string>();

  constructor(
    private jwtService: JwtService,

    @InjectRepository(User)
    private userRepo: Repository<User>,

    @InjectRepository(Booking)
    private bookingRepo: Repository<Booking>,

    @InjectRepository(Ride)
    private rideRepo: Repository<Ride>,
  ) {}

  // ─── Connection lifecycle ──────────────────────────────────────────────────

  async handleConnection(socket: Socket) {
    try {
      const user = await this.authenticateSocket(socket);
      this.connectedUsers.set(socket.id, user.id);
      this.logger.log(`Connected: ${user.firstName} (${socket.id})`);
    } catch {
      socket.emit(EVENTS.ERROR, { message: 'Unauthorized. Provide a valid JWT token.' });
      socket.disconnect();
    }
  }

  handleDisconnect(socket: Socket) {
    const userId = this.connectedUsers.get(socket.id);
    this.connectedUsers.delete(socket.id);
    this.logger.log(`Disconnected: userId=${userId} (${socket.id})`);
  }

  // ─── Join Ride Room ────────────────────────────────────────────────────────
  // Both driver and confirmed riders join the ride room

  @SubscribeMessage(EVENTS.JOIN_RIDE)
  async handleJoinRide(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { rideId: string },
  ) {
    const userId = this.connectedUsers.get(socket.id);
    if (!userId) throw new WsException('Not authenticated');

    const ride = await this.rideRepo.findOne({ where: { id: data.rideId } });
    if (!ride) throw new WsException('Ride not found');

    // Only driver or confirmed riders can join
    const isDriver = ride.driverId === userId;
    const isRider = await this.bookingRepo.findOne({
      where: { rideId: data.rideId, riderId: userId, status: BookingStatus.CONFIRMED },
    });

    if (!isDriver && !isRider) {
      throw new WsException('You are not a participant of this ride');
    }

    const room = `ride:${data.rideId}`;
    socket.join(room);

    this.logger.log(`User ${userId} joined room ${room}`);

    // Notify others in room
    socket.to(room).emit(EVENTS.RIDER_JOINED, {
      userId,
      role: isDriver ? 'driver' : 'rider',
      timestamp: new Date(),
    });

    return { success: true, room };
  }

  // ─── Leave Ride Room ───────────────────────────────────────────────────────

  @SubscribeMessage(EVENTS.LEAVE_RIDE)
  handleLeaveRide(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { rideId: string },
  ) {
    const room = `ride:${data.rideId}`;
    socket.leave(room);
    return { success: true };
  }

  // ─── Location Update (driver → all riders in room) ─────────────────────────

  @SubscribeMessage(EVENTS.LOCATION_UPDATE)
  async handleLocationUpdate(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { rideId: string; lat: number; lng: number; heading?: number },
  ) {
    const userId = this.connectedUsers.get(socket.id);
    if (!userId) throw new WsException('Not authenticated');

    // Only driver can broadcast location
    const ride = await this.rideRepo.findOne({ where: { id: data.rideId } });
    if (!ride || ride.driverId !== userId) {
      throw new WsException('Only the driver can broadcast location');
    }

    if (ride.status !== RideStatus.IN_PROGRESS) {
      throw new WsException('Location updates only allowed during active rides');
    }

    const room = `ride:${data.rideId}`;
    // Broadcast to all riders in the room (excluding driver's socket)
    socket.to(room).emit(EVENTS.LOCATION_RECEIVED, {
      lat: data.lat,
      lng: data.lng,
      heading: data.heading,
      timestamp: new Date(),
    });
  }

  // ─── SOS Alert ────────────────────────────────────────────────────────────
  // Any participant can trigger SOS — broadcasts to room + logs

  @SubscribeMessage(EVENTS.SOS_ALERT)
  async handleSos(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { rideId: string; lat?: number; lng?: number; message?: string },
  ) {
    const userId = this.connectedUsers.get(socket.id);
    if (!userId) throw new WsException('Not authenticated');

    const user = await this.userRepo.findOne({ where: { id: userId } });
    const room = `ride:${data.rideId}`;

    const sosPayload = {
      triggeredBy: {
        userId,
        name: `${user?.firstName} ${user?.lastName}`,
      },
      rideId: data.rideId,
      location: data.lat && data.lng ? { lat: data.lat, lng: data.lng } : null,
      message: data.message || 'Emergency — immediate help needed',
      timestamp: new Date(),
    };

    // Alert everyone in the ride room
    this.server.to(room).emit(EVENTS.SOS_RECEIVED, sosPayload);

    // Also alert admin room
    this.server.to('admin').emit(EVENTS.SOS_RECEIVED, sosPayload);

    this.logger.warn(`🚨 SOS triggered by user ${userId} in ride ${data.rideId}`);

    return { success: true, message: 'SOS alert sent' };
  }

  // ─── Server-side broadcast helpers (called from other services) ───────────

  broadcastRideStatus(rideId: string, status: string) {
    this.server.to(`ride:${rideId}`).emit(EVENTS.RIDE_STATUS_CHANGED, {
      rideId,
      status,
      timestamp: new Date(),
    });
  }

  // ─── Auth helper ──────────────────────────────────────────────────────────

  private async authenticateSocket(socket: Socket): Promise<User> {
    // Accept token from handshake auth or query param
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) throw new WsException('No token provided');

    const payload = this.jwtService.verify(token);
    const user = await this.userRepo.findOne({
      where: { id: payload.sub, isActive: true },
    });

    if (!user) throw new WsException('User not found');
    return user;
  }
}
