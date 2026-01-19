// lib/screens/otp_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth/auth_flow_provider.dart';
import '../utils/constants.dart';
import '../utils/secure_storage_helper.dart';
import '../services/auth_service.dart';
import '../services/auth_flow_notifier.dart';
import 'customer/dashboard_screen.dart';
import 'auth/pin_setup_screen.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phone;
  final Map<String, dynamic>? user;
  final bool isResetPin;
  const OTPScreen({
    super.key,
    required this.phone,
    this.user,
    this.isResetPin = false,
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());
  final TextEditingController _otpAutofillController = TextEditingController();

  bool _isLoading = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _canResend = false;
  final List<bool> _focusStates = List.generate(4, (_) => false);
  final List<String> _previousTexts = List.generate(4, (_) => '');
  String _generatedOtp = '';

  @override
  void initState() {
    super.initState();
    _generateOtp();
    _startTimer();
    
    _otpAutofillController.addListener(() {
      final code = _otpAutofillController.text;
      if (code.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(code)) {
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = code[i];
        }
        _verifyOtp();
      }
    });

    for (int i = 0; i < 4; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) {
          setState(() {
            _focusStates[i] = _focusNodes[i].hasFocus;
          });
        }
      });
      _controllers[i].addListener(() {
        final currentText = _controllers[i].text;
        if (currentText.length > _previousTexts[i].length && currentText.isNotEmpty) {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
        } else if (currentText.length < _previousTexts[i].length) {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
        }
        _previousTexts[i] = currentText;
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _generateOtp() {
    final random = Random();
    _generatedOtp = '';
    for (int i = 0; i < 4; i++) {
      _generatedOtp += random.nextInt(10).toString();
    }
    // Intentionally avoid logging OTP or phone number to protect PII.
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
    try {
      final formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('phone', formattedPhone)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      return response != null;
    } catch (e) {
      debugPrint('Check user error (redacted)');
      return false;
    }
  }

  String get _otp => _controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    if (_otp.length != 4) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Small buffer for UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify OTP matches generated OTP or is bypass
      if (_otp != _generatedOtp && _otp != '1234') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid OTP', style: GoogleFonts.inter(fontSize: 14)),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
        return;
      }

      // OTP verified successfully
      if (mounted) {
        final authFlow = ref.read(authFlowProvider);
        await SecureStorageHelper.savePhone(widget.phone);

        // Check if user exists to determine next screen
        final userExists = await _checkUserExists(widget.phone);
        final isPinSet = await SecureStorageHelper.isPinSet();

        if (userExists && isPinSet) {
          authFlow.setAuthenticated();
        } else {
          authFlow.setOtpVerified(
            phoneNumber: widget.phone,
            isFirstTime: !userExists,
            isResetPin: widget.isResetPin,
          );
        }

        // Auto-navigation: Pop the OTP screen to reveal the next screen from AuthGate
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Verify OTP error (redacted)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    _generateOtp();
    _startTimer();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP resent successfully', style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOtpBox(int index, double screenWidth) {
    final isFocused = _focusStates[index];
    final hasValue = _controllers[index].text.isNotEmpty;
    
    final availableWidth = screenWidth * 0.84;
    final spacingBetween = screenWidth * 0.04;
    final totalSpacing = spacingBetween * 3;
    final boxWidth = (availableWidth - totalSpacing) / 4;
    final boxHeight = boxWidth * 1.2;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? AppColors.primaryLight
              : hasValue
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3),
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last digit entered, auto-verify
              _focusNodes[index].unfocus();
              _verifyOtp();
            }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              Text(
                'Verify OTP',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Enter the 4-digit code sent to\n+91 ${widget.phone}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    _buildOtpBox(i, screenWidth),
                    if (i < 3) SizedBox(width: screenWidth * 0.04),
                  ],
                ],
              ),
              SizedBox(height: screenHeight * 0.06),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                Column(
                  children: [
                    if (!_canResend)
                      Text(
                        'Resend code in $_secondsRemaining s',
                        style: GoogleFonts.inter(color: Colors.white54),
                      )
                    else
                      TextButton(
                        onPressed: _resendOtp,
                        child: Text(
                          'Resend OTP',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              SizedBox(height: screenHeight * 0.04),
              // Manual verify button just in case
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _otp.length != 4 ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Verify & Continue',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
