// lib/screens/staff/staff_login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth/auth_flow_provider.dart';
import '../../utils/constants.dart';
import '../../utils/secure_storage_helper.dart';
import '../../services/staff_auth_service.dart';
import '../../services/auth_flow_notifier.dart';
import '../../utils/shake_widget.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _staffIdFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isStaffIdFocused = false;
  bool _isPasswordFocused = false;
  final GlobalKey<SineShakeWidgetState> _shakeKey = GlobalKey<SineShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    _staffIdFocusNode.addListener(() {
      setState(() => _isStaffIdFocused = _staffIdFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    _staffIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _staffIdController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter Email and Password',
            style: GoogleFonts.inter(fontSize: 14.0),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use StaffAuthService to handle username/code mapping
      await StaffAuthService.signInWithStaffCode(
        staffCode: email,
        password: password,
      );

      if (mounted) {
        // Clear navigation stack to remove login screen and reveal dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Explicitly set authenticated to trigger dashboard navigation
        ref.read(authFlowProvider).setAuthenticated();

        setState(() {
          _isLoading = false;
        });
        debugPrint('🔵 StaffLoginScreen: Login successful for $email');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _shakeKey.currentState?.shake();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid email or password',
              style: GoogleFonts.inter(fontSize: 14.0),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      }
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
            // Back button at top left
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    ref.read(authFlowProvider).forceLogout();
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO (BIGGER SIZE matching LoginScreen)
                    Center(
                      child: Container(
                        width: screenWidth * 0.40,
                        height: screenWidth * 0.40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: screenWidth * 0.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),
                    
                    // MAIN HEADING
                    Column(
                      children: [
                        Text(
                          'SLG',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4AF37),
                            letterSpacing: 8.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'GOLDS',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4AF37),
                            letterSpacing: 8.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Staff Portal Access',
                      style: GoogleFonts.inter(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.2,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    Center(
                      child: Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    SineShakeWidget(
                      key: _shakeKey,
                      child: Column(
                        children: [
                          // STAFF ID INPUT
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isStaffIdFocused ? AppColors.primaryLight : AppColors.primary,
                                width: _isStaffIdFocused ? 2 : 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _staffIdController,
                                    focusNode: _staffIdFocusNode,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'staff@slggolds.com',
                                      hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 16),
                                      border: InputBorder.none,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // PASSWORD INPUT
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isPasswordFocused ? AppColors.primaryLight : AppColors.primary,
                                width: _isPasswordFocused ? 2 : 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Staff@123',
                                      hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 16),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _handleLogin(),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // LOGIN BUTTON (Matching "Get OTP" style)
                    Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primaryLight, AppColors.primary],
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
                          onTap: _isLoading ? null : _handleLogin,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0A)),
                                    ),
                                  )
                                : Text(
                                    'Access Portal',
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

                    const SizedBox(height: 24),

                    // FORGOT PASSWORD
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please contact system administrator to reset your password.'),
                            backgroundColor: AppColors.textSecondary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
