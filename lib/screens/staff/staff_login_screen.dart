// lib/screens/staff/staff_login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../utils/secure_storage_helper.dart';
import '../../services/staff_auth_service.dart';
import '../../services/auth_flow_notifier.dart';
import 'package:provider/provider.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('StaffLoginScreen: initState called - screen is being built');
  }
  final _staffIdFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    _staffIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final staffCode = _staffIdController.text.trim().toUpperCase();
    final password = _passwordController.text.trim();

    if (staffCode.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter Staff ID and Password',
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
      // Authenticate using Supabase Auth (resolves staff_code → email internally)
      await StaffAuthService.signInWithStaffCode(
        staffCode: staffCode,
        password: password,
      );

      // Save staff code for reference (not used for auth)
      await SecureStorageHelper.saveStaffId(staffCode);

      // Supabase session is now set
      // AuthGate will detect session and route via RoleRoutingService
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Auth state listener will call setAuthenticated() after access check
        // AuthGate will detect state change and route automatically - no need to pop
        debugPrint('🔵 StaffLoginScreen: Login successful. Auth listener will set authenticated state and AuthGate will route.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid Staff ID or Password',
              style: GoogleFonts.inter(fontSize: 14.0),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140A33), // Purple background
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A1454),
                Color(0xFF140A33),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Provider.of<AuthFlowNotifier>(context, listen: false).forceLogout();
                    },
                  ),
                ),

                const SizedBox(height: 40.0),

                // SLG Logo placeholder
                Container(
                  height: 100.0,
                  width: 100.0,
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
                ),

                const SizedBox(height: 40.0),

                // Title
                Text(
                  'Staff Login',
                  style: GoogleFonts.inter(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8.0),

                // Subtitle
                Text(
                  'Access your work portal',
                  style: GoogleFonts.inter(
                    fontSize: 16.0,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48.0),

                // Staff ID field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _staffIdController,
                    focusNode: _staffIdFocusNode,
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Staff ID',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Password field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                ),

                const SizedBox(height: 32.0),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 2.0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Forgot password
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Contact admin to reset password',
                          style: GoogleFonts.inter(fontSize: 14.0),
                        ),
                        backgroundColor: AppColors.textSecondary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
