import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../state/staff/staff_dashboard_provider.dart';

class StaffHomeScreen extends ConsumerWidget {
  final String staffId;
  const StaffHomeScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream data from provider (using realtime)
    final dashboardData = ref.watch(staffDashboardProvider(staffId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      body: dashboardData.when(
        data: (data) {
          // Check for empty state from RPC result
          final bool isEmptyState = data['is_empty_state'] == true;
          
          if (isEmptyState) {
            return _buildEmptyState();
          }
          
          return _buildDashboard(context, data);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          Text(
            "Welcome, Staff Member!",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Waiting for customer assignments...",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
               // Placeholder for "Contact Admin"
            },
            icon: const Icon(Icons.support_agent),
            label: const Text("Contact Admin"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          _buildHeader(data),
          const SizedBox(height: 24),
          _buildMetricsGrid(data),
          const SizedBox(height: 24),
          _buildProgressCard(data),
          const SizedBox(height: 24),
          _buildOverviewSection(data),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Overview',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Target: ₹${data['daily_target'] ?? 0}',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'MAKE THIS HAPPEN',
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Collected Today', '₹${data['collected_today'] ?? 0}', Icons.payments),
        _buildMetricCard('Customers', '${data['assigned_customers_count'] ?? 0}', Icons.person),
        _buildMetricCard('Visited Today', '${data['visited_today'] ?? 0}', Icons.check_circle),
        _buildMetricCard('Yesterday', '₹${data['yesterday_collection'] ?? 0}', Icons.history),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> data) {
    final achievementP = (data['achievement_pct'] ?? 0).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), Colors.black26],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Achievement', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${achievementP.toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (achievementP / 100).clamp(0, 1),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route Progress', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'You have visited ${data['visited_today'] ?? 0} out of ${data['assigned_customers_count'] ?? 0} customers today.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
