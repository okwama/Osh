class ImageUtils {
  static String getOptimizedImageUrl(
    String? originalUrl, {
    int width = 300,
    int height = 300,
    int quality = 80,
    String format = 'webp',
    bool progressive = true,
  }) {
    if (originalUrl == null || originalUrl.isEmpty) {
      return 'https://via.placeholder.com/$width'; // Placeholder image
    }

    // If URL already contains ImageKit transformations, return it as is
    if (originalUrl.contains('tr=')) {
      return originalUrl;
    }

    // If the URL is already complete (starts with http:// or https://), no need to prepend base URL
    if (originalUrl.startsWith('http://') ||
        originalUrl.startsWith('https://')) {
      return originalUrl; // Return the full URL as is
    }

    // Add ImageKit transformations
    final transformations = [
      'w-$width',
      'h-$height',
      'q-$quality',
      'f-$format',
      if (progressive) 'pr-true',
    ];

    final separator = originalUrl.contains('?') ? '&' : '?';
    return '$originalUrl${separator}tr=${transformations.join(",")}';
  }

  static String getThumbnailUrl(String? originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: 120,
      height: 120,
      quality: 60,
    );
  }

  static String getDetailUrl(String? originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: 800,
      height: 800,
      quality: 90,
    );
  }

  static String getGridUrl(String? originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: 300,
      height: 300,
      quality: 75,
    );
  }
}
