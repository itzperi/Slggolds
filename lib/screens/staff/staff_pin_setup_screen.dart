// lib/screens/staff/staff_pin_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/secure_storage_helper.dart';
import '../../utils/biometric_helper.dart';
import 'staff_dashboard.dart';

class StaffPinSetupScreen extends StatefulWidget {
  final String staffId;

  const StaffPinSetupScreen({super.key, required this.staffId});

  @override
  State<StaffPinSetupScreen> createState() => _StaffPinSetupScreenState();
}

class _StaffPinSetupScreenState extends State<StaffPinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';

      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += number;
          if (_pin.length == 4) {
            // Move to confirm stage
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isConfirming = true;
                });
              }
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
          if (_confirmPin.length == 4) {
            // Both PINs entered, verify match
            _verifyAndSavePin();
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      if (!_isConfirming) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _showBiometricSetupDialog() async {
    final biometricType = await BiometricHelper.getBiometricTypeName();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F4F),
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enable $biometricType?',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Use $biometricType for faster and more secure login',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToDashboard();
            },
            child: Text(
              'Skip for Now',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _enableBiometric();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Enable',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    final authenticated = await BiometricHelper.authenticate();
    if (authenticated) {
      await SecureStorageHelper.setBiometricEnabled(true);
      _navigateToDashboard();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Biometric authentication failed',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        // Still navigate to dashboard even if biometric fails
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _navigateToDashboard();
          }
        });
      }
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StaffDashboard(staffId: widget.staffId),
        ),
      );
    }
  }

  Future<void> _verifyAndSavePin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
        _confirmPin = '';
      });
      return;
    }

    // PINs match, save
    setState(() => _isLoading = true);

    try {
      // Save PIN hash to secure storage
      final hashedPin = SecureStorageHelper.hashPin(_pin);
      await SecureStorageHelper.saveStaffPin(_pin);
      await SecureStorageHelper.saveStaffId(widget.staffId);

      // Update database: set has_pin = true
      try {
        await Supabase.instance.client
            .from('staff')
            .update({'has_pin': true, 'pin_hash': hashedPin})
            .eq('staff_id', widget.staffId);
      } catch (e) {
        print('Error updating staff PIN in database: $e');
        // Continue even if database update fails (mock data scenario)
      }

      // Check if biometric is available and offer setup
      if (mounted) {
        final biometricAvailable = await BiometricHelper.isAvailable();
        if (biometricAvailable) {
          // Show biometric setup option
          _showBiometricSetupDialog();
        } else {
          // No biometric, go directly to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StaffDashboard(staffId: widget.staffId),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving PIN. Please try again.';
          _isLoading = false;
        });
      }
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'SLG',
                            style: GoogleFonts.inter(
                              fontSize: 32.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Title
                  Center(
                    child: Text(
                      _isConfirming ? 'Confirm Your PIN' : 'Set Up Your PIN',
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

                  // Subtitle
                  Center(
                    child: Text(
                      _isConfirming
                          ? 'Re-enter your 4-digit PIN'
                          : 'Create a 4-digit PIN for quick login',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.038,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // PIN Dots Display
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (index) {
                        final currentPin = _isConfirming ? _confirmPin : _pin;
                        final isFilled = index < currentPin.length;

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

                  if (_isLoading) ...[
                    SizedBox(height: 12),
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ],

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Number Pad
                  Center(
                    child: _buildNumberPad(screenWidth, isSmallScreen),
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
          border: Border.all(
            color: Colors.white30,
            width: 1,
          ),
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
          border: Border.all(
            color: Colors.white30,
            width: 1,
          ),
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

