import 'dart:io';
import 'dart:convert';

/// Script to remove redundant await _db.initialize() calls from service files
/// Since database is now initialized centrally in main.dart, these calls are no longer needed
void main() async {
  print('🧹 Starting cleanup of redundant database initialize calls...\n');

  // Define the service directories to process
  final serviceDirs = [
    'lib/services/core',
    'lib/services/core/reports',
  ];

  int totalFilesProcessed = 0;
  int totalCallsRemoved = 0;
  final processedFiles = <String>[];

  for (final dir in serviceDirs) {
    final directory = Directory(dir);
    if (!await directory.exists()) {
      print('⚠️ Directory not found: $dir');
      continue;
    }

    print('📁 Processing directory: $dir');
    
    await for (final file in directory.list(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        final result = await processFile(file);
        if (result['processed']) {
          totalFilesProcessed++;
          totalCallsRemoved += result['callsRemoved'] as int;
          processedFiles.add(file.path);
          print('  ✅ ${file.path}: ${result['callsRemoved']} calls removed');
        }
      }
    }
  }

  print('\n📊 Cleanup Summary:');
  print('  📁 Files processed: $totalFilesProcessed');
  print('  🗑️ Total calls removed: $totalCallsRemoved');
  print('  📋 Files modified: ${processedFiles.length}');
  
  if (processedFiles.isNotEmpty) {
    print('\n📝 Modified files:');
    for (final file in processedFiles) {
      print('  • $file');
    }
  }

  print('\n✅ Cleanup completed successfully!');
  print('💡 Database initialization is now centralized in main.dart');
}

/// Process a single Dart file to remove redundant initialize calls
Future<Map<String, dynamic>> processFile(File file) async {
  try {
    String content = await file.readAsString();
    final originalContent = content;
    
    // Pattern to match: await _db.initialize();
    // This will match the line with proper indentation
    final pattern = RegExp(r'^\s*await _db\.initialize\(\);\s*$', multiLine: true);
    
    final matches = pattern.allMatches(content);
    if (matches.isEmpty) {
      return {'processed': false, 'callsRemoved': 0};
    }

    // Remove the initialize calls
    content = content.replaceAll(pattern, '');
    
    // Also remove any empty lines that might be left behind
    content = _cleanupEmptyLines(content);
    
    // Only write if content actually changed
    if (content != originalContent) {
      await file.writeAsString(content);
      return {'processed': true, 'callsRemoved': matches.length};
    }
    
    return {'processed': false, 'callsRemoved': 0};
  } catch (e) {
    print('❌ Error processing ${file.path}: $e');
    return {'processed': false, 'callsRemoved': 0};
  }
}

/// Clean up empty lines that might be left after removing initialize calls
String _cleanupEmptyLines(String content) {
  // Remove multiple consecutive empty lines, keeping only one
  content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
  
  // Remove empty lines at the beginning of try blocks
  content = content.replaceAll(RegExp(r'(\s*try\s*\{\s*)\n\s*\n'), r'$1\n');
  
  // Remove empty lines before catch blocks
  content = content.replaceAll(RegExp(r'\n\s*\n(\s*catch\s*\()'), r'\n$1');
  
  return content;
}

/// Alternative: Process specific files manually if needed
Future<void> processSpecificFiles() async {
  final specificFiles = [
    'lib/services/core/order_service.dart',
    'lib/services/core/product_service.dart',
    'lib/services/core/payment_service.dart',
    'lib/services/core/notice_service.dart',
    'lib/services/core/route_service.dart',
    'lib/services/core/uplift_sale_service.dart',
    'lib/services/core/task_service.dart',
    'lib/services/core/target_service.dart',
    'lib/services/core/store_service.dart',
    'lib/services/core/session_service.dart',
    'lib/services/core/journey_plan_service.dart',
    'lib/services/core/leave_service.dart',
  ];

  print('🎯 Processing specific files...\n');

  for (final filePath in specificFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      final result = await processFile(file);
      if (result['processed']) {
        print('✅ $filePath: ${result['callsRemoved']} calls removed');
      } else {
        print('ℹ️ $filePath: No changes needed');
      }
    } else {
      print('⚠️ File not found: $filePath');
    }
  }
} 