# Code Cleanup Script for WOOSH App
param([switch]$DryRun = $false, [switch]$Backup = $true)

Write-Host "🧹 WOOSH App Code Cleanup Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Find all Dart files
$files = Get-ChildItem -Recurse -Include "*.dart" | Where-Object { 
    $_.FullName -notlike "*test*" -and 
    $_.FullName -notlike "*generated*" -and
    $_.FullName -notlike "*.g.dart" -and
    $_.FullName -notlike "*.freezed.dart"
}

$totalChanges = 0
$processedFiles = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $fileChanges = 0
    
    Write-Host "📄 Processing: $($file.Name)" -ForegroundColor Cyan
    
    # 1. Remove unused variables (common patterns)
    $unusedVariablePatterns = @(
        @{
            Pattern = 'warning - The value of the local variable ''(\w+)'' isn''t used'
            Replacement = '// Removed unused variable: $1'
            Description = "Remove unused local variables"
        },
        @{
            Pattern = 'final (\w+) = [^;]+;.*?// Removed unused variable: \1'
            Replacement = ''
            Description = "Remove unused variable declarations"
        }
    )
    
    # 2. Fix empty catch blocks
    $emptyCatchPatterns = @(
        @{
            Pattern = '} catch \(e\) {\s*}'
            Replacement = '} catch (e) {
        // TODO: Add proper error handling
        print(''Error: $e'');
      }'
            Description = "Add basic error handling to empty catch blocks"
        },
        @{
            Pattern = '} catch \(e\) {\s*// TODO: Add proper error handling\s*print\(''Error: \$e''\);\s*}'
            Replacement = '} catch (e) {
        // TODO: Add proper error handling
        print(''Error: $e'');
      }'
            Description = "Standardize error handling"
        }
    )
    
    # 3. Fix null-aware operator warnings
    $nullAwarePatterns = @(
        @{
            Pattern = '(\w+)\.\?\.(\w+)'
            Replacement = '$1.$2'
            Description = "Remove unnecessary null-aware operators"
        }
    )
    
    # Apply patterns
    foreach ($pattern in $unusedVariablePatterns + $emptyCatchPatterns + $nullAwarePatterns) {
        $newContent = $content -replace $pattern.Pattern, $pattern.Replacement
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔧 Applied: $($pattern.Description)" -ForegroundColor Yellow
        }
    }
    
    if ($fileChanges -gt 0) {
        $totalChanges += $fileChanges
        Write-Host "  ✅ Total changes: $fileChanges" -ForegroundColor Green
        
        if (-not $DryRun) {
            if ($Backup) {
                $backupPath = "$($file.FullName).backup"
                Copy-Item $file.FullName $backupPath
                Write-Host "  📦 Backup created: $backupPath" -ForegroundColor Gray
            }
            
            Set-Content $file.FullName $content -Encoding UTF8
            Write-Host "  💾 File updated" -ForegroundColor Green
        } else {
            Write-Host "  🔍 Dry run - no changes applied" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ No changes needed" -ForegroundColor Gray
    }
}

Write-Host "`n🎉 Cleanup Summary" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green
Write-Host "📊 Files processed: $processedFiles" -ForegroundColor White
Write-Host "📊 Total changes: $totalChanges" -ForegroundColor White
Write-Host "📊 Dry run mode: $DryRun" -ForegroundColor White
Write-Host "📊 Backup created: $Backup" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n💡 To apply changes, run: .\scripts\cleanup_code.ps1" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Cleanup completed successfully!" -ForegroundColor Green
} 