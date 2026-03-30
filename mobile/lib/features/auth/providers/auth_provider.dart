import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/api_constants.dart';

String _apiError(Object e) => extractApiError(e);

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _dio = DioClient.instance;

  // ─── Init — check stored token ────────────────────────────────────────────

  Future<void> init() async {
    final token = await SecureStorage.getToken();
    if (token == null) return;

    try {
      final res = await _dio.get(ApiConstants.me);
      state = state.copyWith(user: UserModel.fromJson(res.data));
    } on DioException catch (e) {
      // Only log out on 401 — not on network errors or parse failures
      if (e.response?.statusCode == 401) {
        await SecureStorage.deleteToken();
      }
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.post(ApiConstants.register, data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'userType': userType,
        if (phone != null) 'phone': phone,
      });
      state = state.copyWith(isLoading: false);
      return res.data['userId'] as String;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _apiError(e));
      return null;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      final token = res.data['accessToken'] as String;
      await SecureStorage.saveToken(token);
      final user = UserModel.fromJson(res.data['user']);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _apiError(e));
      return false;
    }
  }

  // ─── Verify Email OTP ─────────────────────────────────────────────────────

  Future<bool> verifyEmail({required String email, required String token}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post(ApiConstants.verifyEmail, data: {
        'email': email,
        'token': token,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _apiError(e));
      return false;
    }
  }

  // ─── Resend OTP ───────────────────────────────────────────────────────────

  Future<bool> resendOtp(String email) async {
    try {
      await _dio.post(ApiConstants.resendOtp, data: {'email': email});
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }

  // ─── Refresh current user ─────────────────────────────────────────────────

  Future<void> refreshUser() async {
    try {
      final res = await _dio.get(ApiConstants.me);
      state = state.copyWith(user: UserModel.fromJson(res.data));
    } catch (_) {}
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
