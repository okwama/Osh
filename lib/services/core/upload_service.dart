import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:woosh/config/cloudinary_config.dart';

class UploadService {
  static const String _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/otienobryan/image/upload';

  /// Uploads an image or document file to Cloudinary with optional compression
  static Future<Map<String, dynamic>> uploadImage(File file) async {
    try {
      // Detect file type by extension
      final ext = file.path.split('.').last.toLowerCase();
      final isImage =
          ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
      File uploadFile = file;

      if (isImage) {
        // Compress the image first
        uploadFile = await _compressImage(file);
      } else {
        print('📤 Detected non-image file: .$ext, skipping compression');
      }

      // Read the file
      final bytes = await uploadFile.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl));

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'file_${DateTime.now().millisecondsSinceEpoch}.$ext',
        ),
      );

      // Add Cloudinary parameters
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['timestamp'] =
          (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      request.fields['folder'] = 'whoosh';
      request.fields['use_filename'] = 'true';
      request.fields['unique_filename'] = 'true';

      // Generate signature (simplified - in production, this should be done server-side)
      final signature = _generateSignature(request.fields);
      request.fields['signature'] = signature;

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (isImage) {
        // Clean up temporary file if it was compressed
        if (uploadFile.path != file.path) {
          await uploadFile.delete();
        }
      }

      if (response.statusCode == 200) {
        // Parse response
        final responseMap = _parseResponse(responseData);
        return {
          'url': responseMap['secure_url'],
          'fileId': responseMap['public_id'],
          'name': responseMap['original_filename'],
          'format': responseMap['format'],
          'size': responseMap['bytes'],
          'width': responseMap['width'],
          'height': responseMap['height'],
        };
      } else {
        print('📤 Upload failed with status: ${response.statusCode}');
        print('📤 Response body: $responseData');
        throw Exception(
            'Upload failed: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      print('📤 File upload error: $e');
      throw Exception('File upload error: $e');
    }
  }

  /// Compresses an image file to reduce size while maintaining quality
  static Future<File> _compressImage(File file) async {
    try {
      // Read the image file
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      int width = image.width;
      int height = image.height;
      const maxDimension = 1200;

      if (width > maxDimension || height > maxDimension) {
        if (width > height) {
          height = (height * maxDimension / width).round();
          width = maxDimension;
        } else {
          width = (width * maxDimension / height).round();
          height = maxDimension;
        }
      }

      // Resize the image
      final resized = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.cubic,
      );

      // Compress with progressive quality reduction
      int quality = 85;
      List<int> compressedBytes = img.encodeJpg(resized, quality: quality);

      // If still too large, reduce quality further
      while (compressedBytes.length > 500 * 1024 && quality > 60) {
        // Target 500KB
        quality -= 5;
        compressedBytes = img.encodeJpg(resized, quality: quality);
      }

      // Create temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Generates a proper HMAC-SHA1 signature for Cloudinary upload
  static String _generateSignature(Map<String, String> fields) {
    // Create a sorted map of parameters to sign (exclude api_key and file)
    final paramsToSign = <String, String>{};

    // Add parameters that need to be signed (alphabetically sorted)
    for (final entry in fields.entries) {
      if (entry.key != 'api_key' && entry.key != 'file') {
        paramsToSign[entry.key] = entry.value;
      }
    }

    // Sort parameters alphabetically
    final sortedParams = SplayTreeMap<String, String>.from(paramsToSign);

    // Create signature string
    final signatureString =
        sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    // Create the string to sign (parameters + api_secret)
    final stringToSign = '$signatureString${CloudinaryConfig.apiSecret}';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    print('📸 Signature string: $signatureString');
    print('📸 String to sign: $stringToSign');
    print('📸 Generated signature: $digest');

    return digest.toString();
  }

  /// Parses Cloudinary response
  static Map<String, dynamic> _parseResponse(String responseData) {
    try {
      // Use proper JSON parsing
      final Map<String, dynamic> result = json.decode(responseData);

      print('📸 Upload response parsed successfully');
      print('📸 Secure URL: ${result['secure_url']}');
      print('📸 Public ID: ${result['public_id']}');

      return result;
    } catch (e) {
      print('📸 Failed to parse response: $responseData');
      throw Exception('Failed to parse upload response: $e');
    }
  }

  /// Uploads image from bytes (for web or memory-based uploads)
  static Future<Map<String, dynamic>> uploadImageFromBytes(
    Uint8List bytes, {
    String? filename,
  }) async {
    try {
      // Create temporary file from bytes
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/${filename ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg'}');
      await tempFile.writeAsBytes(bytes);

      // Upload using the file upload method
      final result = await uploadImage(tempFile);

      // Clean up temporary file
      await tempFile.delete();

      return result;
    } catch (e) {
      throw Exception('Failed to upload image from bytes: $e');
    }
  }

  /// Deletes an image from Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/otienobryan/image/destroy';
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();

      final response = await http.post(
        Uri.parse(url),
        body: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp,
          'signature': _generateSignature({
            'public_id': publicId,
            'timestamp': timestamp,
          }),
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Gets upload progress callback (for future implementation)
  static void Function(int, int)? getUploadProgress() {
    // This can be implemented for progress tracking
    return null;
  }

  /// Test signature generation (for debugging)
  static void testSignatureGeneration() {
    final testFields = {
      'timestamp': '1234567890',
      'folder': 'whoosh',
      'use_filename': 'true',
      'unique_filename': 'true',
      'api_key': CloudinaryConfig.apiKey,
    };

    print('🧪 Testing signature generation...');
    print('🧪 Test fields: $testFields');

    final signature = _generateSignature(testFields);
    print('🧪 Generated signature: $signature');
    print('🧪 Signature length: ${signature.length}');
    print('🧪 Test complete');
  }
}
