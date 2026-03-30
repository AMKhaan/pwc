class ApiConstants {
  ApiConstants._();

  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS simulator
  // static const String baseUrl = 'http://192.168.18.135:3000/api/v1'; // Physical device (local)
  static const String baseUrl = 'http://165.232.135.168:3001/api/v1'; // Production server

  static const String wsUrl = 'http://165.232.135.168:3001';
  static const String wsNamespace = '/realtime';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendOtp = '/auth/resend-otp';
  static const String me = '/auth/me';
  static const String sendCompanyOtp = '/auth/verify-company-email/send';
  static const String confirmCompanyOtp = '/auth/verify-company-email/confirm';
  static const String sendUniversityOtp = '/auth/verify-university-email/send';
  static const String confirmUniversityOtp = '/auth/verify-university-email/confirm';

  // Users
  static const String myProfile = '/users/me';
  static const String myVehicles = '/users/me/vehicles';

  // Rides
  static const String rides = '/rides';
  static const String myRides = '/rides/my';

  // Bookings
  static const String bookings = '/bookings';
  static const String myBookings = '/bookings/my';
  static const String rideBookings = '/bookings/ride';
  static const String pendingBookingsCount = '/bookings/pending-count';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static const String markNotificationsRead = '/notifications/mark-all-read';
  static const String pendingPerRide = '/bookings/pending-per-ride';

  // Payments
  static const String initiatePayment = '/payments/initiate';

  // Profile completion / verification
  static const String idDocumentUploadUrl = '/users/me/id-document-upload-url';
  static const String submitVerification = '/users/me/submit-verification';
  static const String avatarUploadUrl = '/users/me/avatar-upload-url';
  static const String saveAvatarUrl = '/users/me/avatar';
  static const String sendPhoneOtp = '/users/me/send-phone-otp';
  static const String verifyPhoneOtp = '/users/me/verify-phone-otp';
}
