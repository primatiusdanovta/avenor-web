class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'SWEETIE_API_BASE_URL',
    defaultValue: 'https://avenorperfume.site/api/mobile',
  );

  static const appName = 'Smoothies Sweetie';
}

