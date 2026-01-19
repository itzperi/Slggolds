import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class PerformanceScreen extends ConsumerWidget {
  final String staffId;
  const PerformanceScreen({super.key, required this.staffId});

  Future<Map<String, dynamic>> _fetchPerformance() async {
    final response = await Supabase.instance.client.rpc('get_staff_performance', params: {'staff_id_param': staffId});
    return Map<String, dynamic>.from(response);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Performance', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchPerformance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          
          final data = snapshot.data!;
          return _buildBody(data);
        },
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildBadgeCard(data['badge']),
          const SizedBox(height: 24),
          _buildMetricsGrid(data),
          const SizedBox(height: 24),
          _buildCommissionChart(),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String badge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, const Color(0xffB8860B)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.black54, size: 64),
          const SizedBox(height: 12),
          Text(badge, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text('CURRENT RANKING', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricItem('Total Collected', '₹${data['total_collected']}', Icons.account_balance_wallet, Colors.green),
        _buildMetricItem('Commission', '₹${data['commission']}', Icons.monetization_on, AppColors.primary),
        _buildMetricItem('Today Leads', '12', Icons.trending_up, Colors.blue),
        _buildMetricItem('Success Rate', '94%', Icons.verified_user, Colors.purple),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildCommissionChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.backgroundLighter, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Trend', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 100, child: Center(child: Text('Chart Placeholder', style: TextStyle(color: Colors.white24)))),
        ],
      ),
    );
  }
}
