@echo off
echo 🧹 Starting cleanup of redundant database initialize calls...
echo.

set totalFilesProcessed=0
set totalCallsRemoved=0

REM Process lib/services/core directory
if exist "lib\services\core" (
    echo 📁 Processing directory: lib/services/core
    
    REM Use PowerShell to process the files
    powershell -Command "& {
        $files = Get-ChildItem -Path 'lib\services\core' -Filter '*.dart' -Recurse
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw
            $originalContent = $content
            
            # Remove await _db.initialize(); lines
            $pattern = '^\s*await _db\.initialize\(\);\s*$'
            $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            if ($matches.Count -gt 0) {
                $content = [regex]::Replace($content, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                
                # Clean up empty lines
                $content = [regex]::Replace($content, '\n\s*\n\s*\n', \"`n`n\")
                $content = [regex]::Replace($content, '(\s*try\s*\{\s*)`n\s*`n', '$1`n')
                $content = [regex]::Replace($content, '`n\s*`n(\s*catch\s*\()', \"`n$1\")
                
                if ($content -ne $originalContent) {
                    Set-Content -Path $file.FullName -Value $content -NoNewline
                    Write-Host \"  ✅ $($file.Name): $($matches.Count) calls removed\" -ForegroundColor Green
                    $script:totalFilesProcessed++
                    $script:totalCallsRemoved += $matches.Count
                }
            }
        }
    }"
)

REM Process lib/services/core/reports directory
if exist "lib\services\core\reports" (
    echo 📁 Processing directory: lib/services/core/reports
    
    powershell -Command "& {
        $files = Get-ChildItem -Path 'lib\services\core\reports' -Filter '*.dart' -Recurse
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw
            $originalContent = $content
            
            # Remove await _db.initialize(); lines
            $pattern = '^\s*await _db\.initialize\(\);\s*$'
            $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            if ($matches.Count -gt 0) {
                $content = [regex]::Replace($content, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                
                # Clean up empty lines
                $content = [regex]::Replace($content, '\n\s*\n\s*\n', \"`n`n\")
                $content = [regex]::Replace($content, '(\s*try\s*\{\s*)`n\s*`n', '$1`n')
                $content = [regex]::Replace($content, '`n\s*`n(\s*catch\s*\()', \"`n$1\")
                
                if ($content -ne $originalContent) {
                    Set-Content -Path $file.FullName -Value $content -NoNewline
                    Write-Host \"  ✅ $($file.Name): $($matches.Count) calls removed\" -ForegroundColor Green
                    $script:totalFilesProcessed++
                    $script:totalCallsRemoved += $matches.Count
                }
            }
        }
    }"
)

echo.
echo 📊 Cleanup completed!
echo 💡 Database initialization is now centralized in main.dart
echo.
pause 