// lib/screens/staff/staff_account_info_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../utils/constants.dart';
import '../../services/staff_data_service.dart';

class StaffAccountInfoScreen extends StatefulWidget {
  final String staffId;

  const StaffAccountInfoScreen({super.key, required this.staffId});

  @override
  State<StaffAccountInfoScreen> createState() => _StaffAccountInfoScreenState();
}

class _StaffAccountInfoScreenState extends State<StaffAccountInfoScreen> {
  Map<String, dynamic>? _staffInfo;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    try {
      final profile = await StaffDataService.getStaffProfile(widget.staffId);
      if (!mounted) return;
      
      setState(() {
        _staffInfo = profile ?? {};
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('StaffAccountInfoScreen._loadStaffData FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
        _staffInfo = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Failed to load account information',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _loadStaffData();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final staffInfo = _staffInfo ?? {};

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2A1454),
                const Color(0xFF140A33),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account Information',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoCard('Name', staffInfo['name'] ?? 'Unknown'),
                      const SizedBox(height: 16),
                      _buildInfoCard('Staff ID', staffInfo['staff_code'] ?? widget.staffId),
                      const SizedBox(height: 16),
                      _buildInfoCard('Phone', staffInfo['phone'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _buildInfoCard('Email', staffInfo['email'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _buildInfoCard('Role', staffInfo['role'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Join Date',
                        _formatDate(staffInfo['join_date'] ?? ''),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

