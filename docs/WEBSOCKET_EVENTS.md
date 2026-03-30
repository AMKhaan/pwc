# WebSocket Events
## RideSync Real-time API

**Namespace:** `/realtime`
**Auth:** Send JWT token in handshake: `{ auth: { token: "Bearer ..." } }`

---

## Connection

```javascript
const socket = io('http://localhost:3000/realtime', {
  auth: { token: 'your_jwt_token' }
});
```

---

## Client → Server Events

### `join_ride`
Join a ride room (driver or confirmed rider).
```json
{ "rideId": "uuid" }
```
Response: `{ "success": true, "room": "ride:uuid" }`

---

### `leave_ride`
Leave a ride room.
```json
{ "rideId": "uuid" }
```

---

### `location_update`
Driver only — broadcast current GPS location to all riders.
```json
{
  "rideId": "uuid",
  "lat": 31.4815,
  "lng": 74.3984,
  "heading": 180
}
```
No response — broadcasts `location_received` to room.

---

### `sos_alert`
Any participant — trigger emergency alert.
```json
{
  "rideId": "uuid",
  "lat": 31.4815,
  "lng": 74.3984,
  "message": "Need help immediately"
}
```
Response: `{ "success": true, "message": "SOS alert sent" }`

---

## Server → Client Events

### `location_received`
Riders receive driver's live location.
```json
{
  "lat": 31.4815,
  "lng": 74.3984,
  "heading": 180,
  "timestamp": "2026-03-24T10:00:00Z"
}
```

---

### `ride_status_changed`
All room members notified on status change.
```json
{
  "rideId": "uuid",
  "status": "IN_PROGRESS | COMPLETED | CANCELLED",
  "timestamp": "2026-03-24T10:00:00Z"
}
```

---

### `rider_joined`
Notified when someone joins the ride room.
```json
{
  "userId": "uuid",
  "role": "driver | rider",
  "timestamp": "2026-03-24T10:00:00Z"
}
```

---

### `sos_received`
Emergency alert broadcast to all room members + admin.
```json
{
  "triggeredBy": { "userId": "uuid", "name": "John Doe" },
  "rideId": "uuid",
  "location": { "lat": 31.4815, "lng": 74.3984 },
  "message": "Need help immediately",
  "timestamp": "2026-03-24T10:00:00Z"
}
```

---

### `error`
Any WebSocket error.
```json
{ "message": "Error description" }
```

---

## Flutter Usage (Phase 5 reference)

```dart
// Connect
final socket = io('http://api.ridesync.pk/realtime',
  OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': jwtToken})
    .build()
);

// Join ride room
socket.emit('join_ride', {'rideId': rideId});

// Driver sends location
socket.emit('location_update', {
  'rideId': rideId,
  'lat': position.latitude,
  'lng': position.longitude,
  'heading': position.heading,
});

// Rider listens for location
socket.on('location_received', (data) {
  updateDriverMarker(data['lat'], data['lng']);
});

// Listen for SOS
socket.on('sos_received', (data) {
  showSosAlert(data);
});
```
