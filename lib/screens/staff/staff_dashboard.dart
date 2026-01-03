// lib/screens/staff/staff_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../utils/constants.dart';
import '../../services/staff_data_service.dart';
import 'collect_tab_screen.dart';
import 'reports_screen.dart';
import 'staff_profile_screen.dart';

class StaffDashboard extends StatefulWidget {
  final String staffId;

  const StaffDashboard({
    super.key,
    required this.staffId,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;
  List<Widget>? _screens;
  Map<String, dynamic>? _staffData;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    debugPrint('StaffDashboard._loadStaffData: START - staffId=${widget.staffId}');
    try {
      final profile = await StaffDataService.getStaffProfile(widget.staffId);
      debugPrint('StaffDashboard._loadStaffData: Profile loaded: ${profile != null}');
      if (!mounted) {
        debugPrint('StaffDashboard._loadStaffData: Widget not mounted, returning');
        return;
      }
      
      debugPrint('StaffDashboard._loadStaffData: Setting state with screens');
      setState(() {
        _staffData = profile ?? {};
        _isLoading = false;
        _screens = [
          CollectTabScreen(staffData: _staffData ?? {}),
          ReportsScreen(staffId: widget.staffId),
          StaffProfileScreen(staffId: widget.staffId),
        ];
      });
      debugPrint('StaffDashboard._loadStaffData: State updated, _isLoading=false');
    } catch (e, stackTrace) {
      debugPrint('StaffDashboard._loadStaffData FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        debugPrint('StaffDashboard._loadStaffData: Widget not mounted after error, returning');
        return;
      }
      
      debugPrint('StaffDashboard._loadStaffData: Setting error state');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load staff data. Please try again.';
        _isLoading = false;
        _staffData = {};
        _screens = [
          CollectTabScreen(staffData: {}),
          ReportsScreen(staffId: widget.staffId),
          StaffProfileScreen(staffId: widget.staffId),
        ];
      });
      debugPrint('StaffDashboard._loadStaffData: Error state set, _isLoading=false');
    }
  }

  void _showFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('StaffDashboard.build: _isLoading=$_isLoading, _hasError=$_hasError, _screens=${_screens != null}');
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF140A33), // Match app background
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_hasError && _screens == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF140A33), // Match app background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An error occurred',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
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

    return Scaffold(
      backgroundColor: const Color(0xFF140A33), // Match app background
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens ?? [
          CollectTabScreen(staffData: _staffData ?? {}),
          ReportsScreen(staffId: widget.staffId),
          StaffProfileScreen(staffId: widget.staffId),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A1F4F),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _showFeedback();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF2A1F4F),
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.white60,
          selectedFontSize: 12.0,
          unselectedFontSize: 12.0,
          iconSize: 26.0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.payment : Icons.payment_outlined),
              label: 'Collect',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Icons.assessment : Icons.assessment_outlined),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 ? Icons.person : Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
