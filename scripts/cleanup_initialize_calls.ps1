# PowerShell script to remove redundant await _db.initialize() calls
# Since database is now initialized centrally in main.dart

Write-Host "🧹 Starting cleanup of redundant database initialize calls..." -ForegroundColor Green
Write-Host ""

$totalFilesProcessed = 0
$totalCallsRemoved = 0
$processedFiles = @()

# Define service directories to process
$serviceDirs = @(
    "lib/services/core",
    "lib/services/core/reports"
)

foreach ($dir in $serviceDirs) {
    if (Test-Path $dir) {
        Write-Host "📁 Processing directory: $dir" -ForegroundColor Yellow
        
        # Get all .dart files in the directory
        $files = Get-ChildItem -Path $dir -Filter "*.dart" -Recurse
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw
            $originalContent = $content
            
            # Count how many initialize calls exist
            $pattern = '^\s*await _db\.initialize\(\);\s*$'
            $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            if ($matches.Count -gt 0) {
                # Remove the initialize calls
                $content = [regex]::Replace($content, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                
                # Clean up empty lines
                $content = [regex]::Replace($content, '\n\s*\n\s*\n', "`n`n")
                $content = [regex]::Replace($content, '(\s*try\s*\{\s*)`n\s*`n', '$1`n')
                $content = [regex]::Replace($content, '`n\s*`n(\s*catch\s*\()', "`n$1")
                
                # Write back to file if content changed
                if ($content -ne $originalContent) {
                    Set-Content -Path $file.FullName -Value $content -NoNewline
                    $totalFilesProcessed++
                    $totalCallsRemoved += $matches.Count
                    $processedFiles += $file.FullName
                    Write-Host "  ✅ $($file.Name): $($matches.Count) calls removed" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "⚠️ Directory not found: $dir" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Cleanup Summary:" -ForegroundColor Cyan
Write-Host "  📁 Files processed: $totalFilesProcessed" -ForegroundColor White
Write-Host "  🗑️ Total calls removed: $totalCallsRemoved" -ForegroundColor White
Write-Host "  📋 Files modified: $($processedFiles.Count)" -ForegroundColor White

if ($processedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "📝 Modified files:" -ForegroundColor Cyan
    foreach ($file in $processedFiles) {
        Write-Host "  • $file" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "✅ Cleanup completed successfully!" -ForegroundColor Green
Write-Host "💡 Database initialization is now centralized in main.dart" -ForegroundColor Yellow 