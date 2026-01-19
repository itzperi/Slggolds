import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../state/staff/staff_dashboard_provider.dart';
import 'customer_detail_screen.dart';

class AssignedCustomersScreen extends ConsumerStatefulWidget {
  final String staffId;
  const AssignedCustomersScreen({super.key, required this.staffId});

  @override
  ConsumerState<AssignedCustomersScreen> createState() => _AssignedCustomersScreenState();
}

class _AssignedCustomersScreenState extends ConsumerState<AssignedCustomersScreen> {
  String _currentFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(assignedCustomersProvider((staffId: widget.staffId, filter: _currentFilter)));

    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Customers', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(),
            ],
          ),
        ),
      ),
      body: customersAsync.when(
        data: (customers) => _buildCustomerList(customers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          hintText: 'Search name or phone...',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: ['all', 'overdue', 'today', 'this_week'].map((f) {
          final isSelected = _currentFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(f.toUpperCase().replaceAll('_', ' ')),
              selected: isSelected,
              onSelected: (val) => setState(() => _currentFilter = f),
              backgroundColor: Colors.white12,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerList(List<Map<String, dynamic>> customers) {
    final filtered = customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString();
      return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text('No customers found', style: GoogleFonts.inter(color: Colors.white38)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        return _buildCustomerCard(c);
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> c) {
    final overdue = (c['days_overdue'] ?? 0) as int;
    final isPriority = overdue > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPriority ? AppColors.danger.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(c['name'] ?? 'Unknown', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(c['phone'] ?? '', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 4),
            Text(c['route_name'] ?? 'No Route', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${c['next_due_amount']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            if (isPriority)
              Text('$overdue Days Overdue', style: GoogleFonts.inter(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(
                customer: c,
                staffId: widget.staffId,
              ),
            ),
          );
        },
      ),
    );
  }
}
