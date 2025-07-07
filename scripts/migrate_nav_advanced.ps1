# Advanced Navigator to GetX Migration Script
param([switch]$DryRun = $false, [switch]$Backup = $true)

Write-Host "🚀 Advanced Navigator to GetX Migration" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

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
    
    # Check if file contains Navigator usage
    if ($content -match 'Navigator\.') {
        $processedFiles++
        
        # Add GetX import if needed
        if ($content -notmatch 'import.*get/get\.dart') {
            # Find the last import statement
            $lines = $content -split "`n"
            $lastImportIndex = -1
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^import\s+') {
                    $lastImportIndex = $i
                }
            }
            
            if ($lastImportIndex -ge 0) {
                $lines = $lines[0..$lastImportIndex] + "import 'package:get/get.dart';" + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
                $content = $lines -join "`n"
                $fileChanges++
                Write-Host "  ➕ Added GetX import" -ForegroundColor Green
            }
        }
        
        # Complex Navigator.push replacement (handles multiline)
        $pushPattern = @'
Navigator\.push\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)
'@
        $newContent = $content -replace $pushPattern, 'Get.to(() => $1)'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.push with Get.to" -ForegroundColor Yellow
        }
        
        # Navigator.pushReplacement
        $pushReplacementPattern = @'
Navigator\.pushReplacement\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)
'@
        $newContent = $content -replace $pushReplacementPattern, 'Get.off(() => $1)'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.pushReplacement with Get.off" -ForegroundColor Yellow
        }
        
        # Navigator.pushNamed
        $newContent = $content -replace 'Navigator\.pushNamed\s*\(\s*context\s*,\s*[\'"]([^\'"]+)[\'"]\s*\)', 'Get.toNamed(''$1'')'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.pushNamed with Get.toNamed" -ForegroundColor Yellow
        }
        
        # Navigator.pushNamedAndRemoveUntil
        $newContent = $content -replace 'Navigator\.pushNamedAndRemoveUntil\s*\(\s*context\s*,\s*[\'"]([^\'"]+)[\'"]\s*,\s*([^)]+)\s*\)', 'Get.offAllNamed(''$1'')'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.pushNamedAndRemoveUntil with Get.offAllNamed" -ForegroundColor Yellow
        }
        
        # Navigator.pop(context)
        $newContent = $content -replace 'Navigator\.pop\s*\(\s*context\s*\)', 'Get.back()'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.pop(context) with Get.back()" -ForegroundColor Yellow
        }
        
        # Navigator.pop(context, result)
        $newContent = $content -replace 'Navigator\.pop\s*\(\s*context\s*,\s*([^)]+)\s*\)', 'Get.back(result: $1)'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.pop(context, result) with Get.back(result: result)" -ForegroundColor Yellow
        }
        
        # Navigator.of(context).pop()
        $newContent = $content -replace 'Navigator\.of\s*\(\s*context\s*\)\.pop\s*\(\s*\)', 'Get.back()'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.of(context).pop() with Get.back()" -ForegroundColor Yellow
        }
        
        # Navigator.of(context).pop(result)
        $newContent = $content -replace 'Navigator\.of\s*\(\s*context\s*\)\.pop\s*\(\s*([^)]+)\s*\)', 'Get.back(result: $1)'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.of(context).pop(result) with Get.back(result: result)" -ForegroundColor Yellow
        }
        
        # Navigator.canPop(context)
        $newContent = $content -replace 'Navigator\.canPop\s*\(\s*context\s*\)', 'Get.canPop()'
        if ($newContent -ne $content) {
            $content = $newContent
            $fileChanges++
            Write-Host "  🔄 Replaced Navigator.canPop(context) with Get.canPop()" -ForegroundColor Yellow
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
}

Write-Host "`n🎉 Migration Summary" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "📊 Files processed: $processedFiles" -ForegroundColor White
Write-Host "📊 Total changes: $totalChanges" -ForegroundColor White
Write-Host "📊 Dry run mode: $DryRun" -ForegroundColor White
Write-Host "📊 Backup created: $Backup" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n💡 To apply changes, run: .\scripts\migrate_nav_advanced.ps1" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Migration completed successfully!" -ForegroundColor Green
    Write-Host "📝 Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run 'flutter analyze' to check for errors" -ForegroundColor White
    Write-Host "  2. Test the application thoroughly" -ForegroundColor White
    Write-Host "  3. Fix any compilation issues" -ForegroundColor White
    Write-Host "  4. Remove .backup files if everything works" -ForegroundColor White
} 