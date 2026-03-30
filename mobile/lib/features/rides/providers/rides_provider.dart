import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/ride_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

// ─── Search / List rides ──────────────────────────────────────────────────────

class RidesNotifier extends StateNotifier<AsyncValue<List<RideModel>>> {
  RidesNotifier() : super(const AsyncValue.data([]));

  final _dio = DioClient.instance;

  Future<void> searchRides({
    String? rideType,
    String? date,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    String? expertise,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _dio.get(
        ApiConstants.rides,
        queryParameters: {
          if (rideType != null) 'rideType': rideType,
          if (date != null) 'date': date,
          if (originLat != null) 'originLat': originLat,
          if (originLng != null) 'originLng': originLng,
          if (destinationLat != null) 'destinationLat': destinationLat,
          if (destinationLng != null) 'destinationLng': destinationLng,
          if (expertise != null) 'expertise': expertise,
        },
      );

      final rides = (res.data as List)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(rides);
    } on DioException catch (e) {
      state = AsyncValue.error(e.message ?? 'Failed to load rides', StackTrace.current);
    }
  }

  Future<void> loadMyRides() async {
    state = const AsyncValue.loading();
    try {
      final res = await _dio.get(ApiConstants.myRides);
      final rides = (res.data as List)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(rides);
    } on DioException catch (e) {
      state = AsyncValue.error(e.message ?? 'Failed to load rides', StackTrace.current);
    }
  }
}

final ridesProvider =
    StateNotifierProvider<RidesNotifier, AsyncValue<List<RideModel>>>((ref) {
  return RidesNotifier();
});

// ─── Single ride ──────────────────────────────────────────────────────────────

final rideDetailProvider =
    FutureProvider.family<RideModel, String>((ref, rideId) async {
  final res = await DioClient.instance.get('${ApiConstants.rides}/$rideId');
  return RideModel.fromJson(res.data as Map<String, dynamic>);
});

// ─── Create ride ──────────────────────────────────────────────────────────────

final createRideProvider = Provider<Future<RideModel?> Function(Map<String, dynamic>)>(
  (ref) => (data) async {
    try {
      final res = await DioClient.instance.post(ApiConstants.rides, data: data);
      return RideModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  },
);
