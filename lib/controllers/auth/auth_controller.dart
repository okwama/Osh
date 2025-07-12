import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../../services/database_service.dart';
import '../../models/salerep/sales_rep_model.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _isLoggedIn = false.obs;
  final _currentUser = Rxn<SalesRepModel>();
  final _isInitialized = false.obs;
  final _currentToken = Rxn<String>();

  RxBool get isLoggedIn => _isLoggedIn;
  SalesRepModel? get currentUser => _currentUser.value;
  RxBool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken.value;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Check for existing session first (non-blocking)
      await _loadUserFromStorage().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⏰ Auth initialization timeout, proceeding anyway');
        },
      );
      _isInitialized.value = true;

      // Initialize database connection in background
      _initializeDatabase();
    } catch (e) {
      print('⚠️ Auth initialization error: $e');
      _isInitialized.value = true;
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      if (!DatabaseService.instance.isInitialized) {
        print('🔄 Starting database initialization...');
        await DatabaseService.instance.initialize();
        print('✅ Database initialized successfully');
      }
    } catch (e) {
      print('❌ Database initialization failed: $e');
      // Don't rethrow - let individual operations handle DB errors
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final box = GetStorage();
      final userData = box.read('salesRep');
      final token = box.read('authToken');

      if (userData != null && token != null) {
        // Validate token from storage
        final isValid = TokenService.isAuthenticated();

        if (isValid) {
          try {
            _currentUser.value = SalesRepModel.fromMap(userData);
            _currentToken.value = token;
            _isLoggedIn.value = true;
          } catch (e) {
            await _clearStorage();
          }
        } else {
          // Token is invalid, clear storage
          await _clearStorage();
        }
      }
    } catch (e) {
      await _clearStorage();
    }
  }

  Future<void> login(String phoneNumber, String password) async {
    try {
      // Ensure database is initialized before login
      if (!DatabaseService.instance.isInitialized) {
        print('🔄 Initializing database before login...');
        await _initializeDatabase();
      }

      final result = await AuthService.login(phoneNumber, password);

      if (result['success'] == true && result['salesRep'] != null) {
        final user = SalesRepModel.fromMap(result['salesRep']);
        final token = result['token']?.toString();

        // Validate token
        if (token == null || token.isEmpty) {
          throw Exception('Login successful but no token received');
        }

        // Store user data and token
        final box = GetStorage();
        box.write('salesRep', user.toMap());
        box.write('authToken', token);
        box.write('userId', user.id.toString());

        _currentUser.value = user;
        _currentToken.value = token;
        _isLoggedIn.value = true;
      } else {
        throw Exception(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // QR code login not implemented in current AuthService
  Future<void> loginWithQrCode(String qrCode) async {
    throw UnimplementedError('QR code login not implemented');
  }

  Future<void> logout() async {
    try {
      if (_currentToken.value != null) {
        await TokenService.clearTokens();
      }

      await _clearStorage();
      _currentUser.value = null;
      _currentToken.value = null;
      _isLoggedIn.value = false;
    } catch (e) {
      rethrow;
    }
  }

  bool isAuthenticated() {
    return _isLoggedIn.value && _currentToken.value != null;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_currentUser.value == null) {
        throw Exception('No user logged in');
      }

      final success = await AuthService.updateProfile(
        _currentUser.value!.id,
        data,
      );

      if (success) {
        // Reload user data
        final updatedUser =
            await AuthService.getUserById(_currentUser.value!.id);
        if (updatedUser != null) {
          _currentUser.value = updatedUser;

          // Update stored data
          final box = GetStorage();
          box.write('salesRep', updatedUser.toMap());
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (_currentUser.value == null) {
        return false;
      }

      return await AuthService.changePassword(
        _currentUser.value!.id,
        currentPassword,
        newPassword,
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearStorage() async {
    final box = GetStorage();
    box.remove('salesRep');
    box.remove('authToken');
    box.remove('userId');
  }
}
