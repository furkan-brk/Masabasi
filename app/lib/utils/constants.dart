/// App-wide constants for the Masabaşı Oyun Kulübü web app.
class AppConstants {
  AppConstants._();

  static const String appName = 'Masabaşı Oyun Kulübü';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8090/api/v1',
  );
}
