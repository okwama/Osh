# Flutter Navigator to GetX Migration Script
# This script automates the migration from Flutter Navigator to GetX navigation

param(
    [string]$ProjectPath = ".",
    [switch]$DryRun = $false,
    [switch]$Backup = $true
)

Write-Host "🚀 Flutter Navigator to GetX Migration Script" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Configuration
$DartFiles = Get-ChildItem -Path $ProjectPath -Recurse -Include "*.dart" | Where-Object { 
    $_.FullName -notlike "*test*" -and 
    $_.FullName -notlike "*generated*" -and
    $_.FullName -notlike "*.g.dart" -and
    $_.FullName -notlike "*.freezed.dart"
}

$MigrationRules = @(
    @{
        Name = "Navigator.push with MaterialPageRoute"
        Pattern = 'Navigator\.push\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)'
        Replacement = 'Get.to(() => $1)'
        Description = "Replace Navigator.push(context, MaterialPageRoute(builder: (_) => Page())) with Get.to(() => Page())"
    },
    @{
        Name = "Navigator.push with MaterialPageRoute (multiline)"
        Pattern = 'Navigator\.push\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)'
        Replacement = 'Get.to(() => $1)'
        Description = "Replace multiline Navigator.push with Get.to"
    },
    @{
        Name = "Navigator.pushReplacement"
        Pattern = 'Navigator\.pushReplacement\s*\(\s*context\s*,\s*MaterialPageRoute\s*\(\s*builder\s*:\s*\([^)]*\)\s*=>\s*([^)]+)\)\s*\)\s*\)'
        Replacement = 'Get.off(() => $1)'
        Description = "Replace Navigator.pushReplacement with Get.off"
    },
    @{
        Name = "Navigator.pushNamed"
        Pattern = 'Navigator\.pushNamed\s*\(\s*context\s*,\s*[\'"]([^\'"]+)[\'"]\s*\)'
        Replacement = 'Get.toNamed(''$1'')'
        Description = "Replace Navigator.pushNamed with Get.toNamed"
    },
    @{
        Name = "Navigator.pushNamedAndRemoveUntil"
        Pattern = 'Navigator\.pushNamedAndRemoveUntil\s*\(\s*context\s*,\s*[\'"]([^\'"]+)[\'"]\s*,\s*([^)]+)\s*\)'
        Replacement = 'Get.offAllNamed(''$1'')'
        Description = "Replace Navigator.pushNamedAndRemoveUntil with Get.offAllNamed"
    },
    @{
        Name = "Navigator.pop"
        Pattern = 'Navigator\.pop\s*\(\s*context\s*\)'
        Replacement = 'Get.back()'
        Description = "Replace Navigator.pop(context) with Get.back()"
    },
    @{
        Name = "Navigator.pop with result"
        Pattern = 'Navigator\.pop\s*\(\s*context\s*,\s*([^)]+)\s*\)'
        Replacement = 'Get.back(result: $1)'
        Description = "Replace Navigator.pop(context, result) with Get.back(result: result)"
    },
    @{
        Name = "Navigator.of(context).pop"
        Pattern = 'Navigator\.of\s*\(\s*context\s*\)\.pop\s*\(\s*\)'
        Replacement = 'Get.back()'
        Description = "Replace Navigator.of(context).pop() with Get.back()"
    },
    @{
        Name = "Navigator.of(context).pop with result"
        Pattern = 'Navigator\.of\s*\(\s*context\s*\)\.pop\s*\(\s*([^)]+)\s*\)'
        Replacement = 'Get.back(result: $1)'
        Description = "Replace Navigator.of(context).pop(result) with Get.back(result: result)"
    },
    @{
        Name = "Navigator.canPop"
        Pattern = 'Navigator\.canPop\s*\(\s*context\s*\)'
        Replacement = 'Get.canPop()'
        Description = "Replace Navigator.canPop(context) with Get.canPop()"
    }
)

# Import detection patterns
$ImportPatterns = @(
    @{
        Name = "GetX Import"
        Pattern = 'import\s+[\'"]package:get/get\.dart[\'"];?'
        Description = "Check for GetX import"
    }
)

# Function to backup file
function Backup-File {
    param([string]$FilePath)
    if ($Backup) {
        $BackupPath = "$FilePath.backup"
        Copy-Item -Path $FilePath -Destination $BackupPath -Force
        Write-Host "  📦 Backed up to: $BackupPath" -ForegroundColor Yellow
    }
}

# Function to add GetX import
function Add-GetXImport {
    param([string]$FilePath, [string]$Content)
    
    # Check if GetX import already exists
    if ($Content -match 'import\s+[\'"]package:get/get\.dart[\'"];?') {
        return $Content
    }
    
    # Find the last import statement
    $Lines = $Content -split "`n"
    $LastImportIndex = -1
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^import\s+') {
            $LastImportIndex = $i
        }
    }
    
    if ($LastImportIndex -ge 0) {
        # Insert GetX import after the last import
        $Lines = $Lines[0..$LastImportIndex] + "import 'package:get/get.dart';" + $Lines[($LastImportIndex + 1)..($Lines.Count - 1)]
        $Content = $Lines -join "`n"
        Write-Host "  ➕ Added GetX import" -ForegroundColor Green
    } else {
        # Add at the beginning if no imports found
        $Content = "import 'package:get/get.dart';`n" + $Content
        Write-Host "  ➕ Added GetX import at beginning" -ForegroundColor Green
    }
    
    return $Content
}

# Function to process a single file
function Process-File {
    param([string]$FilePath)
    
    Write-Host "`n📄 Processing: $FilePath" -ForegroundColor Cyan
    
    $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $OriginalContent = $Content
    $Changes = @()
    
    # Check if file needs GetX import
    $NeedsGetXImport = $false
    
    # Apply migration rules
    foreach ($Rule in $MigrationRules) {
        $Matches = [regex]::Matches($Content, $Rule.Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        if ($Matches.Count -gt 0) {
            $NeedsGetXImport = $true
            $Changes += "  ✅ $($Rule.Name): $($Matches.Count) replacements"
            
            if (-not $DryRun) {
                $Content = [regex]::Replace($Content, $Rule.Pattern, $Rule.Replacement, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            }
        }
    }
    
    # Add GetX import if needed
    if ($NeedsGetXImport -and -not $DryRun) {
        $Content = Add-GetXImport -FilePath $FilePath -Content $Content
    }
    
    # Show changes
    if ($Changes.Count -gt 0) {
        Write-Host "  📝 Changes:" -ForegroundColor Yellow
        foreach ($Change in $Changes) {
            Write-Host $Change -ForegroundColor White
        }
        
        if (-not $DryRun) {
            # Backup file
            Backup-File -FilePath $FilePath
            
            # Write changes
            Set-Content -Path $FilePath -Value $Content -Encoding UTF8
            Write-Host "  💾 File updated" -ForegroundColor Green
        } else {
            Write-Host "  🔍 Dry run - no changes made" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ No changes needed" -ForegroundColor Gray
    }
}

# Main execution
$TotalFiles = $DartFiles.Count
$ProcessedFiles = 0
$ChangedFiles = 0

Write-Host "`n🔍 Found $TotalFiles Dart files to process" -ForegroundColor Blue

foreach ($File in $DartFiles) {
    $ProcessedFiles++
    Write-Progress -Activity "Migrating Navigation" -Status "Processing $($File.Name)" -PercentComplete (($ProcessedFiles / $TotalFiles) * 100)
    
    try {
        Process-File -FilePath $File.FullName
        $ChangedFiles++
    } catch {
        Write-Host "  ❌ Error processing $($File.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Progress -Activity "Migrating Navigation" -Completed

# Summary
Write-Host "`n🎉 Migration Complete!" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green
Write-Host "📊 Summary:" -ForegroundColor White
Write-Host "  • Total files processed: $ProcessedFiles" -ForegroundColor White
Write-Host "  • Files with changes: $ChangedFiles" -ForegroundColor White
Write-Host "  • Dry run mode: $DryRun" -ForegroundColor White
Write-Host "  • Backup created: $Backup" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n💡 To apply changes, run without -DryRun flag" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Migration completed successfully!" -ForegroundColor Green
    Write-Host "📝 Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review the changes" -ForegroundColor White
    Write-Host "  2. Test the application" -ForegroundColor White
    Write-Host "  3. Fix any compilation errors" -ForegroundColor White
    Write-Host "  4. Remove backup files if everything works" -ForegroundColor White
}

Write-Host "`n🔧 Migration Rules Applied:" -ForegroundColor Blue
foreach ($Rule in $MigrationRules) {
    Write-Host "  • $($Rule.Description)" -ForegroundColor White
} 