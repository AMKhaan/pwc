class RideModel {
  final String id;
  final String driverId;
  final String rideType;
  final String status;
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final double? distanceKm;
  final bool isRecurring;
  final String? notes;
  final String? discussionTopic;
  final double? discussionFee;
  final String? hostExpertise;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? vehicle;

  RideModel({
    required this.id,
    required this.driverId,
    required this.rideType,
    required this.status,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    this.distanceKm,
    required this.isRecurring,
    this.notes,
    this.discussionTopic,
    this.discussionFee,
    this.hostExpertise,
    this.driver,
    this.vehicle,
  });

  String get driverName {
    if (driver == null) return 'Driver';
    return '${driver!['firstName']} ${driver!['lastName']}';
  }

  static double _toDouble(dynamic v) => double.parse(v.toString());
  static double? _toDoubleOpt(dynamic v) => v == null ? null : double.parse(v.toString());
  static int _toInt(dynamic v) => v is int ? v : int.parse(v.toString());

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      rideType: json['rideType'] as String,
      status: json['status'] as String,
      originAddress: json['originAddress'] as String,
      originLat: _toDouble(json['originLat']),
      originLng: _toDouble(json['originLng']),
      destinationAddress: json['destinationAddress'] as String,
      destinationLat: _toDouble(json['destinationLat']),
      destinationLng: _toDouble(json['destinationLng']),
      departureTime: DateTime.parse(json['departureTime'] as String),
      totalSeats: _toInt(json['totalSeats']),
      availableSeats: _toInt(json['availableSeats']),
      pricePerSeat: _toDouble(json['pricePerSeat']),
      distanceKm: _toDoubleOpt(json['distanceKm']),
      isRecurring: json['isRecurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      discussionTopic: json['discussionTopic'] as String?,
      discussionFee: _toDoubleOpt(json['discussionFee']),
      hostExpertise: json['hostExpertise'] as String?,
      driver: json['driver'] as Map<String, dynamic>?,
      vehicle: json['vehicle'] as Map<String, dynamic>?,
    );
  }
}
