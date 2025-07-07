# PowerShell script to fix Android package structure
# Run this script from the project root directory

Write-Host "Fixing Android package structure..." -ForegroundColor Green

# Function to update MainActivity.kt
function Update-MainActivityKt {
    $mainActivityPath = "android/app/src/main/kotlin/com/cit/woosh/MainActivity.kt"
    
    if (Test-Path $mainActivityPath) {
        try {
            $content = Get-Content -Path $mainActivityPath -Raw -Encoding UTF8
            $originalContent = $content
            
            # Update package name
            $content = $content -replace "package com\.cit\.wooshs", "package com.cit.glamourqueen"
            
            if ($content -ne $originalContent) {
                Set-Content -Path $mainActivityPath -Value $content -Encoding UTF8
                Write-Host "Updated: $mainActivityPath" -ForegroundColor Yellow
                return $true
            }
        }
        catch {
            Write-Host "Error updating MainActivity.kt : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    return $false
}

# Function to create new directory structure and move files
function Move-AndroidFiles {
    $oldDir = "android/app/src/main/kotlin/com/cit/woosh"
    $newDir = "android/app/src/main/kotlin/com/cit/glamourqueen"
    
    if (Test-Path $oldDir) {
        try {
            # Create new directory if it doesn't exist
            if (!(Test-Path $newDir)) {
                New-Item -ItemType Directory -Path $newDir -Force | Out-Null
                Write-Host "Created directory: $newDir" -ForegroundColor Yellow
            }
            
            # Move all files from old directory to new directory
            $files = Get-ChildItem -Path $oldDir -File
            foreach ($file in $files) {
                $newPath = Join-Path $newDir $file.Name
                Move-Item -Path $file.FullName -Destination $newPath -Force
                Write-Host "Moved: $($file.Name) to $newPath" -ForegroundColor Yellow
            }
            
            # Remove old directory if empty
            if ((Get-ChildItem -Path $oldDir -Recurse | Measure-Object).Count -eq 0) {
                Remove-Item -Path $oldDir -Force
                Write-Host "Removed empty directory: $oldDir" -ForegroundColor Yellow
            }
            
            return $true
        }
        catch {
            Write-Host "Error moving Android files : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    return $false
}

# Function to update build.gradle files
function Update-BuildGradle {
    $buildGradlePath = "android/app/build.gradle"
    
    if (Test-Path $buildGradlePath) {
        try {
            $content = Get-Content -Path $buildGradlePath -Raw -Encoding UTF8
            $originalContent = $content
            
            # Update applicationId if it exists
            $content = $content -replace "applicationId `"com\.cit\.woosh`"", "applicationId `"com.cit.glamourqueen`""
            $content = $content -replace "applicationId `"com\.cit\.wooshs`"", "applicationId `"com.cit.glamourqueen`""
            
            if ($content -ne $originalContent) {
                Set-Content -Path $buildGradlePath -Value $content -Encoding UTF8
                Write-Host "Updated: $buildGradlePath" -ForegroundColor Yellow
                return $true
            }
        }
        catch {
            Write-Host "Error updating build.gradle : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    return $false
}

# Main execution
$updatedFiles = 0

# Update MainActivity.kt
if (Update-MainActivityKt) {
    $updatedFiles++
}

# Move Android files to new package structure
if (Move-AndroidFiles) {
    $updatedFiles++
}

# Update build.gradle
if (Update-BuildGradle) {
    $updatedFiles++
}

Write-Host "`nAndroid package structure fix completed!" -ForegroundColor Green
Write-Host "Files updated: $updatedFiles" -ForegroundColor Cyan

if ($updatedFiles -gt 0) {
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Run 'flutter clean'" -ForegroundColor White
    Write-Host "2. Run 'flutter pub get'" -ForegroundColor White
    Write-Host "3. Test your Android build" -ForegroundColor White
    Write-Host "4. Update any remaining references manually if needed" -ForegroundColor White
} else {
    Write-Host "`nNo files were updated. Android package structure may already be correct." -ForegroundColor Green
}

Write-Host "`nNew Android package structure:" -ForegroundColor Cyan
Write-Host "Package: com.cit.glamourqueen" -ForegroundColor White
Write-Host "Directory: android/app/src/main/kotlin/com/cit/glamourqueen/" -ForegroundColor White 