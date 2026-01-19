import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';

class RouteManagementScreen extends StatelessWidget {
  final String staffId;
  const RouteManagementScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Field Operations', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.primary),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSyncStatusIndicator(),
            const SizedBox(height: 24),
            _buildMapPlaceholder(),
            const SizedBox(height: 24),
            _buildRouteList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text('Offline: 3 pending sync', style: GoogleFonts.inter(color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text('Route View', style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteList() {
    return Column(
      children: [
        _buildRouteItem('Customer: Ravi S', 'Current Location: North Sector', true),
        _buildRouteItem('Customer: Anitha K', 'Next Stop: 0.5km away', false),
        _buildRouteItem('Customer: Mohan P', 'Route: West Gate', false),
      ],
    );
  }

  Widget _buildRouteItem(String title, String subtitle, bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.white24),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        trailing: const Icon(Icons.drag_handle, color: Colors.white24),
      ),
    );
  }
}
