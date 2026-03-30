class BookingModel {
  final String id;
  final String rideId;
  final String riderId;
  final String status;
  final int seatsBooked;
  final double totalAmount;
  final String paymentType;
  final String? paymentMethod;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? ride;
  final Map<String, dynamic>? rider;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  BookingModel({
    required this.id,
    required this.rideId,
    required this.riderId,
    required this.status,
    required this.seatsBooked,
    required this.totalAmount,
    required this.paymentType,
    this.paymentMethod,
    this.confirmedAt,
    this.completedAt,
    required this.createdAt,
    this.ride,
    this.rider,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
  });

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isEscrow => paymentType == 'ESCROW';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      rideId: json['rideId'] as String,
      riderId: json['riderId'] as String,
      status: json['status'] as String,
      seatsBooked: json['seatsBooked'] is int ? json['seatsBooked'] as int : int.parse(json['seatsBooked'].toString()),
      totalAmount: double.parse(json['totalAmount'].toString()),
      paymentType: json['paymentType'] as String,
      paymentMethod: json['paymentMethod'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ride: json['ride'] as Map<String, dynamic>?,
      rider: json['rider'] as Map<String, dynamic>?,
      pickupAddress: json['pickupAddress'] as String?,
      pickupLat: json['pickupLat'] != null
          ? double.parse(json['pickupLat'].toString())
          : null,
      pickupLng: json['pickupLng'] != null
          ? double.parse(json['pickupLng'].toString())
          : null,
    );
  }
}
