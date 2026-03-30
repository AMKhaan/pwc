class AppConstants {
  AppConstants._();

  static const String appName = 'RideSync';
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';

  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 10.0;

  // Map defaults — centered on Lahore
  static const double lahoreLat = 31.5204;
  static const double lahoreLng = 74.3587;
  static const double defaultZoom = 13.0;

  // Ride types (matches backend enum)
  static const String officeRide = 'OFFICE';
  static const String universityRide = 'UNIVERSITY';
  static const String discussionRide = 'DISCUSSION';
}
