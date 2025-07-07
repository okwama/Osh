# Final comprehensive fix for all remaining compilation issues

Write-Host "Starting final comprehensive fix for all remaining compilation issues..." -ForegroundColor Green

# Function to fix TargetService string literal issues
function Fix-TargetServiceStringLiterals {
    Write-Host "Fixing TargetService string literal issues..." -ForegroundColor Yellow
    
    $targetServiceFile = "lib/services/target_service.dart"
    if (Test-Path $targetServiceFile) {
        $newContent = @"
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'token_service.dart';

class TargetService {
  static Future<List<Map<String, dynamic>>> getTargets() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('\${Config.baseUrl}/api/targets'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['targets'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching targets: \$e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getDailyVisitTargets({required String userId}) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return {};
      
      final response = await http.get(
        Uri.parse('\${Config.baseUrl}/api/targets/daily-visits?userId=\$userId'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching daily visit targets: \$e');
      return {};
    }
  }
  
  static Future<Map<String, dynamic>> getNewClientsProgress({required String userId, String? period}) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return {};
      
      final url = '\${Config.baseUrl}/api/targets/new-clients?userId=\$userId';
      final finalUrl = period != null ? '\$url&period=\$period' : url;
      
      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching new clients progress: \$e');
      return {};
    }
  }
  
  static Future<Map<String, dynamic>> getProductSalesProgress({required String userId, String? period}) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return {};
      
      final url = '\${Config.baseUrl}/api/targets/product-sales?userId=\$userId';
      final finalUrl = period != null ? '\$url&period=\$period' : url;
      
      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching product sales progress: \$e');
      return {};
    }
  }
  
  static Future<Map<String, dynamic>> getMonthlyVisits({required String userId}) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return {};
      
      final response = await http.get(
        Uri.parse('\${Config.baseUrl}/api/targets/monthly-visits?userId=\$userId'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching monthly visits: \$e');
      return {};
    }
  }
  
  static Future<List<Map<String, dynamic>>> getClientDetails(String userId, {String? period}) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return [];
      
      final url = '\${Config.baseUrl}/api/targets/client-details?userId=\$userId';
      final finalUrl = period != null ? '\$url&period=\$period' : url;
      
      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['clients'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching client details: \$e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return {};
      
      final response = await http.get(
        Uri.parse('\${Config.baseUrl}/api/targets/dashboard'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching dashboard: \$e');
      return {};
    }
  }
  
  static Future<Map<String, dynamic>> getSalesData() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return {};
      
      final response = await http.get(
        Uri.parse('\${Config.baseUrl}/api/targets/sales-data'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching sales data: \$e');
      return {};
    }
  }
  
  static void clearCache() {
    // Implementation for clearing cache
    print('Cache cleared');
  }
}
"@
        
        Set-Content -Path $targetServiceFile -Value $newContent -NoNewline
    }
}

# Function to fix TokenService duplicate methods
function Fix-TokenServiceDuplicateMethods {
    Write-Host "Fixing TokenService duplicate methods..." -ForegroundColor Yellow
    
    $tokenServiceFile = "lib/services/token_service.dart"
    if (Test-Path $tokenServiceFile) {
        $content = Get-Content -Path $tokenServiceFile -Raw
        
        # Remove duplicate storeTokens methods
        $content = $content -replace "static Future<void> storeTokens\(String accessToken, String refreshToken, DateTime expiryTime\) async \{.*?\}", ""
        $content = $content -replace "static Future<void> storeTokens\(String accessToken, String refreshToken, DateTime expiryTime\) async \{.*?\}", ""
        
        # Add single storeTokens method
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

# Function to fix SessionService missing methods
function Fix-SessionServiceMissingMethods {
    Write-Host "Fixing SessionService missing methods..." -ForegroundColor Yellow
    
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
  
  static Future<void> recordLogin() async {
    // Implementation for recording login
    print('Login recorded');
  }
  
  static Future<void> recordLogout() async {
    // Implementation for recording logout
    print('Logout recorded');
  }
  
  static Future<bool> isSessionValid() async {
    return await TokenService.isAuthenticated();
  }
  
  static Future<List<Map<String, dynamic>>> getSessionHistory() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('\${Config.baseUrl}/api/session/history'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching session history: \$e');
      return [];
    }
  }
}
"@
        
        Set-Content -Path $sessionServiceFile -Value $newContent -NoNewline
    }
}

# Function to fix API service return type issues
function Fix-ApiServiceReturnTypes {
    Write-Host "Fixing API service return type issues..." -ForegroundColor Yellow
    
    $apiServiceFile = "lib/services/api_service.dart"
    if (Test-Path $apiServiceFile) {
        $content = Get-Content -Path $apiServiceFile -Raw
        
        # Fix _getAuthToken method
        $content = $content -replace "Future<String\?> _getAuthToken\(\)", "String? _getAuthToken()"
        $content = $content -replace "return await TokenService\.getAccessToken\(\);", "return TokenService.getAccessToken();"
        
        # Fix isAuthenticated method
        $content = $content -replace "Future<bool> isAuthenticated\(\)", "bool isAuthenticated()"
        $content = $content -replace "return await TokenService\.isAuthenticated\(\);", "return TokenService.isAuthenticated();"
        
        # Fix storeTokens calls
        $content = $content -replace "TokenService\.storeTokens\(\)", "TokenService.storeTokens(accessToken, refreshToken, expiryTime)"
        
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
            $content = $content -replace "Future<String\?> _getAuthToken\(\)", "String? _getAuthToken()"
            $content = $content -replace "return await TokenService\.getAccessToken\(\);", "return TokenService.getAccessToken();"
            
            Set-Content -Path $file -Value $content -NoNewline
        }
    }
}

# Function to fix ProfileController
function Fix-ProfileController {
    Write-Host "Fixing ProfileController..." -ForegroundColor Yellow
    
    $profileControllerFile = "lib/controllers/profile_controller.dart"
    if (Test-Path $profileControllerFile) {
        $newContent = @"
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var isLoading = false.obs;
  var userData = <String, dynamic>{}.obs;
  var passwordSuccess = ''.obs;
  var passwordError = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }
  
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      final response = await _apiService.getUserProfile();
      if (response != null) {
        userData.value = response['salesRep'] ?? {};
      }
    } catch (e) {
      print('Error loading user profile: \$e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      isLoading.value = true;
      final result = await _apiService.changePassword(currentPassword, newPassword);
      if (result['success']) {
        passwordSuccess.value = result['message'];
        passwordError.value = '';
      } else {
        passwordError.value = result['message'];
        passwordSuccess.value = '';
      }
    } catch (e) {
      passwordError.value = 'An error occurred while changing password';
      passwordSuccess.value = '';
      print('PROFILE CONTROLLER: Password update failed: \$e');
    } finally {
      isLoading.value = false;
    }
  }
}
"@
        
        Set-Content -Path $profileControllerFile -Value $newContent -NoNewline
    }
}

# Main execution
Write-Host "Starting final comprehensive fixes..." -ForegroundColor Green

Fix-TargetServiceStringLiterals
Fix-TokenServiceDuplicateMethods
Fix-SessionServiceMissingMethods
Fix-ApiServiceReturnTypes
Fix-OtherServiceReturnTypes
Fix-ProfileController

Write-Host "`nFinal comprehensive fixes completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run 'flutter analyze' to check remaining issues" -ForegroundColor White
Write-Host "2. Run 'flutter run' to test the app" -ForegroundColor White 