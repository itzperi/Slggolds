// lib/screens/staff/collect_tab_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../services/staff_data_service.dart';
import '../../services/role_routing_service.dart';
import 'customer_detail_screen.dart';
import 'today_target_detail_screen.dart';

class CollectTabScreen extends StatefulWidget {
  final Map<String, dynamic> staffData;

  const CollectTabScreen({super.key, required this.staffData});

  @override
  State<CollectTabScreen> createState() => _CollectTabScreenState();
}

class _CollectTabScreenState extends State<CollectTabScreen> {
  String _searchQuery = '';
  late TextEditingController _searchController;
  String _filter = 'all'; // all, due_today, pending
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _dueToday = [];
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;
  String? _staffProfileId;
  
  // Stats
  int _collectedCount = 0;
  int _totalCustomers = 0;
  double _collectedAmount = 0.0;
  double _targetAmount = 0.0;
  double _progress = 0.0;
  int _pendingCount = 0;
  List<Map<String, dynamic>> _todayCollections = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    debugPrint('CollectTabScreen._loadData: START');
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      _staffProfileId = await RoleRoutingService.getCurrentProfileId();
      debugPrint('CollectTabScreen._loadData: staffProfileId = $_staffProfileId');
      if (_staffProfileId == null) {
        debugPrint('CollectTabScreen._loadData: ERROR - staffProfileId is null');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('CollectTabScreen._loadData: Fetching data...');
      // Load all data in parallel
      final results = await Future.wait([
        StaffDataService.getAssignedCustomers(_staffProfileId!),
        StaffDataService.getDueToday(_staffProfileId!),
        StaffDataService.getPending(_staffProfileId!),
        StaffDataService.getTodayStats(_staffProfileId!),
        StaffDataService.getDailyTarget(_staffProfileId!),
        StaffDataService.getTodayCollections(_staffProfileId!),
      ]);
      debugPrint('CollectTabScreen._loadData: Data fetch completed');

      if (!mounted) return;

      _customers = results[0] as List<Map<String, dynamic>>;
      _dueToday = results[1] as List<Map<String, dynamic>>;
      _pending = results[2] as List<Map<String, dynamic>>;
      final todayStats = results[3] as Map<String, dynamic>;
      final target = results[4] as Map<String, dynamic>;
      _todayCollections = results[5] as List<Map<String, dynamic>>;

      _collectedCount = todayStats['customersCollected'] as int? ?? 0;
      _totalCustomers = todayStats['totalCustomers'] as int? ?? 0;
      _collectedAmount = (todayStats['totalAmount'] as num?)?.toDouble() ?? 0.0;
      _targetAmount = (target['amount'] as num?)?.toDouble() ?? 0.0;
      _pendingCount = todayStats['pendingCount'] as int? ?? 0;
      _progress = _targetAmount > 0 ? (_collectedAmount / _targetAmount).clamp(0.0, 1.0) : 0.0;

      // Debug logging
      debugPrint('CollectTabScreen: Loaded ${_customers.length} customers');
      debugPrint('CollectTabScreen: Due today: ${_dueToday.length}, Pending: ${_pending.length}');
      if (_customers.isNotEmpty) {
        debugPrint('CollectTabScreen: First customer: ${_customers[0]['name']} (${_customers[0]['phone']})');
      }
      debugPrint('CollectTabScreen: Search query: "$_searchQuery", Filter: $_filter');
      debugPrint('CollectTabScreen: Filtered customers: ${_filteredCustomers.length}');

      if (mounted) setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      debugPrint('CollectTabScreen._loadData: ERROR - $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    var customers = _customers;

    // Apply filter
    if (_filter == 'due_today') {
      customers = _dueToday;
    } else if (_filter == 'pending') {
      customers = _pending;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      customers = customers.where((c) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final phone = (c['phone'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    return customers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

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
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Text(
                      'Collections',
                      style: GoogleFonts.inter(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Target card - Clickable
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TodayTargetDetailScreen(
                            staffId: _staffProfileId ?? '',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TODAY\'S TARGET',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.0,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 16.0),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$_collectedCount / $_totalCustomers',
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Collected',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.0,
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 16.0),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '₹${_collectedAmount.toStringAsFixed(0)} / ₹${_targetAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: LinearProgressIndicator(
                              value: _progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '${(_progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12.0,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            '$_pendingCount Pending',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white),
                                  onPressed: () {
                                    debugPrint('CollectTabScreen: Clearing search');
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16.0),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

                // Filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', _totalCustomers),
                          const SizedBox(width: 8.0),
                          _buildFilterChip('Due Today', 'due_today', _dueToday.length),
                          const SizedBox(width: 8.0),
                          _buildFilterChip('Pending', 'pending', _pendingCount),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

                // Customer list
                _filteredCustomers.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No customers found',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildCustomerCard(_filteredCustomers[index]),
                            );
                          },
                          childCount: _filteredCustomers.length,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filter = value),
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: AppColors.primary.withOpacity(0.3),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12.0,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.3),
        width: 1.0,
      ),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final paidToday = customer['paidToday'] as bool;
    final missedCount = customer['missedPayments'] as int;
    final name = customer['name'] as String;
    final phone = customer['phone'] as String;
    final scheme = customer['scheme'] as String;
    final frequency = customer['frequency'] as String;
    final dueAmount = customer['dueAmount'] as double;

    Color borderColor = AppColors.primary.withOpacity(0.3);
    Color bgColor = Colors.white.withOpacity(0.05);

    if (paidToday) {
      borderColor = Colors.green.withOpacity(0.5);
      bgColor = Colors.green.withOpacity(0.05);
    } else if (missedCount > 0) {
      borderColor = Colors.orange.withOpacity(0.5);
      bgColor = Colors.orange.withOpacity(0.05);
    }

    // Get today's payment amount if paid
    double? paidAmount;
    if (paidToday) {
      final todayPayment = _todayCollections.firstWhere(
        (c) => c['customerId'] == customer['id'],
        orElse: () => {'amount': 0.0},
      );
      paidAmount = todayPayment['amount'] as double?;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerDetailScreen(
                  customerId: customer['id'],
                  customer: customer,
                ),
              ),
            ).then((_) => _loadData());
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: paidToday
                        ? Icon(Icons.check, color: Colors.green, size: 24.0)
                        : Text(
                            name[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (missedCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange, size: 16.0),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                '$missedCount Missed',
                                style: GoogleFonts.inter(
                                  color: Colors.orange,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        phone,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$scheme • $frequency',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 13.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      if (paidToday && paidAmount != null)
                        Text(
                          'Paid Today: ₹${paidAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: Colors.green,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (missedCount > 0)
                        Text(
                          '$missedCount Missed Payments',
                          style: GoogleFonts.inter(
                            color: Colors.orange,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Due: ₹${dueAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone, color: AppColors.primary),
                  onPressed: () async {
                    final url = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

