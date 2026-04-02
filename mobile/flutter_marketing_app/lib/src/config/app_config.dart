class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'AVENOR_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/mobile',
  );

  static const appName = 'Avenor Marketing';
}
