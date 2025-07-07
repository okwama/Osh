# Simple Navigator to GetX Migration Script
param([switch]$DryRun = $false)

Write-Host "🚀 Navigator to GetX Migration" -ForegroundColor Green

# Find all Dart files
$files = Get-ChildItem -Recurse -Include "*.dart" | Where-Object { 
    $_.FullName -notlike "*test*" -and 
    $_.FullName -notlike "*generated*" -and
    $_.FullName -notlike "*.g.dart"
}

$totalChanges = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileChanges = 0
    
    # Add GetX import if needed
    if ($content -match 'Navigator\.' -and $content -notmatch 'import.*get/get\.dart') {
        $content = $content -replace 'import.*flutter/material\.dart.*;', '$&`nimport ''package:get/get.dart'';'
        $fileChanges++
    }
    
    # Replace Navigator.push with Get.to
    $content = $content -replace 'Navigator\.push\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)', 'Get.to(() => $1)'
    if ($content -ne $originalContent) { $fileChanges++; $originalContent = $content }
    
    # Replace Navigator.pushReplacement with Get.off
    $content = $content -replace 'Navigator\.pushReplacement\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)', 'Get.off(() => $1)'
    if ($content -ne $originalContent) { $fileChanges++; $originalContent = $content }
    
    # Replace Navigator.pop(context) with Get.back()
    $content = $content -replace 'Navigator\.pop\s*\(\s*context\s*\)', 'Get.back()'
    if ($content -ne $originalContent) { $fileChanges++; $originalContent = $content }
    
    # Replace Navigator.pop(context, result) with Get.back(result: result)
    $content = $content -replace 'Navigator\.pop\s*\(\s*context\s*,\s*([^)]+)\s*\)', 'Get.back(result: $1)'
    if ($content -ne $originalContent) { $fileChanges++; $originalContent = $content }
    
    # Replace Navigator.of(context).pop() with Get.back()
    $content = $content -replace 'Navigator\.of\s*\(\s*context\s*\)\.pop\s*\(\s*\)', 'Get.back()'
    if ($content -ne $originalContent) { $fileChanges++; $originalContent = $content }
    
    # Replace Navigator.of(context).pop(result) with Get.back(result: result)
    $content = $content -replace 'Navigator\.of\s*\(\s*context\s*\)\.pop\s*\(\s*([^)]+)\s*\)', 'Get.back(result: $1)'
    if ($content -ne $originalContent) { $fileChanges++; $originalContent = $content }
    
    if ($fileChanges -gt 0) {
        Write-Host "📄 $($file.Name): $fileChanges changes" -ForegroundColor Yellow
        $totalChanges += $fileChanges
        
        if (-not $DryRun) {
            # Backup file
            Copy-Item $file.FullName "$($file.FullName).backup"
            Set-Content $file.FullName $content
        }
    }
}

Write-Host "`n✅ Migration complete! $totalChanges total changes" -ForegroundColor Green
if ($DryRun) {
    Write-Host "💡 Run without -DryRun to apply changes" -ForegroundColor Yellow
} 