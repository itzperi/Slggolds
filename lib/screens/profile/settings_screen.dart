import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/secure_storage_helper.dart';
import '../../utils/biometric_helper.dart';
import '../../utils/constants.dart';
import '../auth/pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load from Supabase or local storage
    final bioEnabled = await SecureStorageHelper.isBiometricEnabled();
    final bioAvailable = await BiometricHelper.isAvailable();

    if (mounted) {
      setState(() {
        _biometricEnabled = bioEnabled;
        _biometricAvailable = bioAvailable;
        // Load notification preference from database
      });
    }
  }

  Future<void> _changePin() async {
    final phone = await SecureStorageHelper.getSavedPhone();
    if (phone != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            phoneNumber: phone,
            isFirstTime: false,
            isReset: false,
          ),
        ),
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable biometric
      final authenticated = await BiometricHelper.authenticate();
      if (authenticated) {
        await SecureStorageHelper.setBiometricEnabled(true);
        if (mounted) {
          setState(() {
            _biometricEnabled = true;
          });
        }
      }
    } else {
      // Disable biometric
      await SecureStorageHelper.setBiometricEnabled(false);
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    // Save to database and update local state
    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
      });
      // TODO: Save to Supabase user preferences
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundDarker,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Change PIN
          _buildSettingCard(
            icon: Icons.lock_outline,
            title: 'Change PIN',
            subtitle: 'Update your 4-digit PIN',
            onTap: _changePin,
          ),

          const SizedBox(height: 16),

          // Biometric Login (only if available)
          if (_biometricAvailable)
            _buildSettingCard(
              icon: Icons.fingerprint,
              title: 'Biometric Login',
              subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
                activeColor: AppColors.primary,
              ),
            ),

          if (_biometricAvailable) const SizedBox(height: 16),

          // Notifications
          _buildSettingCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          // App Version (non-interactive)
          _buildSettingCard(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: 'Version 1.0.0 (MVP)',
            onTap: null, // Not clickable
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),

                const SizedBox(width: 16),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing (arrow or switch)
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white30,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

