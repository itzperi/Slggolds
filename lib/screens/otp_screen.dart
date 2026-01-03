// lib/screens/otp_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/secure_storage_helper.dart';
import '../services/auth_service.dart';
import '../services/auth_flow_notifier.dart';
import 'customer/dashboard_screen.dart';
import 'auth/pin_setup_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final bool isResetPin;
  final Map<String, dynamic>? user;

  const OTPScreen({
    super.key,
    required this.phone,
    this.isResetPin = false,
    this.user,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());
  final TextEditingController _otpAutofillController = TextEditingController();

  bool _isLoading = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _canResend = false;
  final List<bool> _focusStates = List.generate(6, (_) => false);
  final List<String> _previousTexts = List.generate(6, (_) => '');
  String _generatedOtp = '';

  @override
  void initState() {
    super.initState();
    _generateOtp();
    _startTimer();
    // Listen for autofill OTP
    _otpAutofillController.addListener(() {
      final code = _otpAutofillController.text;
      if (code.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(code)) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = code[i];
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyOtp();
        });
      }
    });
    // Add focus listeners
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        setState(() {
          _focusStates[i] = _focusNodes[i].hasFocus;
        });
      });
      // Add typing sound listeners - play sound for both typing and deleting
      _controllers[i].addListener(() {
        final currentText = _controllers[i].text;
        // Play sound when character is added
        if (currentText.length > _previousTexts[i].length && currentText.isNotEmpty) {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
        }
        // Play sound when character is deleted
        else if (currentText.length < _previousTexts[i].length) {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
        }
        _previousTexts[i] = currentText;
      });
    }
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }


  void _generateOtp() {
    final random = Random();
    _generatedOtp = '';
    for (int i = 0; i < 6; i++) {
      _generatedOtp += random.nextInt(10).toString();
    }
    if (kDebugMode) {
      print('OTP for ${widget.phone}: $_generatedOtp');
    }
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _otpAutofillController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _checkUserExists(String phone) async {
    // Query Supabase to check if user with this phone exists
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      return response != null;
    } catch (e) {
      // If table doesn't exist or error, assume user doesn't exist
      return false;
    }
  }

  String get _otp =>
      _controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the 6-digit OTP',
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

    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Verify OTP matches generated OTP
    if (_otp != _generatedOtp) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid OTP',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        // Clear all boxes
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
      return;
    }

    // OTP verified successfully
    if (mounted) {
      final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
      
      if (widget.isResetPin) {
        authFlow.setOtpVerified(
              phoneNumber: widget.phone,
          isResetPin: true,
        );
      } else {
        final userExists = await _checkUserExists(widget.phone);

        if (userExists) {
          final isPinSet = await SecureStorageHelper.isPinSet();

          if (!isPinSet) {
            authFlow.setOtpVerified(
                  phoneNumber: widget.phone,
                  isFirstTime: true,
            );
          } else {
            // PIN is set, user is fully authenticated
            authFlow.setAuthenticated();
          }
        } else {
          await SecureStorageHelper.savePhone(widget.phone);
          authFlow.setOtpVerified(
                phoneNumber: widget.phone,
                isFirstTime: true,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    _generateOtp();
    _startTimer();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OTP resent successfully',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index, double screenWidth) {
    final isFocused = _focusStates[index];
    final hasValue = _controllers[index].text.isNotEmpty;
    
    // Calculate responsive box size - ensure 6 boxes fit with spacing
    final availableWidth = screenWidth * 0.84; // Account for padding
    final spacingBetween = screenWidth * 0.02; // 2% spacing between boxes
    final totalSpacing = spacingBetween * 5; // 5 gaps between 6 boxes
    final boxWidth = (availableWidth - totalSpacing) / 6;
    final boxHeight = boxWidth * 1.15; // Slightly taller than wide
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppColors.primaryLight
              : hasValue
                  ? AppColors.primary.withOpacity(0.8)
                  : AppColors.primary.withOpacity(0.5),
          width: isFocused ? 2.5 : hasValue ? 2 : 1.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : hasValue
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            Future.delayed(const Duration(milliseconds: 50), () {
              _focusNodes[index + 1].requestFocus();
            });
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top spacing
              SizedBox(height: screenHeight * 0.05),

              // HEADING - Premium typography matching login
              Text(
                'Verify Your Number',
                style: GoogleFonts.playfairDisplay(
                  fontSize: screenWidth * 0.072,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              // SUBHEADING - More detailed instruction
              SizedBox(height: screenHeight * 0.015),
              Text(
                'A 6-digit verification code has been sent to\n+91 ${widget.phone}',
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

              // PHONE NUMBER DISPLAY - Tappable with Edit option
              SizedBox(height: screenHeight * 0.02),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+91 ${widget.phone}',
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Change',
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // DECORATIVE LINE - Matching login screen
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

              // OTP INPUT BOXES - Enhanced spacing
              SizedBox(height: screenHeight * 0.05),
              // Hidden TextField for SMS autofill
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 0,
                  child: TextField(
                    controller: _otpAutofillController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(
                      counterText: '',
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 6; i++) ...[
                    _buildOtpBox(i, screenWidth),
                    if (i < 5) SizedBox(width: screenWidth * 0.02),
                  ],
                ],
              ),

              // VERIFY BUTTON - Matching login button style
              SizedBox(height: screenHeight * 0.05),
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
                    onTap: _isLoading ? null : _verifyOtp,
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
                          : Text(
                              'Verify OTP',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A0A0A),
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // RESEND TIMER - More elegant design
              SizedBox(height: screenHeight * 0.04),
              _canResend
                  ? GestureDetector(
                      onTap: _resendOtp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resend Code',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: const Color(0xFF9CA3AF),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resend code in $_secondsRemaining s',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),

              // Bottom spacing
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
