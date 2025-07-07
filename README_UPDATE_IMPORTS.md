# Import Update Scripts for Glamour Queen

This directory contains scripts to update all imports from "woosh" to "glamour_queen" throughout your Flutter project.

## Available Scripts

### 1. PowerShell Script (Windows)
- **File**: `update_imports.ps1`
- **Usage**: Run in PowerShell from the project root directory

### 2. Bash Script (Cross-platform)
- **File**: `update_imports.sh`
- **Usage**: Run in bash/terminal from the project root directory

## What the Scripts Do

The scripts will automatically update:

1. **Package imports** in all Dart files:
   - `import 'package:woosh/...'` → `import 'package:glamour_queen/...'`

2. **Relative imports**:
   - `import '../woosh/...'` → `import '../glamour_queen/...'`
   - `import '../../woosh/...'` → `import '../../glamour_queen/...'`

3. **pubspec.yaml**:
   - Package name: `woosh` → `glamour_queen`
   - Description update

4. **Test files**:
   - `test/widget_test.dart` import updates

5. **Android files** (if they exist):
   - Package names in MainActivity files

## How to Run

### Windows (PowerShell)
```powershell
# Navigate to your project root
cd "C:\Users\Benjamin Okwama\StudioProjects\Moonsun\glamour_queen"

# Run the script
.\update_imports.ps1
```

### Cross-platform (Bash)
```bash
# Navigate to your project root
cd /path/to/glamour_queen

# Make script executable (first time only)
chmod +x update_imports.sh

# Run the script
./update_imports.sh
```

## After Running the Script

1. **Clean the project**:
   ```bash
   flutter clean
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Check for any remaining references**:
   - Search for "woosh" in your codebase
   - Update any remaining references manually

4. **Test your application**:
   - Run the app to ensure everything works
   - Check for any import errors

## Safety Features

- **Backup creation**: Scripts create backups before modifying files
- **Change detection**: Only files that actually need updates are modified
- **Error handling**: Scripts handle errors gracefully and continue processing
- **Progress reporting**: Shows which files are being updated

## Manual Verification

After running the script, you can verify the changes:

```bash
# Search for any remaining "woosh" references
grep -r "woosh" lib/ test/ --include="*.dart"

# Search for any remaining "package:woosh" imports
grep -r "package:woosh" lib/ test/ --include="*.dart"
```

## Troubleshooting

If you encounter issues:

1. **Check file permissions**: Ensure you have write access to all project files
2. **Verify script location**: Make sure you're running the script from the project root
3. **Check for file locks**: Close any IDEs or editors that might have files open
4. **Manual backup**: Consider creating a git commit before running the script

## Files Modified

The scripts will update:
- All `.dart` files in `lib/` and `test/` directories
- `pubspec.yaml`
- `test/widget_test.dart`
- Android MainActivity files (if they exist)

## Notes

- The scripts are designed to be safe and non-destructive
- They only modify files that actually contain "woosh" references
- All changes are logged to the console
- Backup files are automatically cleaned up after successful updates 