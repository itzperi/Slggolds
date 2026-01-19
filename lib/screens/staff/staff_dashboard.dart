// lib/screens/staff/staff_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import 'staff_home_screen.dart';
import 'assigned_customers_screen.dart';
import 'collect_tab_screen.dart'; // Using as Payments/Collect
import 'performance_screen.dart';
import 'route_management_screen.dart';
import 'staff_profile_screen.dart';

class StaffDashboard extends ConsumerStatefulWidget {
  final String staffId;

  const StaffDashboard({
    super.key,
    required this.staffId,
  });

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  int _currentIndex = 0;

  void _showFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      StaffHomeScreen(staffId: widget.staffId),
      AssignedCustomersScreen(staffId: widget.staffId),
      CollectTabScreen(staffData: {'id': widget.staffId}), // Core Payment capability
      PerformanceScreen(staffId: widget.staffId),
      RouteManagementScreen(staffId: widget.staffId),
      StaffProfileScreen(staffId: widget.staffId),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _showFeedback();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.white38,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Customers'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Performance'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Route'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
