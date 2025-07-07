# PowerShell script to update import statements from 'glamour_queen' to 'woosh'

Write-Host "Updating import statements from 'glamour_queen' to 'woosh'..." -ForegroundColor Green

$updatedFiles = 0
$totalFiles = 0

# Function to update imports in a single file
function Update-ImportsInFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    
    # Update package imports
    $content = $content -replace "import 'package:glamour_queen/", "import 'package:woosh/"
    
    # Update relative imports
    $content = $content -replace "import '../../glamour_queen/", "import '../../woosh/"
    $content = $content -replace "import '../glamour_queen/", "import '../woosh/"
    $content = $content -replace "import 'glamour_queen/", "import 'woosh/"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $FilePath -Value $content
        Write-Host "Updated: $FilePath" -ForegroundColor Yellow
        return $true
    }
    
    return $false
}

# Update test files
$testFiles = @(
    "test/widget_test.dart",
    "test/error_handling_test.dart",
    "test/country_tax_labels_test.dart",
    "test/country_currency_labels_test.dart",
    "test/api_service_test.dart"
)

foreach ($file in $testFiles) {
    $totalFiles++
    if (Update-ImportsInFile $file) {
        $updatedFiles++
    }
}

# Find and update all Dart files in lib directory
Write-Host "Scanning Dart files to update..." -ForegroundColor Cyan
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object { $_.FullName }

foreach ($file in $dartFiles) {
    $totalFiles++
    if (Update-ImportsInFile $file) {
        $updatedFiles++
    }
}

Write-Host ""
Write-Host "Update completed!" -ForegroundColor Green
Write-Host "Files processed: $totalFiles"
Write-Host "Files updated: $updatedFiles" -ForegroundColor Yellow

if ($updatedFiles -gt 0) {
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run 'flutter clean'"
    Write-Host "2. Run 'flutter pub get'"
    Write-Host "3. Test your application thoroughly"
} else {
    Write-Host ""
    Write-Host "No files were updated. All may already be correct." -ForegroundColor Green
} 