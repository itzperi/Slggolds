import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/secure_storage_helper.dart';
import '../../utils/biometric_helper.dart';
import '../../utils/constants.dart';
import '../customer/dashboard_screen.dart';
import '../otp_screen.dart';
import 'pin_setup_screen.dart';
import '../../services/auth_flow_notifier.dart';

class PinLoginScreen extends StatefulWidget {
  final String phone;

  const PinLoginScreen({
    super.key,
    required this.phone,
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  int _failedAttempts = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _biometricAvailable = false;

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
      // Force OTP login after 30 days
      _loginWithOTP();
    }
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
        _errorMessage = '';
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final isCorrect = await SecureStorageHelper.verifyPin(_pin);

    if (isCorrect) {
      await SecureStorageHelper.updateLastAuth();
      _navigateToDashboard();
    } else {
      if (mounted) {
        setState(() {
          _failedAttempts++;
          _pin = '';
          _isLoading = false;
          _errorMessage = 'Incorrect PIN. Try again.';
        });

        // After 3 failed attempts, force OTP
        if (_failedAttempts >= 3) {
          _showOTPForceDialog();
        }
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final authenticated = await BiometricHelper.authenticate();
    if (authenticated) {
      await SecureStorageHelper.updateLastAuth();
      _navigateToDashboard();
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
        });
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
    // Send OTP (use existing OTP sending logic)
    // Then navigate to OTP verification with reset flag
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(
            phone: widget.phone,
            isResetPin: true, // Add this parameter to OTP screen
          ),
        ),
      );
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
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

                  // Logo
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

                  // Welcome text
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

                  // Phone number
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

                  // "Enter your PIN" text
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

                  // PIN Dots
                  Center(
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
                            boxShadow: [
                              BoxShadow(
                                color: isFilled
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.transparent,
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
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

                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.danger,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Number Pad
                  Center(
                    child: _buildNumberPad(screenWidth, isSmallScreen),
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Biometric button (if available)
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
                              Icon(
                                Icons.fingerprint,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Use Biometric',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 8),

                  // Forgot PIN link
                  Center(
                    child: TextButton(
                      onPressed: _forgotPin,
                      child: Text(
                        'Forgot PIN?',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // Login with OTP link
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
              SizedBox(width: buttonSize + spacing),
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
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: buttonSize * 0.35,
          ),
        ),
      ),
    );
  }
}

