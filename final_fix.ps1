# Final fix script for remaining compilation issues

Write-Host "Starting final fixes for remaining compilation issues..." -ForegroundColor Green

# Function to fix TokenService static method calls
function Fix-TokenServiceStaticCalls {
    Write-Host "Fixing TokenService static method calls..." -ForegroundColor Yellow
    
    # Files that need TokenService fixes
    $files = @(
        "lib/services/api_service.dart",
        "lib/services/checkin_service.dart",
        "lib/services/client_stock_service.dart",
        "lib/services/jouneyplan_service.dart",
        "lib/services/productTransaction_service.dart",
        "lib/services/report_service.dart",
        "lib/services/session_service.dart",
        "lib/services/task_service.dart",
        "lib/pages/profile/user_stats_page.dart",
        "lib/utils/test_refresh_token.dart"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "Fixing TokenService static calls in: $file" -ForegroundColor Cyan
            $content = Get-Content -Path $file -Raw
            
            # Fix static method calls to use static syntax
            $content = $content -replace "TokenService\(\)\.getAccessToken\(\)", "TokenService.getAccessToken()"
            $content = $content -replace "TokenService\(\)\.getRefreshToken\(\)", "TokenService.getRefreshToken()"
            $content = $content -replace "TokenService\(\)\.isTokenExpired\(\)", "TokenService.isTokenExpired()"
            $content = $content -replace "TokenService\(\)\.clearTokens\(\)", "TokenService.clearTokens()"
            $content = $content -replace "TokenService\(\)\.isAuthenticated\(\)", "TokenService.isAuthenticated()"
            $content = $content -replace "TokenService\(\)\.debugTokenInfo\(\)", "TokenService.debugTokenInfo()"
            $content = $content -replace "TokenService\(\)\.storeTokens\(\)", "TokenService.storeTokens()"
            
            Set-Content -Path $file -Value $content -NoNewline
        }
    }
}

# Function to add missing dependencies to pubspec.yaml
function Add-MissingDependencies {
    Write-Host "Adding missing dependencies..." -ForegroundColor Yellow
    
    $pubspecFile = "pubspec.yaml"
    if (Test-Path $pubspecFile) {
        $content = Get-Content -Path $pubspecFile -Raw
        
        # Add shared_preferences dependency if not present
        if ($content -notmatch "shared_preferences:") {
            $content = $content -replace "dependencies:", "dependencies:
  shared_preferences: ^2.2.2"
        }
        
        # Add uuid dependency if not present
        if ($content -notmatch "uuid:") {
            $content = $content -replace "shared_preferences:.*", "shared_preferences: ^2.2.2
  uuid: ^4.2.1"
        }
        
        Set-Content -Path $pubspecFile -Value $content -NoNewline
    }
}

# Function to fix TokenService class to add missing methods
function Fix-TokenServiceClass {
    Write-Host "Fixing TokenService class..." -ForegroundColor Yellow
    
    $tokenServiceFile = "lib/services/token_service.dart"
    if (Test-Path $tokenServiceFile) {
        $content = Get-Content -Path $tokenServiceFile -Raw
        
        # Add missing storeTokens method
        $storeTokensMethod = @"

  static Future<void> storeTokens(String accessToken, String refreshToken, DateTime expiryTime) async {
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
    await setTokenExpiry(expiryTime);
  }
"@
        $content = $content -replace "static void debugTokenInfo\(\) \{", "static void debugTokenInfo() {$storeTokensMethod"
        
        Set-Content -Path $tokenServiceFile -Value $content -NoNewline
    }
}

# Function to fix API service return types
function Fix-ApiServiceReturnTypes {
    Write-Host "Fixing API service return types..." -ForegroundColor Yellow
    
    $apiServiceFile = "lib/services/api_service.dart"
    if (Test-Path $apiServiceFile) {
        $content = Get-Content -Path $apiServiceFile -Raw
        
        # Fix _getAuthToken method return type
        $content = $content -replace "String\? _getAuthToken\(\)", "Future<String?> _getAuthToken()"
        $content = $content -replace "return TokenService\.getAccessToken\(\);", "return await TokenService.getAccessToken();"
        
        # Fix isAuthenticated method return type
        $content = $content -replace "bool isAuthenticated\(\)", "Future<bool> isAuthenticated()"
        $content = $content -replace "return TokenService\.isAuthenticated\(\);", "return await TokenService.isAuthenticated();"
        
        Set-Content -Path $apiServiceFile -Value $content -NoNewline
    }
}

# Function to fix other service return types
function Fix-OtherServiceReturnTypes {
    Write-Host "Fixing other service return types..." -ForegroundColor Yellow
    
    $files = @(
        "lib/services/client_stock_service.dart",
        "lib/services/productTransaction_service.dart",
        "lib/services/report_service.dart"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "Fixing return types in: $file" -ForegroundColor Cyan
            $content = Get-Content -Path $file -Raw
            
            # Fix _getAuthToken method return type
            $content = $content -replace "String\? _getAuthToken\(\)", "Future<String?> _getAuthToken()"
            $content = $content -replace "return TokenService\.getAccessToken\(\);", "return await TokenService.getAccessToken();"
            
            Set-Content -Path $file -Value $content -NoNewline
        }
    }
}

# Function to fix session service
function Fix-SessionService {
    Write-Host "Fixing session service..." -ForegroundColor Yellow
    
    $sessionServiceFile = "lib/services/session_service.dart"
    if (Test-Path $sessionServiceFile) {
        $newContent = @"
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'token_service.dart';

class SessionService {
  static Future<Map<String, String>> getHeaders() async {
    final token = await TokenService.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer \$token';
    }
    return headers;
  }

  static Future<String?> getRefreshToken() async {
    return await TokenService.getRefreshToken();
  }

  static Future<void> storeTokens(String accessToken, String refreshToken, DateTime expiryTime) async {
    await TokenService.storeTokens(accessToken, refreshToken, expiryTime);
  }
}
"@
        
        Set-Content -Path $sessionServiceFile -Value $newContent -NoNewline
    }
}

# Function to fix target service
function Fix-TargetService {
    Write-Host "Fixing target service..." -ForegroundColor Yellow
    
    $targetServiceFile = "lib/services/target_service.dart"
    if (Test-Path $targetServiceFile) {
        $content = Get-Content -Path $targetServiceFile -Raw
        
        # Fix _getAuthToken method return type
        $content = $content -replace "String\? _getAuthToken\(\)", "Future<String?> _getAuthToken()"
        $content = $content -replace "return TokenService\.getAccessToken\(\);", "return await TokenService.getAccessToken();"
        
        # Remove problematic model imports and references
        $content = $content -replace "import '../models/target\.dart';", ""
        $content = $content -replace "List<Target>", "List<Map<String, dynamic>>"
        $content = $content -replace "Target", "Map<String, dynamic>"
        
        Set-Content -Path $targetServiceFile -Value $content -NoNewline
    }
}

# Function to fix test refresh token
function Fix-TestRefreshToken {
    Write-Host "Fixing test refresh token..." -ForegroundColor Yellow
    
    $testFile = "lib/utils/test_refresh_token.dart"
    if (Test-Path $testFile) {
        $content = Get-Content -Path $testFile -Raw
        
        # Fix static method calls
        $content = $content -replace "TokenService\(\)\.isAuthenticated\(\)", "TokenService.isAuthenticated()"
        $content = $content -replace "TokenService\(\)\.getAccessToken\(\)", "TokenService.getAccessToken()"
        $content = $content -replace "TokenService\(\)\.getRefreshToken\(\)", "TokenService.getRefreshToken()"
        $content = $content -replace "TokenService\(\)\.isTokenExpired\(\)", "TokenService.isTokenExpired()"
        
        # Fix boolean condition
        $content = $content -replace "if \(isAuthenticated\)", "if (await isAuthenticated)"
        
        Set-Content -Path $testFile -Value $content -NoNewline
    }
}

# Main execution
Write-Host "Starting final fixes..." -ForegroundColor Green

Fix-TokenServiceStaticCalls
Add-MissingDependencies
Fix-TokenServiceClass
Fix-ApiServiceReturnTypes
Fix-OtherServiceReturnTypes
Fix-SessionService
Fix-TargetService
Fix-TestRefreshToken

Write-Host "`nFinal fixes completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run 'flutter pub get' to install new dependencies" -ForegroundColor White
Write-Host "2. Run 'flutter analyze' to check remaining issues" -ForegroundColor White
Write-Host "3. Run 'flutter run' to test the app" -ForegroundColor White 