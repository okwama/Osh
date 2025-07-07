# Flutter Linter Debug Script for Windows
# This script helps debug and fix linter errors in Flutter applications.

param(
    [string]$ProjectPath = ".",
    [string]$SpecificFile = "",
    [switch]$Verbose
)

function Write-Header {
    param([string]$Title)
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "="*60 -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Blue
}

function Test-FlutterInstallation {
    Write-Header "FLUTTER INSTALLATION CHECK"
    
    try {
        $flutterVersion = flutter --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $versionLine = ($flutterVersion -split "`n")[0]
            Write-Success $versionLine
            return $true
        } else {
            Write-Error "Flutter not found or not working properly"
            return $false
        }
    } catch {
        Write-Error "Flutter not available. Please install Flutter first."
        return $false
    }
}

function Test-ProjectStructure {
    Write-Header "PROJECT STRUCTURE CHECK"
    
    $projectPath = Resolve-Path $ProjectPath
    Write-Info "Project path: $projectPath"
    
    # Check pubspec.yaml
    if (Test-Path "$projectPath\pubspec.yaml") {
        Write-Success "pubspec.yaml found"
    } else {
        Write-Error "pubspec.yaml not found"
    }
    
    # Check lib directory
    if (Test-Path "$projectPath\lib") {
        $dartFiles = Get-ChildItem -Path "$projectPath\lib" -Recurse -Filter "*.dart" | Measure-Object
        Write-Success "Found $($dartFiles.Count) Dart files in lib/"
    } else {
        Write-Error "lib/ directory not found"
    }
    
    # Check analysis_options.yaml
    if (Test-Path "$projectPath\analysis_options.yaml") {
        Write-Success "analysis_options.yaml found"
    } else {
        Write-Warning "analysis_options.yaml not found"
    }
}

function Test-AnalysisOptions {
    Write-Header "ANALYSIS OPTIONS CHECK"
    
    $analysisFile = "$ProjectPath\analysis_options.yaml"
    if (Test-Path $analysisFile) {
        $content = Get-Content $analysisFile -Raw
        
        $issues = @()
        if ($content -notmatch "include: package:flutter_lints/flutter.yaml") {
            $issues += "Missing Flutter lints include"
        }
        
        if ($content -notmatch "analyzer:") {
            $issues += "Missing analyzer configuration"
        }
        
        if ($issues.Count -eq 0) {
            Write-Success "analysis_options.yaml looks good"
        } else {
            Write-Warning "Potential issues in analysis_options.yaml:"
            foreach ($issue in $issues) {
                Write-Host "   - $issue" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Warning "analysis_options.yaml not found"
    }
}

function Run-FlutterAnalyze {
    Write-Header "RUNNING FLUTTER ANALYZE"
    
    try {
        Write-Info "Running flutter analyze..."
        
        # Change to project directory
        Push-Location $ProjectPath
        
        # Run flutter analyze and capture both stdout and stderr
        $output = & flutter analyze 2>&1
        $exitCode = $LASTEXITCODE
        
        # Restore original location
        Pop-Location
        
        if ($exitCode -eq 0) {
            # Check if there's any output (warnings/info) or if it's truly clean
            if ($output -and $output.Count -gt 0) {
                return $output
            } else {
                Write-Success "No linter errors found!"
                return $null
            }
        } else {
            return $output
        }
    } catch {
        Write-Error "Error running flutter analyze: $_"
        return $null
    }
}

function Parse-AnalysisOutput {
    param([array]$Output)
    
    if (-not $Output -or $Output.Count -eq 0) { 
        return @{
            'errors' = @()
            'warnings' = @()
            'hints' = @()
            'info' = @()
            'by_file' = @{}
            'by_rule' = @{}
        }
    }
    
    $issues = @{
        'errors' = @()
        'warnings' = @()
        'hints' = @()
        'info' = @()
        'by_file' = @{}
        'by_rule' = @{}
    }
    
    foreach ($line in $Output) {
        # Handle different output formats from flutter analyze
        if ($line -match '^(.+):(\d+):(\d+):\s*(.+?):\s*(.+)$') {
            $file = $matches[1]
            $lineNum = $matches[2]
            $column = $matches[3]
            $severity = $matches[4]
            $message = $matches[5]
            
            $issue = @{
                'file' = $file
                'line' = $lineNum
                'column' = $column
                'severity' = $severity
                'message' = $message
            }
            
            # Extract rule name if present (format: rule_name: message)
            if ($message -match '^([a-z_]+):\s*(.+)$') {
                $rule = $matches[1]
                $issue['rule'] = $rule
                $issue['message'] = $matches[2]
                
                if (-not $issues['by_rule'].ContainsKey($rule)) {
                    $issues['by_rule'][$rule] = @()
                }
                $issues['by_rule'][$rule] += $issue
            }
            
            # Add to severity category
            if ($issues.ContainsKey($severity)) {
                $issues[$severity] += $issue
            }
            
            # Add to file category
            if (-not $issues['by_file'].ContainsKey($file)) {
                $issues['by_file'][$file] = @()
            }
            $issues['by_file'][$file] += $issue
        }
        # Handle other potential output formats
        elseif ($line -match '^(.+):(\d+):(\d+):\s*(.+)$') {
            $file = $matches[1]
            $lineNum = $matches[2]
            $column = $matches[3]
            $message = $matches[4]
            
            $issue = @{
                'file' = $file
                'line' = $lineNum
                'column' = $column
                'severity' = 'info'
                'message' = $message
            }
            
            $issues['info'] += $issue
            
            if (-not $issues['by_file'].ContainsKey($file)) {
                $issues['by_file'][$file] = @()
            }
            $issues['by_file'][$file] += $issue
        }
    }
    
    return $issues
}

function Show-IssueSummary {
    param([hashtable]$Issues)
    
    Write-Header "LINTER ERROR SUMMARY"
    
    $totalIssues = $Issues['errors'].Count + $Issues['warnings'].Count + $Issues['hints'].Count + $Issues['info'].Count
    
    if ($totalIssues -eq 0) {
        Write-Success "No linter issues found!"
        return
    }
    
    Write-Host "Total Issues: $totalIssues" -ForegroundColor White
    Write-Host "  ERRORS: $($Issues['errors'].Count)" -ForegroundColor Red
    Write-Host "  WARNINGS: $($Issues['warnings'].Count)" -ForegroundColor Yellow
    Write-Host "  HINTS: $($Issues['hints'].Count)" -ForegroundColor Blue
    Write-Host "  INFO: $($Issues['info'].Count)" -ForegroundColor Cyan
    
    if ($Issues['by_rule'].Count -gt 0) {
        Write-Host "`nIssues by Rule:" -ForegroundColor White
        foreach ($rule in $Issues['by_rule'].Keys | Sort-Object) {
            $count = $Issues['by_rule'][$rule].Count
            Write-Host "  $rule`: $count issues" -ForegroundColor Gray
        }
    }
}

function Show-FileIssues {
    param([hashtable]$Issues, [string]$SpecificFile)
    
    Write-Header "FILE-SPECIFIC ISSUES"
    
    if ($Issues['by_file'].Count -eq 0) {
        Write-Info "No file-specific issues to display"
        return
    }
    
    $filesToShow = if ($SpecificFile) { @($SpecificFile) } else { $Issues['by_file'].Keys | Sort-Object }
    
    foreach ($file in $filesToShow) {
        if ($Issues['by_file'].ContainsKey($file)) {
            $fileIssues = $Issues['by_file'][$file]
            Write-Host "`nFILE: $file ($($fileIssues.Count) issues)" -ForegroundColor White
            
            foreach ($issue in $fileIssues) {
                $severityIcon = switch ($issue['severity']) {
                    'error' { '[ERROR]' }
                    'warning' { '[WARN]' }
                    'hint' { '[HINT]' }
                    'info' { '[INFO]' }
                    default { '[UNKNOWN]' }
                }
                
                Write-Host "  $($severityIcon) Line $($issue['line']):$($issue['column']) - $($issue['message'])" -ForegroundColor Gray
                if ($issue.ContainsKey('rule')) {
                    Write-Host "     Rule: $($issue['rule'])" -ForegroundColor DarkGray
                }
            }
        }
    }
}

function Show-SuggestedFixes {
    param([hashtable]$Issues)
    
    Write-Header "SUGGESTED FIXES"
    
    if ($Issues['by_rule'].Count -eq 0) {
        Write-Info "No specific fixes needed - your code looks good!"
        return
    }
    
    $commonFixes = @{
        'avoid_print' = @{
            'description' = 'Replace print() with proper logging'
            'fix' = 'Use debugPrint() or a logging framework like logger package'
            'example' = 'debugPrint("Debug message");'
        }
        'unused_import' = @{
            'description' = 'Remove unused imports'
            'fix' = 'Delete the unused import statement'
            'example' = '// Remove: import "package:unused/package.dart";'
        }
        'unused_field' = @{
            'description' = 'Remove or use the unused field'
            'fix' = 'Either use the field or prefix with underscore to mark as private'
            'example' = '// Change: String name; to: String _name;'
        }
        'prefer_const_constructors' = @{
            'description' = 'Use const constructors when possible'
            'fix' = 'Add const keyword before constructor calls'
            'example' = 'const Text("Hello") instead of Text("Hello")'
        }
        'use_build_context_synchronously' = @{
            'description' = 'Avoid using BuildContext after async operations'
            'fix' = 'Check if mounted before using context'
            'example' = 'if (mounted) { Navigator.pop(context); }'
        }
        'prefer_single_quotes' = @{
            'description' = 'Use single quotes instead of double quotes'
            'fix' = 'Replace double quotes with single quotes'
            'example' = "'Hello' instead of `"Hello`""
        }
    }
    
    foreach ($rule in $Issues['by_rule'].Keys) {
        if ($commonFixes.ContainsKey($rule)) {
            $fixInfo = $commonFixes[$rule]
            $count = $Issues['by_rule'][$rule].Count
            Write-Host "`nFIX: $rule ($count issues)" -ForegroundColor Yellow
            Write-Host "   Description: $($fixInfo['description'])" -ForegroundColor Gray
            Write-Host "   Fix: $($fixInfo['fix'])" -ForegroundColor Gray
            Write-Host "   Example: $($fixInfo['example'])" -ForegroundColor Gray
        }
    }
}

function Show-QuickFixCommands {
    Write-Header "QUICK FIX COMMANDS"
    
    Write-Host "Run automatic fixes:" -ForegroundColor White
    Write-Host "   dart fix --apply" -ForegroundColor Gray
    Write-Host "   flutter fix --apply" -ForegroundColor Gray
    
    Write-Host "`nFormat code:" -ForegroundColor White
    Write-Host "   dart format ." -ForegroundColor Gray
    Write-Host "   flutter format ." -ForegroundColor Gray
    
    Write-Host "`nRe-analyze with specific options:" -ForegroundColor White
    Write-Host "   flutter analyze --no-fatal-infos" -ForegroundColor Gray
    Write-Host "   flutter analyze --no-fatal-warnings" -ForegroundColor Gray
    
    Write-Host "`nClean and rebuild:" -ForegroundColor White
    Write-Host "   flutter clean" -ForegroundColor Gray
    Write-Host "   flutter pub get" -ForegroundColor Gray
    Write-Host "   flutter analyze" -ForegroundColor Gray
}

function Show-DetailedIssues {
    param([hashtable]$Issues)
    
    Write-Header "DETAILED ISSUE LIST"
    
    foreach ($severity in @('errors', 'warnings', 'hints', 'info')) {
        if ($Issues[$severity].Count -gt 0) {
            Write-Host "`n$($severity.ToUpper()) ($($Issues[$severity].Count)):" -ForegroundColor White
            foreach ($issue in $Issues[$severity]) {
                Write-Host "  $($issue['file']):$($issue['line']) - $($issue['message'])" -ForegroundColor Gray
            }
        }
    }
}

# Main execution
Write-Host "Starting Flutter Linter Debug..." -ForegroundColor Green
Write-Host "Project path: $ProjectPath" -ForegroundColor Cyan

# Check Flutter installation
if (-not (Test-FlutterInstallation)) {
    Write-Error "Flutter is not properly installed. Please install Flutter first."
    exit 1
}

# Check project structure
Test-ProjectStructure

# Check analysis options
Test-AnalysisOptions

# Run flutter analyze
$analysisOutput = Run-FlutterAnalyze

if ($analysisOutput) {
    # Parse and display results
    $issues = Parse-AnalysisOutput -Output $analysisOutput
    
    if ($issues['by_file'].Count -gt 0 -or $issues['errors'].Count -gt 0 -or $issues['warnings'].Count -gt 0) {
        Show-IssueSummary -Issues $issues
        Show-FileIssues -Issues $issues -SpecificFile $SpecificFile
        Show-SuggestedFixes -Issues $issues
        Show-QuickFixCommands
        
        if ($Verbose) {
            Show-DetailedIssues -Issues $issues
        }
    } else {
        Write-Success "No linter errors found! Your code looks good."
    }
} else {
    Write-Success "No linter errors found! Your code looks good."
}

Write-Header "DEBUG COMPLETE"
Write-Host "Debug complete! Use the suggested commands above to fix issues." -ForegroundColor Green 