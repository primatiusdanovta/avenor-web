class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'AVENOR_API_BASE_URL',
    defaultValue: 'https://avenorperfume.site/api/mobile',
  );

  static const appName = 'Avenor Marketing';
}
