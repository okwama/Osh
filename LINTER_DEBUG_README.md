# Flutter Linter Debug Script

This script helps you debug and fix linter errors in your Flutter application. It provides comprehensive analysis, suggestions, and quick fix commands.

## Files Created

- `debug_linter.ps1` - Main PowerShell script (Windows)
- `debug_linter.bat` - Batch file wrapper for easy execution (Windows)
- `debug_linter.sh` - Shell script for Linux/macOS
- `LINTER_DEBUG_README.md` - This documentation

## Usage

### Windows (Recommended)
```bash
# Double-click the batch file or run:
debug_linter.bat

# Or run PowerShell directly:
powershell -ExecutionPolicy Bypass -File "debug_linter.ps1"
```

### Linux/macOS
```bash
# Make executable (first time only)
chmod +x debug_linter.sh

# Run the script
./debug_linter.sh
```

### Command Line Options

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-p, --path` | Path to Flutter project (default: current directory) | `-p "C:\myproject"` |
| `-f, --file` | Analyze only a specific file | `-f "lib/main.dart"` |
| `-v, --verbose` | Show detailed issue list | `-v` |
| `-h, --help` | Show help message | `-h` |

## What the Script Does

### 1. Environment Checks
- ✅ Verifies Flutter installation
- ✅ Checks project structure
- ✅ Validates analysis_options.yaml

### 2. Analysis
- 🔍 Runs `flutter analyze`
- 📊 Categorizes issues by severity and type
- 📁 Groups issues by file and rule

### 3. Reporting
- 📋 Shows summary statistics
- 📄 Lists file-specific issues
- 🔧 Provides suggested fixes
- ⚡ Generates quick fix commands

### 4. Common Issue Fixes

The script recognizes and suggests fixes for common issues:

| Issue | Description | Fix |
|-------|-------------|-----|
| `avoid_print` | Using print() instead of proper logging | Use `debugPrint()` or logger package |
| `unused_import` | Unused import statements | Remove the import |
| `unused_field` | Unused class fields | Use the field or prefix with `_` |
| `prefer_const_constructors` | Non-const constructors | Add `const` keyword |
| `use_build_context_synchronously` | Using BuildContext after async | Check `mounted` before use |
| `prefer_single_quotes` | Double quotes instead of single | Use single quotes |

## Quick Fix Commands

The script provides these commands to fix issues:

```bash
# Automatic fixes
dart fix --apply
flutter fix --apply

# Format code
dart format .
flutter format .

# Clean and rebuild
flutter clean
flutter pub get
flutter analyze
```

## Example Output

```
Starting Flutter Linter Debug...
Project path: C:\Users\...\glamour_queen

============================================================
FLUTTER INSTALLATION CHECK
============================================================
SUCCESS: Flutter 3.16.5 • channel stable • https://github.com/flutter/flutter.git

============================================================
PROJECT STRUCTURE CHECK
============================================================
INFO: Project path: C:\Users\...\glamour_queen
SUCCESS: pubspec.yaml found
SUCCESS: Found 45 Dart files in lib/
SUCCESS: analysis_options.yaml found

============================================================
LINTER ERROR SUMMARY
============================================================
Total Issues: 12
  ERRORS: 2
  WARNINGS: 5
  HINTS: 3
  INFO: 2

Issues by Rule:
  avoid_print: 3 issues
  unused_import: 2 issues
  prefer_const_constructors: 4 issues
  use_build_context_synchronously: 3 issues

============================================================
SUGGESTED FIXES
============================================================
FIX: avoid_print (3 issues)
   Description: Replace print() with proper logging
   Fix: Use debugPrint() or a logging framework like logger package
   Example: debugPrint("Debug message");

============================================================
QUICK FIX COMMANDS
============================================================
Run automatic fixes:
   dart fix --apply
   flutter fix --apply

Format code:
   dart format .
   flutter format .
```

## Troubleshooting

### PowerShell Execution Policy (Windows)
If you get execution policy errors, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Flutter Not Found
Make sure Flutter is installed and added to your PATH:
```bash
flutter doctor
```

### Analysis Timeout
For large projects, the analysis might timeout. The script has a 5-minute timeout by default.

### Permission Issues (Linux/macOS)
If you get permission denied errors:
```bash
chmod +x debug_linter.sh
```

## Platform-Specific Notes

### Windows
- Uses PowerShell for rich formatting and color output
- Includes batch file wrapper for easy execution
- Handles Windows-specific path separators

### Linux/macOS
- Uses bash with ANSI color codes
- Handles Unix-style paths
- Includes proper cleanup of temporary files

## Customization

You can modify the script to:
- Add more issue types and fixes
- Change timeout values
- Add custom analysis rules
- Integrate with your CI/CD pipeline

## Performance Tips

1. **Run on specific files** when debugging individual components
2. **Use verbose mode** for detailed analysis
3. **Run automatic fixes** first before manual fixes
4. **Clean and rebuild** after making changes

## Integration with IDEs

You can integrate this script with your IDE:
- **VS Code**: Add to tasks.json
- **Android Studio**: Add as external tool
- **Git Hooks**: Run before commits

## Contributing

Feel free to enhance the script by:
- Adding more issue types
- Improving error parsing
- Adding more fix suggestions
- Supporting more platforms 