import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageOptimizer {
  static Widget optimizedImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    String? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: placeholder != null
            ? Image.asset(placeholder)
            : const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: errorWidget != null
            ? Image.asset(errorWidget)
            : const Icon(Icons.error_outline),
      ),
      memCacheWidth:
          (width * 2).toInt(), // Cache higher resolution for retina displays
      maxWidthDiskCache: (width * 2).toInt(),
    );
  }

  static String getOptimizedImageUrl(String originalUrl,
      {int? width, int? height}) {
    // Add your image optimization service URL parameters here
    // Example: return '$originalUrl?w=$width&h=$height&q=80';
    return originalUrl;
  }
}
