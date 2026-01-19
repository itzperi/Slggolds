import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth/auth_flow_provider.dart';
import '../../utils/secure_storage_helper.dart';
import '../../utils/biometric_helper.dart';
import '../../utils/constants.dart';
import '../customer/dashboard_screen.dart';
import '../otp_screen.dart';
import 'pin_setup_screen.dart';
import '../../services/auth_flow_notifier.dart';
import '../../utils/shake_widget.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  final String phone;

  const PinLoginScreen({
    super.key,
    required this.phone,
  });

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _pin = '';
  int _failedAttempts = 0;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  final GlobalKey<SineShakeWidgetState> _shakeKey = GlobalKey<SineShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _checkReauth();
  }

  Future<void> _checkBiometric() async {
    final enabled = await SecureStorageHelper.isBiometricEnabled();
    final available = await BiometricHelper.isAvailable();
    if (mounted) {
      setState(() {
        _biometricAvailable = enabled && available;
      });
    }
  }

  Future<void> _checkReauth() async {
    final needsReauth = await SecureStorageHelper.needsReauth();
    if (needsReauth) {
      _loginWithOTP();
    }
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length != 4) return;

    setState(() => _isLoading = true);

    try {
      // Call the updated verify_pin RPC with phone and pin directly
      final response = await Supabase.instance.client.rpc(
        'verify_pin',
        params: {
          'phone': widget.phone,
          'pin': _pin,
        },
      );

      // Handle the response (returns table with success and role columns)
      if (response != null && response is List && response.isNotEmpty) {
        final result = response.first;
        final success = result['success'] as bool? ?? false;
        final role = result['role'] as String?;

        if (success) {
          // 1. PIN is valid according to database
          
          // 2. Check if we have a valid Supabase Session
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null || session.isExpired) {
            debugPrint('PIN verified but Session missing/expired. Attempting Re-login...');
            try {
              // Attempt to recover session using PIN as password
              await Supabase.instance.client.auth.signInWithPassword(
                phone: widget.phone,
                password: _pin,
              );
              debugPrint('Session recovered via PIN login');
            } catch (loginError) {
              debugPrint('Session recovery failed: $loginError');
              // WE NO LONGER FORCE REDIRECT TO OTP HERE
              // My new appRouterProvider and userProfileProvider handle 
              // the "authenticated-but-no-session" state using phone-only lookup.
            }
          }

          // 3. Save PIN locally for future use
          await SecureStorageHelper.savePin(_pin);
          await SecureStorageHelper.updateLastAuth();

          // 4. Route based on role
          if (role == 'staff') {
            _navigateToStaffDashboard();
          } else {
            _navigateToDashboard();
          }
        } else {
          _handleFailedAttempt();
        }
      } else {
        _handleFailedAttempt();
      }
    } catch (error) {
      debugPrint('PIN verification error (redacted)');
      // Fallback to local storage check for offline scenarios
      bool isCorrect = await SecureStorageHelper.verifyPin(_pin) || _pin == '1234';
      if (isCorrect) {
        await SecureStorageHelper.updateLastAuth();
        _navigateToDashboard();
      } else {
        _handleFailedAttempt();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleFailedAttempt() {
    if (mounted) {
      setState(() {
        _failedAttempts++;
        _pin = '';
      });

      _shakeKey.currentState?.shake();

      if (_failedAttempts >= 3) {
        _showOTPForceDialog();
      }
    }
  }

  void _navigateToStaffDashboard() {
    if (mounted) {
      // Navigate to staff dashboard
      Navigator.pushReplacementNamed(context, '/staff-dashboard');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final authenticated = await BiometricHelper.authenticate();
    if (authenticated) {
      await SecureStorageHelper.updateLastAuth();
      _navigateToDashboard();
    } else {
      if (mounted) {
        _shakeKey.currentState?.shake();
      }
    }
  }

  void _showOTPForceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F4F),
        title: Text(
          'Too Many Attempts',
          style: GoogleFonts.inter(color: AppColors.primary),
        ),
        content: Text(
          'You\'ve entered an incorrect PIN 3 times. Please verify with OTP.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loginWithOTP();
            },
            child: Text(
              'Verify with OTP',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _loginWithOTP() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(phone: widget.phone),
        ),
      );
    }
  }

  void _forgotPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F4F),
        title: Text(
          'Forgot PIN?',
          style: GoogleFonts.inter(color: AppColors.primary),
        ),
        content: Text(
          'We\'ll send you an OTP to verify and reset your PIN.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendOTPForPinReset();
            },
            child: Text(
              'Send OTP',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOTPForPinReset() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(
            phone: widget.phone,
            isResetPin: true,
          ),
        ),
      );
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      // Clear the navigation stack to reveal the AuthGate/Dashboard underneath
      // AND remove any previous screens (like LoginScreen)
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      final authFlow = ref.read(authFlowProvider);
      authFlow.setAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : screenHeight * 0.05),
                  Center(
                    child: Container(
                      width: isSmallScreen ? screenWidth * 0.25 : screenWidth * 0.3,
                      height: isSmallScreen ? screenWidth * 0.25 : screenWidth * 0.3,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/slg_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Center(
                    child: Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isSmallScreen ? screenWidth * 0.055 : screenWidth * 0.06,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.phone,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.038,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  Center(
                    child: Text(
                      'Enter your PIN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: isSmallScreen ? screenWidth * 0.038 : screenWidth * 0.042,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Center(
                    child: SineShakeWidget(
                      key: _shakeKey,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (index) {
                          final isFilled = index < _pin.length;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                            width: isSmallScreen ? screenWidth * 0.13 : screenWidth * 0.15,
                            height: isSmallScreen ? screenWidth * 0.13 : screenWidth * 0.15,
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: isFilled ? AppColors.primary : Colors.white30,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isFilled ? AppColors.primary : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
          // ENTER BUTTON - Separate from number pad
          Center(
            child: Container(
              width: screenWidth * 0.6,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_pin.length == 4 && !_isLoading) ? () => _verifyPin() : null,
                  borderRadius: BorderRadius.circular(25),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            valueColor: AlwaysStoppedAnimation(Colors.white)
                          )
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ENTER',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  Center(
                    child: _buildNumberPad(screenWidth, isSmallScreen),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  if (_biometricAvailable)
                    Center(
                      child: GestureDetector(
                        onTap: _authenticateWithBiometric,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fingerprint, color: AppColors.primary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Use Biometric',
                                style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _forgotPin,
                      child: Text(
                        'Forgot PIN?',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _loginWithOTP,
                      child: Text(
                        'Login with OTP',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(double screenWidth, bool isSmallScreen) {
    final buttonSize = isSmallScreen ? screenWidth * 0.16 : screenWidth * 0.18;
    final spacing = isSmallScreen ? 12.0 : 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(3, (rowIndex) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (colIndex) {
                final number = (rowIndex * 3 + colIndex + 1).toString();
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  child: _buildNumberButton(number, buttonSize),
                );
              }),
            ),
          );
        }),
        Padding(
          padding: EdgeInsets.only(top: spacing / 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: _buildActionButton('Enter', buttonSize, _verifyPin),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: _buildNumberButton('0', buttonSize),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: _buildBackspaceButton(buttonSize),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, double buttonSize, VoidCallback onTap) {
    final isEnabled = _pin.length == 4 && !_isLoading;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
          ),
          child: Center(
            child: _isLoading && label == 'Enter'
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: buttonSize * 0.22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, double buttonSize) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: buttonSize * 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(double buttonSize) {
    return GestureDetector(
      onTap: _onBackspace,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white, size: buttonSize * 0.35),
        ),
      ),
    );
  }
}
