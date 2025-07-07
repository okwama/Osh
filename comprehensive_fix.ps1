# Comprehensive fix script for all remaining compilation issues

Write-Host "Starting comprehensive fix for all compilation issues..." -ForegroundColor Green

# Function to fix TokenService issues
function Fix-TokenService {
    Write-Host "Fixing TokenService method calls..." -ForegroundColor Yellow
    
    # Files that need TokenService fixes
    $files = @(
        "lib/services/checkin_service.dart",
        "lib/services/client_stock_service.dart",
        "lib/pages/profile/user_stats_page.dart",
        "lib/services/api_service.dart",
        "lib/services/jouneyplan_service.dart",
        "lib/services/productTransaction_service.dart",
        "lib/services/report_service.dart",
        "lib/services/task_service.dart",
        "lib/utils/test_refresh_token.dart"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "Fixing TokenService in: $file" -ForegroundColor Cyan
            $content = Get-Content -Path $file -Raw
            
            # Fix static method calls to instance methods
            $content = $content -replace "TokenService\.getAccessToken\(\)", "TokenService().getAccessToken()"
            $content = $content -replace "TokenService\.getRefreshToken\(\)", "TokenService().getRefreshToken()"
            $content = $content -replace "TokenService\.isTokenExpired\(\)", "TokenService().isTokenExpired()"
            $content = $content -replace "TokenService\.clearTokens\(\)", "TokenService().clearTokens()"
            $content = $content -replace "TokenService\.isAuthenticated\(\)", "TokenService().isAuthenticated()"
            $content = $content -replace "TokenService\.debugTokenInfo\(\)", "TokenService().debugTokenInfo()"
            
            Set-Content -Path $file -Value $content -NoNewline
        }
    }
}

# Function to fix TokenService class definition
function Fix-TokenServiceClass {
    Write-Host "Fixing TokenService class definition..." -ForegroundColor Yellow
    
    $tokenServiceFile = "lib/services/token_service.dart"
    if (Test-Path $tokenServiceFile) {
        $content = Get-Content -Path $tokenServiceFile -Raw
        
        # Replace the entire class with a proper implementation
        $newContent = @"
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static bool _isLoginInProgress = false;

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  static Future<void> setRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  static Future<void> setTokenExpiry(DateTime expiryTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
  }

  static Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tokenExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  static Future<bool> isTokenExpired() async {
    final expiryTime = await getTokenExpiry();
    if (expiryTime == null) return true;
    return DateTime.now().isAfter(expiryTime);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return !(await isTokenExpired());
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  static void debugTokenInfo() {
    print('TokenService debug info');
  }

  static bool get isLoginInProgress => _isLoginInProgress;
  static set isLoginInProgress(bool value) => _isLoginInProgress = value;
}
"@
        
        Set-Content -Path $tokenServiceFile -Value $newContent -NoNewline
    }
}

# Function to fix config.dart duplicate declarations
function Fix-ConfigFile {
    Write-Host "Fixing config.dart duplicate declarations..." -ForegroundColor Yellow
    
    $configFile = "lib/utils/config.dart"
    if (Test-Path $configFile) {
        $newContent = @"
class Config {
  static const String baseUrl = 'https://api.woosh.com';
  static const String apiVersion = 'v1';
  static const String imageBaseUrl = 'https://images.woosh.com';
  
  // Add any other configuration constants here
}
"@
        
        Set-Content -Path $configFile -Value $newContent -NoNewline
    }
}

# Function to fix products grid page syntax errors
function Fix-ProductsGridPage {
    Write-Host "Fixing products grid page syntax errors..." -ForegroundColor Yellow
    
    $file = "lib/pages/order/product/products_grid_page.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Fix GridView.builder syntax
        $content = $content -replace "GridView\.builder\(`n.*?\)", "GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return ProductCard(product: product);
          },
        )"
        
        # Add missing variable declarations
        $missingVars = @"
  String _currentSearchQuery = '';
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  StreamSubscription? _connectivitySubscription;
  List<Product> _products = [];
  
"@
        $content = $content -replace "class _ProductsGridPageState extends State<ProductsGridPage> \{", "class _ProductsGridPageState extends State<ProductsGridPage> {$missingVars"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix order detail page issues
function Fix-OrderDetailPage {
    Write-Host "Fixing order detail page issues..." -ForegroundColor Yellow
    
    $file = "lib/pages/order/viewOrder/orderDetail.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Fix missing variables
        $missingVars = @"
  Color statusColor = Colors.grey;
  IconData statusIcon = Icons.info;
  bool canVoid = false;
  String voidStatusMessage = '';
  Color voidStatusColor = Colors.grey;
  
"@
        $content = $content -replace "class _OrderDetailPageState extends State<OrderDetailPage> \{", "class _OrderDetailPageState extends State<OrderDetailPage> {$missingVars"
        
        # Fix totalAmount reference
        $content = $content -replace "_buildTotalSection\(context, totalAmount\)", "_buildTotalSection(context, widget.order.totalAmount ?? 0.0)"
        
        # Fix Padding widget
        $content = $content -replace "body: SingleChildScrollView", "child: SingleChildScrollView"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix journey view issues
function Fix-JourneyView {
    Write-Host "Fixing journey view issues..." -ForegroundColor Yellow
    
    $file = "lib/pages/journeyplan/journeyview.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Add missing variable declarations
        $missingVars = @"
  bool _isNetworkAvailable = true;
  bool _isSessionValid = true;
  bool _isFetchingLocation = false;
  bool _isCheckingIn = false;
  bool _isWithinGeofence = false;
  double _distanceToClient = 0.0;
  Position? _currentPosition;
  String _currentAddress = '';
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const double GEOFENCE_RADIUS_METERS = 100.0;
  XFile? image;
  
"@
        $content = $content -replace "class _JourneyViewState extends State<JourneyView> \{", "class _JourneyViewState extends State<JourneyView> {$missingVars"
        
        # Fix try-catch blocks
        $content = $content -replace "try \{", "try {"
        $content = $content -replace "catch \(e\) \{", "} catch (e) {"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix uplift sale cart page issues
function Fix-UpliftSaleCartPage {
    Write-Host "Fixing uplift sale cart page issues..." -ForegroundColor Yellow
    
    $file = "lib/pages/pos/upliftSaleCart_page.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Remove duplicate variable declarations
        $content = $content -replace "List<Product> _products = \[\];`n.*?List<Product> _products = \[\];", "List<Product> _products = [];"
        $content = $content -replace "bool _isLoadingProducts = false;`n.*?bool _isLoadingProducts = false;", "bool _isLoadingProducts = false;"
        
        # Fix undefined 'item' references
        $content = $content -replace "item\.", "product."
        
        # Fix method calls
        $content = $content -replace "_buildProductSelector\(\)", "_buildProductSelector(context)"
        $content = $content -replace "_buildCartItem\(\)", "_buildCartItem(context, product)"
        $content = $content -replace "_buildTotalSection\(\)", "_buildTotalSection(context)"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix targets page issues
function Fix-TargetsPage {
    Write-Host "Fixing targets page issues..." -ForegroundColor Yellow
    
    $file = "lib/pages/profile/targets/targets_page.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Add missing variable declarations
        $missingVars = @"
  List<Target> _targets = [];
  List<Order> _userOrders = [];
  bool _isLoadingOrders = false;
  bool _isLoadingMore = false;
  TabController? _tabController;
  
"@
        $content = $content -replace "class _TargetsPageState extends State<TargetsPage> \{", "class _TargetsPageState extends State<TargetsPage> with TickerProviderStateMixin {$missingVars"
        
        # Fix method declarations
        $content = $content -replace "Future<void> _loadTargets\(\)", "Future<void> _loadTargets() async"
        $content = $content -replace "Future<void> _loadUserOrders\(\)", "Future<void> _loadUserOrders() async"
        $content = $content -replace "Future<void> _loadDailyVisitTargets\(\)", "Future<void> _loadDailyVisitTargets() async"
        $content = $content -replace "Future<void> _refreshData\(\)", "Future<void> _refreshData() async"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix outlet service issues
function Fix-OutletService {
    Write-Host "Fixing outlet service issues..." -ForegroundColor Yellow
    
    $file = "lib/services/outlet_service.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Add missing variable declarations
        $missingVars = @"
  List<Outlet> _allOutlets = [];
  int _pageSize = 20;
  String _state = 'idle';
  
"@
        $content = $content -replace "class OutletService \{", "class OutletService {$missingVars"
        
        # Fix method declarations
        $content = $content -replace "void _updateState\(String newState\)", "void _updateState(String newState) { _state = newState; }"
        $content = $content -replace "Future<void> _loadNextPage\(\)", "Future<void> _loadNextPage() async"
        $content = $content -replace "Future<void> _loadAllOutlets\(\)", "Future<void> _loadAllOutlets() async"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix session service issues
function Fix-SessionService {
    Write-Host "Fixing session service issues..." -ForegroundColor Yellow
    
    $file = "lib/services/session_service.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Fix the getHeaders method
        $newHeadersMethod = @"
  static Future<Map<String, String>> getHeaders() async {
    final token = await TokenService().getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer \$token';
    }
    return headers;
  }
"@
        $content = $content -replace "static Future<Map<String, String>> getHeaders\(\) \{.*?\}", $newHeadersMethod
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Function to fix target service issues
function Fix-TargetService {
    Write-Host "Fixing target service issues..." -ForegroundColor Yellow
    
    $file = "lib/services/target_service.dart"
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        
        # Move imports to the top
        $content = $content -replace "import.*?;`n", ""
        $newImports = @"
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/target.dart';
import '../utils/config.dart';
import 'token_service.dart';
import 'api_service.dart';

"@
        $content = $newImports + $content
        
        # Fix method declarations
        $content = $content -replace "Future<List<Target>> getTargets\(\)", "Future<List<Target>> getTargets() async"
        
        Set-Content -Path $file -Value $content -NoNewline
    }
}

# Main execution
Write-Host "Starting comprehensive fixes..." -ForegroundColor Green

Fix-TokenService
Fix-TokenServiceClass
Fix-ConfigFile
Fix-ProductsGridPage
Fix-OrderDetailPage
Fix-JourneyView
Fix-UpliftSaleCartPage
Fix-TargetsPage
Fix-OutletService
Fix-SessionService
Fix-TargetService

Write-Host "`nComprehensive fixes completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run 'flutter analyze' to check remaining issues" -ForegroundColor White
Write-Host "2. Run 'flutter run' to test the app" -ForegroundColor White
Write-Host "3. Fix any remaining specific errors manually" -ForegroundColor White 