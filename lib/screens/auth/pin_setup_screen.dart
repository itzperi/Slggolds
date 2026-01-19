import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth/auth_flow_provider.dart';
import '../../utils/secure_storage_helper.dart';
import '../../utils/constants.dart';
import 'pin_login_screen.dart';
import '../../services/auth_flow_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool isFirstTime;
  final bool isReset;

  const PinSetupScreen({
    super.key,
    required this.phoneNumber,
    this.isFirstTime = false,
    this.isReset = false,
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
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
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
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

  void _onEnterPressed() {
    if (!_isConfirming) {
      if (_pin.length == 4) {
        setState(() {
          _isConfirming = true;
          _errorMessage = '';
        });
      }
    } else {
      if (_confirmPin.length == 4) {
        _verifyAndSavePin();
      }
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

    setState(() => _isLoading = true);

    try {
      await SecureStorageHelper.savePin(_pin);
      await SecureStorageHelper.savePhone(widget.phoneNumber);

      final hashedPin = SecureStorageHelper.hashPin(_pin);
      try {
        await Supabase.instance.client.rpc(
          'upsert_profile_from_mobile',
          params: {
            'phone_param': widget.phoneNumber,
            'pin_hash_param': hashedPin,
          },
        );
        
        // SYNC: Also set the Auth Password to the PIN to allow "Login with PIN" 
        // to actually create a session if the token expires.
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(password: _pin),
          );
          debugPrint('Auth password synced with PIN');
        } catch (pwError) {
          debugPrint('Password sync failed (non-critical): $pwError');
        }

      } catch (dbError) {
        debugPrint('DB PIN SAVE ERROR: $dbError');
      }

      if (widget.isReset) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PinLoginScreen(phone: widget.phoneNumber),
            ),
          );
        }
      } else {
        if (mounted) {
          final authFlow = ref.read(authFlowProvider);
          authFlow.setAuthenticated();
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
                  Center(
                    child: Text(
                      _isConfirming
                          ? 'Re-enter your 4-digit PIN'
                          : 'Enter a 4-digit PIN for quick login',
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
                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.danger, fontSize: 14),
                      ),
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 24 : 32),
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: _buildActionButton('Enter', buttonSize, _onEnterPressed),
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
    final currentPin = _isConfirming ? _confirmPin : _pin;
    final isEnabled = currentPin.length == 4 && !_isLoading;
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
