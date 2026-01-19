// lib/screens/staff/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/staff_data_service.dart';
import '../../services/role_routing_service.dart';
import 'customer_detail_screen.dart';
import 'today_target_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String staffId;

  const ReportsScreen({super.key, required this.staffId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic> _todayStats = {};
  List<Map<String, dynamic>> _priorityCustomers = [];
  Map<String, double> _schemeBreakdown = {'Gold': 0.0, 'Silver': 0.0};
  bool _isLoading = true;
  String? _staffProfileId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _staffProfileId = await RoleRoutingService.getCurrentProfileId();
      if (_staffProfileId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        StaffDataService.getTodayStats(_staffProfileId!),
        StaffDataService.getPriorityCustomers(_staffProfileId!),
        StaffDataService.getSchemeBreakdown(_staffProfileId!),
      ]);

      if (!mounted) return;

      setState(() {
        _todayStats = results[0] as Map<String, dynamic>;
        _priorityCustomers = results[1] as List<Map<String, dynamic>>;
        _schemeBreakdown = results[2] as Map<String, double>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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

    final staffName = 'Staff'; // Can fetch from profile if needed
    final staffId = widget.staffId;

    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());
    
    // Calculate GST breakdown for today's performance
    final totalAmount = (_todayStats['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final gstAmount = totalAmount * 0.03;
    final netInvestment = totalAmount * 0.97;

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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: GoogleFonts.inter(
                            fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Staff: $staffId ($staffName)',
                          style: GoogleFonts.inter(
                            fontSize: 12.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                  ],
                ),
              ),

                  // TODAY'S PERFORMANCE
                  _buildSectionHeader('TODAY\'S PERFORMANCE'),
                  const SizedBox(height: 12.0),
                  Container(
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
                      children: [
                        Text(
                          today,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹${totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 36.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'Total Collected',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // GST Breakdown
                        Text(
                          'GST (3%): ₹${gstAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: Colors.orange,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Net Investment: ₹${netInvestment.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              '${(_todayStats['customersCollected'] as int?) ?? 0} / ${(_todayStats['totalCustomers'] as int?) ?? 0}',
                              'Customers',
                            ),
                            Container(
                              width: 1.0,
                              height: 40.0,
                              color: Colors.white.withOpacity(0.24),
                            ),
                            _buildStatItem(
                              '${((_todayStats['completionPercent'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}%',
                              'Completion',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12.0),
                        GestureDetector(
                          onTap: () => _showPaymentMethodDetails(context, 'cash'),
                          child: Row(
                            children: [
                              Icon(Icons.payments, color: Colors.white.withOpacity(0.7), size: 18.0),
                              const SizedBox(width: 8.0),
                              Text(
                                'Cash: ',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14.0,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '₹${((_todayStats['cashAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.3),
                                size: 12.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () => _showPaymentMethodDetails(context, 'upi'),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.white.withOpacity(0.7), size: 18.0),
                              const SizedBox(width: 8.0),
                              Text(
                                'UPI: ',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14.0,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '₹${((_todayStats['upiAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.3),
                                size: 12.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () => _showPendingCustomers(context),
                              child: _buildWarningItem(
                                (_todayStats['pendingCount'] as int?)?.toString() ?? '0',
                                'Pending',
                                Colors.orange,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAllPriorityCustomers(context),
                              child: _buildWarningItem(
                                (_todayStats['missedPaymentsCount'] as int?)?.toString() ?? '0',
                                'Missed Payments',
                                AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // PENDING COLLECTIONS
                  _buildSectionHeader('PENDING COLLECTIONS'),
                  const SizedBox(height: 12.0),

                  if (_priorityCustomers.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: _buildCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: AppColors.danger, size: 20.0),
                              const SizedBox(width: 8.0),
                              Text(
                                'PRIORITY (${_priorityCustomers.length})',
                                style: GoogleFonts.inter(
                                  color: AppColors.danger,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Customers with missed payments',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12.0,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ..._priorityCustomers.take(5).map((customer) {
                            final missedCount = customer['missedPayments'] as int;
                            final totalDue = StaffDataService.calculateTotalDue(customer);
                            final name = customer['name'] as String;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: AppColors.danger.withOpacity(0.3),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerDetailScreen(
                                          staffId: widget.staffId,
                                          customer: customer,
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.0,
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            name[0].toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: AppColors.danger,
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              '$missedCount missed • ₹${totalDue.toStringAsFixed(0)} due',
                                              style: GoogleFonts.inter(
                                                color: AppColors.danger.withOpacity(0.8),
                                                fontSize: 12.0,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white.withOpacity(0.3),
                                        size: 16.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          if (_priorityCustomers.length > 5)
                            TextButton(
                              onPressed: () => _showAllPriorityCustomers(context),
                              child: Text(
                                'View All (${_priorityCustomers.length})',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],

                  // Due Today count
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: _buildCardDecoration(),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange, size: 20.0),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(
                                'DUE TODAY',
                        style: GoogleFonts.inter(
                                  color: Colors.orange,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '${_priorityCustomers.length} customers',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TodayTargetDetailScreen(
                                  staffId: widget.staffId,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: GoogleFonts.inter(
                          color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // COLLECTION BREAKDOWN
                  if ((_schemeBreakdown['Gold'] ?? 0.0) > 0 || (_schemeBreakdown['Silver'] ?? 0.0) > 0) ...[
                    _buildSectionHeader('COLLECTION BREAKDOWN'),
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: _buildCardDecoration(),
                      child: Column(
                        children: [
                          if ((_schemeBreakdown['Gold'] ?? 0.0) > 0)
                            GestureDetector(
                              onTap: () => _showSchemeBreakdown(context, 'gold', _schemeBreakdown['Gold'] ?? 0.0),
                              child: _buildBreakdownRow(
                                'Gold Schemes',
                                _schemeBreakdown['Gold'] ?? 0.0,
                                AppColors.primary,
                              ),
                            ),
                          if ((_schemeBreakdown['Gold'] ?? 0.0) > 0 && (_schemeBreakdown['Silver'] ?? 0.0) > 0)
                            const SizedBox(height: 12.0),
                          if ((_schemeBreakdown['Silver'] ?? 0.0) > 0)
                            GestureDetector(
                              onTap: () => _showSchemeBreakdown(context, 'silver', _schemeBreakdown['Silver'] ?? 0.0),
                              child: _buildBreakdownRow(
                                'Silver Schemes',
                                _schemeBreakdown['Silver'] ?? 0.0,
                                Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32.0),
                ],
              ),
            ),
          ),
                                ),
                              ),
                            );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16.0),
      border: Border.all(
        color: AppColors.primary.withOpacity(0.3),
        width: 1.0,
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12.0,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildWarningItem(String value, String label, Color color) {
    return Row(
      children: [
        Icon(
          label.contains('Pending') ? Icons.pending_actions : Icons.warning_amber,
          color: color,
          size: 18.0,
        ),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11.0,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color) {
    final total = (_todayStats['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4.0),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 12.0,
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11.0,
            ),
          ),
        ),
      ],
    );
  }

  // Show payment method details modal
  Future<void> _showPaymentMethodDetails(BuildContext context, String method) async {
    final todayCollections = await StaffDataService.getTodayCollections(_staffProfileId ?? '');
    final payments = todayCollections
        .where((p) => p['method'] == method)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1F4F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${method.toUpperCase()} Payments Today',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No ${method.toUpperCase()} payments today',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.0,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final amount = payment['amount'] as double;
                    final customerName = payment['customerName'] as String;
                    final scheme = payment['scheme'] as String;
                    final time = payment['time'] as String? ?? '';

    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.0,
        ),
      ),
                      child: Row(
                        children: [
                          Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                                  customerName,
            style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
          Text(
                                  scheme,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
                                    fontSize: 12.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (time.isNotEmpty) ...[
                                  const SizedBox(height: 2.0),
                                  Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11.0,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
        ],
      ),
    );
                  },
                ),
              ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
                    'Total',
          style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
          ),
        ),
        Text(
                    '₹${payments.fold<double>(0.0, (sum, p) => sum + (p['amount'] as double)).toStringAsFixed(0)}',
          style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
          ),
        ),
      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show all priority customers
  void _showAllPriorityCustomers(BuildContext context) {
    final priorityCustomers = _priorityCustomers;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1F4F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIORITY CUSTOMERS',
                      style: GoogleFonts.inter(
                        color: AppColors.danger,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${priorityCustomers.length} customers with missed payments',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: priorityCustomers.length,
                itemBuilder: (context, index) {
                  final customer = priorityCustomers[index];
                  final missedCount = customer['missedPayments'] as int;
                  final totalDue = StaffDataService.calculateTotalDue(customer);
                  final name = customer['name'] as String;

    return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CustomerDetailScreen(
                                  staffId: widget.staffId,
                                  customer: customer,
                                ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: AppColors.danger,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '$missedCount missed • ₹${totalDue.toStringAsFixed(0)} due',
                                      style: GoogleFonts.inter(
                                        color: AppColors.danger.withOpacity(0.8),
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
          Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.3),
                                size: 16.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show pending customers
  Future<void> _showPendingCustomers(BuildContext context) async {
    final pendingCustomers = await StaffDataService.getPending(_staffProfileId ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1F4F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENDING CUSTOMERS',
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${pendingCustomers.length} customers pending collection',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: pendingCustomers.length,
                itemBuilder: (context, index) {
                  final customer = pendingCustomers[index];
                  final missedCount = customer['missedPayments'] as int;
                  final dueAmount = customer['dueAmount'] as double;
                  final name = customer['name'] as String;
                  final scheme = customer['scheme'] as String;

                  final hasMissed = missedCount > 0;
                  final borderColor = hasMissed
                      ? AppColors.danger.withOpacity(0.5)
                      : Colors.orange.withOpacity(0.3);
                  final bgColor = hasMissed
                      ? AppColors.danger.withOpacity(0.05)
                      : Colors.white.withOpacity(0.05);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CustomerDetailScreen(
                                  staffId: widget.staffId,
                                  customer: customer,
                                ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: hasMissed
                                      ? AppColors.danger.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: hasMissed
                                      ? Icon(
                                          Icons.warning_amber,
            color: AppColors.danger,
                                          size: 20.0,
                                        )
                                      : Text(
                                          name[0].toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: Colors.orange,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                      name,
                  style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    if (hasMissed)
                                      Text(
                                        '⚠️ $missedCount Missed Payments',
                                        style: GoogleFonts.inter(
                                          color: AppColors.danger.withOpacity(0.8),
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else
                                      Text(
                                        'Due: ₹${dueAmount.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(
                                          color: Colors.orange,
                                          fontSize: 12.0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      scheme,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.3),
                                size: 16.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show best day details
  Future<void> _showBestDayDetails(BuildContext context, String bestDay) async {
    // Parse date (format: "Dec 12")
    final now = DateTime.now();
    final year = now.year;
    DateTime? targetDate;

    try {
      final parts = bestDay.split(' ');
      if (parts.length == 2) {
        final monthName = parts[0];
        final day = int.parse(parts[1]);

        final monthMap = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
          'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
          'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
        };

        final month = monthMap[monthName];
        if (month != null) {
          targetDate = DateTime(year, month, day);
        }
      }
    } catch (e) {
      // If parsing fails, use today
      targetDate = DateTime.now();
    }

    // Get mock collections for that day (in real app, query by date)
    final todayCollections = await StaffDataService.getTodayCollections(_staffProfileId ?? '');
    final dayCollections = todayCollections; // Mock: showing today's collections

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1F4F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTIONS ON $bestDay',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${dayCollections.length} payments collected',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: dayCollections.isEmpty
                  ? Center(
                      child: Text(
                        'No collections on this day',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.0,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dayCollections.length,
                      itemBuilder: (context, index) {
                        final collection = dayCollections[index];
                        final amount = collection['amount'] as double;
                        final customerName = collection['customerName'] as String;
                        final scheme = collection['scheme'] as String;
                        final method = collection['method'] as String;
                        final time = collection['time'] as String? ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: GoogleFonts.inter(
                    color: Colors.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                  ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                ),
                                    const SizedBox(height: 4.0),
                Text(
                                      scheme,
                  style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 2.0),
                                      Row(
                                        children: [
                                          Text(
                                            method.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: AppColors.primary,
                                              fontSize: 11.0,
                                            ),
                                          ),
                                          Text(
                                            ' • $time',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 11.0,
                  ),
                ),
              ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
            ),
          ),
        ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${dayCollections.fold<double>(0.0, (sum, p) => sum + (p['amount'] as double)).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show scheme breakdown details
  Future<void> _showSchemeBreakdown(BuildContext context, String assetType, double totalAmount) async {
    final todayCollections = await StaffDataService.getTodayCollections(_staffProfileId ?? '');
    final assignedCustomers = await StaffDataService.getAssignedCustomers(_staffProfileId ?? '');

    // Filter collections by scheme type
    final filteredCollections = todayCollections.where((collection) {
      final customerId = collection['customerId'] as String;
      final customer = assignedCustomers.firstWhere(
        (c) => c['id'] == customerId,
        orElse: () => <String, dynamic>{},
      );
      if (customer.isEmpty) return false;
      final scheme = customer['scheme'] as String;
      return assetType == 'gold' ? scheme.contains('Gold') : scheme.contains('Silver');
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1F4F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${assetType.toUpperCase()} SCHEMES BREAKDOWN',
                      style: GoogleFonts.inter(
                        color: assetType == 'gold' ? AppColors.primary : Colors.grey.shade400,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                        overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)} total collected',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                      ),
                        overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: filteredCollections.isEmpty
                  ? Center(
                      child: Text(
                        'No ${assetType} scheme collections today',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.0,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCollections.length,
                      itemBuilder: (context, index) {
                        final collection = filteredCollections[index];
                        final amount = collection['amount'] as double;
                        final customerName = collection['customerName'] as String;
                        final scheme = collection['scheme'] as String;
                        final method = collection['method'] as String;
                        final time = collection['time'] as String? ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: (assetType == 'gold' ? AppColors.primary : Colors.grey.shade400).withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      scheme,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 2.0),
                                      Row(
                                        children: [
                                          Text(
                                            method.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: assetType == 'gold' ? AppColors.primary : Colors.grey.shade400,
                                              fontSize: 11.0,
                                            ),
                                          ),
                                          Text(
                                            ' • $time',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 11.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: assetType == 'gold' ? AppColors.primary : Colors.grey.shade400,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: (assetType == 'gold' ? AppColors.primary : Colors.grey.shade400).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: assetType == 'gold' ? AppColors.primary : Colors.grey.shade400,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
