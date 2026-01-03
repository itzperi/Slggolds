// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/secure_storage_helper.dart';
import '../services/auth_service.dart';
import '../services/auth_flow_notifier.dart';
import 'otp_screen.dart';
import 'auth/pin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isFocused = false;
  bool _hasSavedPhone = false;
  String? _savedPhone;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _phoneController.addListener(_onTextChanged);
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final savedPhone = await SecureStorageHelper.getSavedPhone();
    if (savedPhone != null && mounted) {
      setState(() {
        _phoneController.text = savedPhone;
        _hasSavedPhone = true;
        _savedPhone = savedPhone;
      });
    }
  }

  void _onTextChanged() {
    // Play premium typing sound when text changes
    if (_phoneController.text.isNotEmpty) {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    debugPrint('🔴 LoginScreen: dispose() called - CLEANING UP');
    _phoneController.removeListener(_onTextChanged);
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<String> _getButtonText() async {
    if (_hasSavedPhone && _phoneController.text == _savedPhone) {
      final isPinSet = await SecureStorageHelper.isPinSet();
      return isPinSet ? 'Continue with PIN' : 'Get OTP';
    }
    return 'Get OTP';
  }

  Future<void> _onButtonPressed() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phone number is required',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid 10-digit number',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Check if continuing with PIN
    if (_hasSavedPhone && phone == _savedPhone) {
      final isPinSet = await SecureStorageHelper.isPinSet();
      if (isPinSet) {
        // Navigate to PIN login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PinLoginScreen(phone: phone),
            ),
          );
        }
        return;
      }
    }

    // Otherwise, send OTP
    await _sendOtp();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final cleanedPhone = phone.trim();

    debugPrint("Checking phone: $cleanedPhone");

    try {
      final user = await supabase
          .schema('public')
          .from('users')
          .select('id, phone, role, is_active, is_developer')
          .eq('phone', cleanedPhone)
          .maybeSingle();

      debugPrint("Supabase response: $user");

      if (user == null) {
        _showError("This number is not registered");
        return;
      }

      if (user['is_active'] != true) {
        _showError("Account is inactive");
        return;
      }

      // SUCCESS
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              phone: cleanedPhone,
              user: user,
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint("PHONE CHECK ERROR: $e");
      debugPrintStack(stackTrace: stack);
      _showError("Error checking phone number");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top spacing
              SizedBox(height: screenHeight * 0.08),

              // LOGO - Centered with brightness/glow (BIGGER SIZE)
              Center(
                child: Container(
                  width: screenWidth * 0.45,
                  height: screenWidth * 0.45,
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

              // MAIN HEADING - Original typography
              SizedBox(height: screenHeight * 0.045),
              Column(
                children: [
                  Text(
                    'SLG',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 8.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'GOLDS',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 8.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // SUBHEADING - Original styling
              SizedBox(height: screenHeight * 0.012),
              Text(
                'Invest in Your Legacy.',
                style: GoogleFonts.inter(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.2,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              // DECORATIVE LINE - Centered
              SizedBox(height: screenHeight * 0.04),
              Center(
                child: Container(
                  width: 60,
                  height: 2.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.primary,
                  ),
                ),
              ),

              // PHONE NUMBER QUESTION
              SizedBox(height: screenHeight * 0.065),
              Text(
                "What's your phone number?",
                style: GoogleFonts.inter(
                  fontSize: screenWidth * 0.052,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              // INPUT FIELD - Clean focus state
              SizedBox(height: screenHeight * 0.025),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.primaryLight
                        : AppColors.primary,
                    width: _isFocused ? 2 : 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+91',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 1,
                      height: 20,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 10-digit number',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        maxLength: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // GET OTP BUTTON - Single shadow, clean
              SizedBox(height: screenHeight * 0.03),
              Container(
                height: 62,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                    child: InkWell(
                    onTap: _isLoading ? null : _onButtonPressed,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0A0A0A),
                                ),
                              ),
                            )
                          : FutureBuilder<String>(
                              future: _getButtonText(),
                              builder: (context, snapshot) {
                                final buttonText = snapshot.data ?? 'Get OTP';
                                return Text(
                                  buttonText,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0A0A0A),
                                    letterSpacing: 0.5,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),

              // Login with OTP link (only show if user has saved phone and PIN)
              if (_hasSavedPhone && _phoneController.text == _savedPhone)
                FutureBuilder<bool>(
                  future: SecureStorageHelper.isPinSet(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.015),
                        child: TextButton(
                          onPressed: _sendOtp,
                          child: Text(
                            'Login with OTP instead',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

              // LEGAL TEXT - Clean
              SizedBox(height: screenHeight * 0.035),
              Text.rich(
                TextSpan(
                  text: 'By proceeding, you accept the ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Terms and Conditions
                        },
                        child: Text(
                          'Terms and Conditions',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '. '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Privacy Policy
                        },
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
                  ],
                ),
              ),
            ),
            // Staff Login Button - Fixed at bottom, outside scroll
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 16),
              child: Column(
                children: [
              // Divider
              Center(
                child: Container(
                  width: 100,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
                  const SizedBox(height: 16),
              // Staff Login Button
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    debugPrint('LoginScreen: Staff Login button tapped');
                    final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
                    debugPrint('LoginScreen: Got instance hashCode = ${authFlow.hashCode}');
                    authFlow.goToStaffLogin();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Staff Login',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }
}
