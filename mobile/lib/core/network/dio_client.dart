import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_ErrorInterceptor());

    return dio;
  }
}

// ─── Auth Interceptor — attaches JWT to every request ────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─── Error Interceptor — standardizes error messages ─────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'Something went wrong. Please try again.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Check your internet.';
    } else if (err.response != null) {
      final data = err.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        message = msg is List ? msg.first.toString() : msg.toString();
      }
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to server. Check your internet.';
    }

    handler.next(
      err.copyWith(
        message: message,
      ),
    );
  }
}

// ─── API error helper ─────────────────────────────────────────────────────────
String extractApiError(Object error) {
  if (error is DioException) {
    return error.message ?? 'Something went wrong';
  }
  return error.toString();
}
