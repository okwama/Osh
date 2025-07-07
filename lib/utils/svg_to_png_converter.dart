import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

/// A simple utility class for working with error icons in the app
class ErrorIconHelper {
  /// Gets the asset path for the 500 error SVG icon
  static String get oops500SvgPath => 'assets/images/error/oops_500.svg';

  /// Gets the asset path for the 500 error PNG icon
  static String get oops500PngPath => 'assets/images/error/oops_500.png';

  /// Checks if the error icons are available in the assets
  static Future<bool> areErrorIconsAvailable() async {
    try {
      // Try to load the SVG file
      await rootBundle.load(oops500SvgPath);
      return true;
    } catch (e) {
      debugPrint('Error icon not found: $e');
      return false;
    }
  }

  /// Builds a widget to display for 500 errors
  static Widget build500ErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Oops!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
