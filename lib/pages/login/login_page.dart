import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10,12}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _showToast(String message, bool isError) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  String _getUserFriendlyErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    
    // Common error patterns
    if (errorLower.contains('wrong password')) {
      return 'Wrong password';
    } else if (errorLower.contains('invalid phone number or password')) {
      return 'Invalid phone number or password';
    } else if (errorLower.contains('connection timeout') || 
               errorLower.contains('connection refused') ||
               errorLower.contains('database connection failed')) {
      return 'Network error. Please check your internet connection';
    } else if (errorLower.contains('authentication failed')) {
      return 'Authentication failed. Please contact support';
    } else if (errorLower.contains('user not found')) {
      return 'Phone number not registered';
    } else if (errorLower.contains('phone')) {
      return 'Invalid phone number';
    } else {
      return 'Login failed. Please try again';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.login(
        _phoneNumberController.text.trim(),
        _passwordController.text,
      );

      // Get user role for navigation
      final userRole = _authController.currentUser?.role ?? '';

      // Navigate based on role
      if (userRole.toLowerCase() == 'manager') {
        Get.offAllNamed('/manager-home');
      } else {
        Get.offAllNamed('/home');
      }

      _showToast('Login successful', false);
    } catch (e) {
      final userFriendlyMessage = _getUserFriendlyErrorMessage(e.toString());
      _showToast(userFriendlyMessage, true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.25 : 20.0;
    final maxFormWidth = isTablet ? 400.0 : double.infinity;

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reduced top spacer
                      SizedBox(height: screenHeight * 0.03),

                      // Main content card
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: maxFormWidth),
                        decoration: BoxDecoration(
                          color: appBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            width: 2,
                            color: Colors.transparent,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldStart.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 40.0 : 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Enlarged logo with enhanced styling
                              Container(
                                height: isTablet ? 120 : 100,
                                width: isTablet ? 120 : 100,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: goldGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldStart.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/new.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // App name image
                              Container(
                                height: isTablet ? 50 : 42,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Image.asset(
                                  'assets/name.png',
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: isTablet ? 28 : 20),

                              // Compact form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Phone Number Field
                                    _buildModernTextField(
                                      controller: _phoneNumberController,
                                      label: 'Phone Number',
                                      hint: 'Enter your phone number',
                                      prefixIcon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: _validatePhoneNumber,
                                    ),

                                    const SizedBox(height: 16),

                                    // Password Field
                                    _buildModernTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      isPassword: true,
                                      validator: _validatePassword,
                                    ),

                                    const SizedBox(height: 24),

                                    // Login Button
                                    _buildModernLoginButton(),

                                    const SizedBox(height: 16),

                                    // Sign up row
                                    _buildSignUpRow(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Reduced bottom spacer
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey.shade500,
              size: 18,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: goldStart, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildModernLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: goldGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: goldGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: goldStart.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _login,
                  borderRadius: BorderRadius.circular(14),
                  child: const Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSignUpRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Don\'t have an account? ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed('/sign-up'),
              child: GradientText(
                'Sign Up',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Database test button (for debugging)
        // TextButton(
        //   onPressed: () => Get.toNamed('/test/database'),
        //   child: Text(
        //     'Test Database Connection',
        //     style: TextStyle(
        //       color: Colors.grey.shade500,
        //       fontSize: 12,
        //       decoration: TextDecoration.underline,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
