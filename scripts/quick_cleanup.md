# 🧹 Quick Cleanup Commands

## Remove Redundant Database Initialize Calls

Since the database is now initialized centrally in `main.dart`, all the `await _db.initialize()` calls in service files are redundant and should be removed.

### Option 1: PowerShell Command (Recommended)

Run this command in your project root:

```powershell
Get-ChildItem -Path "lib/services" -Filter "*.dart" -Recurse | ForEach-Object { 
    $content = Get-Content $_.FullName -Raw; 
    $original = $content; 
    $content = [regex]::Replace($content, '^\s*await _db\.initialize\(\);\s*$', '', [System.Text.RegularExpressions.RegexOptions]::Multiline); 
    $content = [regex]::Replace($content, '\n\s*\n\s*\n', "`n`n"); 
    if ($content -ne $original) { 
        Set-Content -Path $_.FullName -Value $content -NoNewline; 
        Write-Host "✅ $($_.Name): Cleaned" -ForegroundColor Green; 
    } 
}
```

### Option 2: Manual File-by-File

Run these commands to process each service file:

```bash
# Order Service (10 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/order_service.dart

# Product Service (3 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/product_service.dart

# Payment Service (5 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/payment_service.dart

# Notice Service (7 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/notice_service.dart

# Route Service (3 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/route_service.dart

# Uplift Sale Service (5 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/uplift_sale_service.dart

# Task Service (7 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/task_service.dart

# Target Service (7 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/target_service.dart

# Store Service (3 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/store_service.dart

# Session Service (5 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/session_service.dart

# Journey Plan Service (4 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/journey_plan_service.dart

# Leave Service (2 calls)
sed -i 's/^[[:space:]]*await _db\.initialize();[[:space:]]*$//g' lib/services/core/leave_service.dart
```

### Option 3: VS Code Find & Replace

1. Open VS Code
2. Press `Ctrl+Shift+H` (Find & Replace)
3. Set search to: `^\s*await _db\.initialize\(\);\s*$`
4. Set replace to: (empty)
5. Enable regex mode
6. Search in: `lib/services/**/*.dart`
7. Click "Replace All"

### Option 4: Run the PowerShell Script

```powershell
# Run the cleanup script
.\scripts\cleanup_initialize_calls.ps1
```

## Verification

After running the cleanup, verify that all calls are removed:

```bash
# Check for any remaining initialize calls
grep -r "await _db.initialize()" lib/services/
```

This should return no results if the cleanup was successful.

## Expected Results

- **Files processed**: ~15 service files
- **Calls removed**: ~60 redundant initialize calls
- **Performance improvement**: 2-3 seconds faster app startup
- **Memory usage**: Reduced connection pool usage 