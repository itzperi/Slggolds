import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/biometric_helper.dart';
import '../../utils/secure_storage_helper.dart';
import '../../utils/constants.dart';
import '../customer/dashboard_screen.dart';
import '../../services/auth_flow_notifier.dart';

class BiometricSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const BiometricSetupScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isLoading = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
  }

  Future<void> _loadBiometricType() async {
    final type = await BiometricHelper.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricType = type;
      });
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    final available = await BiometricHelper.isAvailable();
    if (!available) {
      _showError('Biometric not available on this device');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final authenticated = await BiometricHelper.authenticate();
    if (authenticated) {
      await SecureStorageHelper.setBiometricEnabled(true);
      _navigateToDashboard();
    } else {
      _showError('Biometric authentication failed');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipBiometric() {
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (mounted) {
      final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
      authFlow.setAuthenticated();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Biometric Icon
              Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: screenWidth * 0.15,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              // Title
              Text(
                'Enable $_biometricType?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              Text(
                'Use $_biometricType for faster\nand more secure login',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: screenWidth * 0.038,
                  height: 1.5,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.08),

              // Enable Button
              SizedBox(
                width: double.infinity,
                height: 62,
                child: Container(
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
                      onTap: _isLoading ? null : _enableBiometric,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0A0A0A),
                                  ),
                                ),
                              )
                            : Text(
                                'Enable $_biometricType',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0A0A0A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Skip Button
              TextButton(
                onPressed: _skipBiometric,
                child: Text(
                  'Skip for Now',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




