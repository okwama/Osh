class Config {
  static const String baseUrl = 'https://woosh-api-mocha.vercel.app';
// static const String baseUrl = 'http://192.168.100.10:5000';
  static const String apiVersion = 'v1';
  static const String imageBaseUrl =
      'https://woosh-api-mocha.vercel.app/uploads';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String productsEndpoint = '/products';
  static const String ordersEndpoint = '/orders';
  static const String outletsEndpoint = '/outlets';

  // Cache Configuration
  static const Duration defaultCacheValidity = Duration(minutes: 5);
  static const Duration imageCacheValidity = Duration(hours: 1);

  // Image Configuration
  static const int maxImageWidth = 800; // For product images
  static const int maxImageHeight = 800; // For product images
  static const double imageThumbnailQuality = 0.8;
}
