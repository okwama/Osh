import 'dart:io';
import 'dart:convert';

/// Script to automatically fix common linting issues
class LintingFixer {
  static const Map<String, String> _fileRenames = {
    'feedbackReport_model.dart': 'feedback_report_model.dart',
    'productReport_model.dart': 'product_report_model.dart',
    'productReturn_model.dart': 'product_return_model.dart',
    'productSample_model.dart': 'product_sample_model.dart',
    'visibilityReport_model.dart': 'visibility_report_model.dart',
    'offlineToast.dart': 'offline_toast.dart',
    'createJourneyplan.dart': 'create_journey_plan.dart',
    'createJourneyplan_modular.dart': 'create_journey_plan_modular.dart',
    'reportMain_page.dart': 'report_main_page.dart',
    'updateOrder_page.dart': 'update_order_page.dart',
    'orderDetail.dart': 'order_detail.dart',
    'upliftSaleCart_page.dart': 'uplift_sale_cart_page.dart',
    'ChangePasswordPage.dart': 'change_password_page.dart',
  };

  static const List<String> _patternsToFix = [
    // Remove unused variables
    r'final \w+ \w+ = .*; // unused',
    r'final \w+ \w+ = .*; // Add',

    // Fix empty catch blocks
    r'} catch \(e\) {\s*}',

    // Fix unnecessary null-aware operators
    r'(\w+)\.\?\.(\w+)',

    // Fix unnecessary null comparisons
    r'(\w+) != null && (\w+) != null',

    // Fix unnecessary string interpolations
    r'\$\{(\w+)\}',
  ];

  static void main(List<String> args) async {
    print('🔧 Starting linting fixes...');

    try {
      await _fixFileNames();
      await _fixCommonPatterns();
      await _removeUnusedCode();

      print('✅ Linting fixes completed successfully!');
      print('📝 Run "flutter analyze" to check remaining issues.');
    } catch (e) {
      print('❌ Error during linting fixes: $e');
    }
  }

  static Future<void> _fixFileNames() async {
    print('📁 Fixing file names...');

    for (final entry in _fileRenames.entries) {
      final oldName = entry.key;
      final newName = entry.value;

      // Find files with old names
      final result = await Process.run('find', ['lib', '-name', oldName]);
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        final files = result.stdout.toString().trim().split('\n');
        for (final file in files) {
          if (file.isNotEmpty) {
            final newPath = file.replaceAll(oldName, newName);
            await File(file).rename(newPath);
            print('  ✅ Renamed: $file -> $newPath');
          }
        }
      }
    }
  }

  static Future<void> _fixCommonPatterns() async {
    print('🔧 Fixing common patterns...');

    final libDir = Directory('lib');
    await _processDirectory(libDir);
  }

  static Future<void> _processDirectory(Directory dir) async {
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _fixFile(entity);
      } else if (entity is Directory) {
        await _processDirectory(entity);
      }
    }
  }

  static Future<void> _fixFile(File file) async {
    try {
      String content = await file.readAsString();
      bool modified = false;

      // Fix empty catch blocks
      content = content.replaceAllMapped(
        RegExp(r'} catch \(e\) {\s*}', multiLine: true),
        (match) {
          modified = true;
          return '} catch (e) {\n      print(\'Error: \$e\');\n    }';
        },
      );

      // Fix unnecessary null-aware operators where receiver can't be null
      content = content.replaceAllMapped(
        RegExp(r'(\w+)\.\?\.(\w+)'),
        (match) {
          final receiver = match.group(1)!;
          final property = match.group(2)!;
          // Only fix if we can determine the receiver is not null
          if (receiver.contains('!') || receiver.contains('required')) {
            modified = true;
            return '$receiver.$property';
          }
          return match.group(0)!;
        },
      );

      // Fix unnecessary null comparisons
      content = content.replaceAllMapped(
        RegExp(r'(\w+) != null && (\w+) != null'),
        (match) {
          final var1 = match.group(1)!;
          final var2 = match.group(2)!;
          if (var1 == var2) {
            modified = true;
            return '$var1 != null';
          }
          return match.group(0)!;
        },
      );

      // Fix unnecessary string interpolations
      content = content.replaceAllMapped(
        RegExp(r'\$\{(\w+)\}'),
        (match) {
          final variable = match.group(1)!;
          // Only fix simple variable interpolations
          if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(variable)) {
            modified = true;
            return '\$$variable';
          }
          return match.group(0)!;
        },
      );

      if (modified) {
        await file.writeAsString(content);
        print('  ✅ Fixed: ${file.path}');
      }
    } catch (e) {
      print('  ⚠️ Error processing ${file.path}: $e');
    }
  }

  static Future<void> _removeUnusedCode() async {
    print('🗑️ Removing unused code...');

    final patterns = [
      // Remove unused private methods
      RegExp(r'void _\w+\([^)]*\) \{[^}]*\}', multiLine: true),
      // Remove unused variables
      RegExp(r'final \w+ \w+ = .*; // unused', multiLine: true),
    ];

    final libDir = Directory('lib');
    await _removePatternsFromDirectory(libDir, patterns);
  }

  static Future<void> _removePatternsFromDirectory(
      Directory dir, List<RegExp> patterns) async {
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _removePatternsFromFile(entity, patterns);
      } else if (entity is Directory) {
        await _removePatternsFromDirectory(entity, patterns);
      }
    }
  }

  static Future<void> _removePatternsFromFile(
      File file, List<RegExp> patterns) async {
    try {
      String content = await file.readAsString();
      bool modified = false;

      for (final pattern in patterns) {
        final matches = pattern.allMatches(content);
        for (final match in matches.toList().reversed) {
          // Only remove if it's clearly unused (has specific comments)
          if (match.group(0)!.contains('// unused') ||
              match.group(0)!.contains('// Add')) {
            content = content.replaceRange(match.start, match.end, '');
            modified = true;
          }
        }
      }

      if (modified) {
        await file.writeAsString(content);
        print('  ✅ Cleaned: ${file.path}');
      }
    } catch (e) {
      print('  ⚠️ Error cleaning ${file.path}: $e');
    }
  }
}

// Run the script
void main(List<String> args) {
  LintingFixer.main(args);
}
