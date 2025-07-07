import 'dart:io';

final debugPatterns = [
  RegExp(r'^\s*print\(.*\);?'),            // print(...)
  RegExp(r'^\s*debugPrint\(.*\);?'),       // debugPrint(...)
  RegExp(r'^\s*logger\.[dwi]\(.*\);?'),    // logger.d(...) / logger.i(...) / logger.w(...)
];

void main() async {
  final dir = Directory('./lib');
  final files = await dir
      .list(recursive: true)
      .where((f) => f.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  print('🔍 Scanning ${files.length} Dart files...\n');

  for (final file in files) {
    final lines = await file.readAsLines();
    bool modified = false;

    final newLines = lines.where((line) {
      for (final pattern in debugPatterns) {
        if (pattern.hasMatch(line)) {
          print('⚠️  ${file.path}: ${line.trim()}');
          modified = true;
          return false; // Remove this line
        }
      }
      return true;
    }).toList();

    if (modified) {
      await file.writeAsString(newLines.join('\n'));
      print('✅ Cleaned: ${file.path}\n');
    }
  }

  print('🎯 Debug print cleanup completed.\n');
}
