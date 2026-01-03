// lib/screens/staff/today_target_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../../utils/constants.dart';
import '../../services/staff_data_service.dart';
import 'customer_detail_screen.dart';

class TodayTargetDetailScreen extends StatefulWidget {
  final String staffId;

  const TodayTargetDetailScreen({
    super.key,
    required this.staffId,
  });

  @override
  State<TodayTargetDetailScreen> createState() => _TodayTargetDetailScreenState();
}

class _TodayTargetDetailScreenState extends State<TodayTargetDetailScreen> {
  Map<String, dynamic>? _todayStats;
  List<Map<String, dynamic>> _assignedCustomers = [];
  List<Map<String, dynamic>> _todayCollections = [];
  double? _dailyTarget;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load all data in parallel
      final results = await Future.wait([
        StaffDataService.getTodayStats(widget.staffId),
        StaffDataService.getAssignedCustomers(widget.staffId),
        StaffDataService.getTodayCollections(widget.staffId),
        StaffDataService.getDailyTarget(widget.staffId),
      ]);

      if (!mounted) return;

      setState(() {
        _todayStats = results[0] as Map<String, dynamic>?;
        _assignedCustomers = (results[1] as List).cast<Map<String, dynamic>>();
        _todayCollections = (results[2] as List).cast<Map<String, dynamic>>();
        final targetMap = results[3] as Map<String, dynamic>?;
        _dailyTarget = (targetMap?['amount'] as num?)?.toDouble();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('TodayTargetDetailScreen._loadData FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
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
                'Failed to load target details',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _loadData();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _todayStats ?? {};
    final collectedCount = stats['customersCollected'] as int? ?? 0;
    final totalCustomers = stats['totalCustomers'] as int? ?? 0;
    final collectedAmount = (stats['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final targetAmount = _dailyTarget ?? 0.0;
    final progress = targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final pendingCount = stats['pendingCount'] as int? ?? 0;

    // Get collected customer IDs from today's collections
    // Normalize ID field names (collections use 'customerId', customers use 'id' or 'customer_id')
    final collectedCustomerIds = _todayCollections
        .map((c) => c['customerId'] ?? c['customer_id'] ?? c['customer_profile_id'])
        .whereType<String>()
        .toSet();

    // Split customers into collected and pending
    // Normalize customer ID lookup (customers have both 'id' and 'customer_id')
    final collectedCustomers = _assignedCustomers
        .where((c) {
          final customerId = c['id'] ?? c['customer_id'];
          return customerId != null && collectedCustomerIds.contains(customerId.toString());
        })
        .toList();

    final pendingCustomers = _assignedCustomers
        .where((c) {
          final customerId = c['id'] ?? c['customer_id'];
          return customerId != null && !collectedCustomerIds.contains(customerId.toString());
        })
        .toList();

    // Sort pending: missed payments first, then by due amount
    pendingCustomers.sort((a, b) {
      final aMissed = a['missedPayments'] as int;
      final bMissed = b['missedPayments'] as int;
      if (aMissed != bMissed) {
        return bMissed.compareTo(aMissed);
      }
      return (b['dueAmount'] as double).compareTo(a['dueAmount'] as double);
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A0F3E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Today\'s Target',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
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
                    'SUMMARY',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.0,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$collectedCount / $totalCustomers',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 32.0,
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
                  ),
                  const SizedBox(height: 16.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${collectedAmount.toStringAsFixed(0)} / ₹${targetAmount.toStringAsFixed(0)}',
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
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    '$pendingCount Pending',
                    style: GoogleFonts.inter(
                      color: Colors.orange,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // Collected today section
            if (collectedCustomers.isNotEmpty) ...[
              Text(
                'COLLECTED TODAY (${collectedCustomers.length})',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16.0),
              ...collectedCustomers.map((customer) {
                // Find collection details from todayCollections
                // Normalize ID lookup (customer has 'id' or 'customer_id', collection has 'customerId')
                final customerId = customer['id'] ?? customer['customer_id'];
                final collection = _todayCollections.firstWhere(
                  (c) {
                    final collId = c['customerId'] ?? c['customer_id'] ?? c['customer_profile_id'];
                    return collId?.toString() == customerId?.toString();
                  },
                  orElse: () => <String, dynamic>{
                    'amount': customer['dueAmount'] ?? 0.0,
                    'method': 'cash',
                    'time': '',
                    'customerName': customer['name'] ?? 'Unknown',
                    'scheme': customer['scheme'] ?? 'N/A',
                  },
                );

                final amount = (collection['amount'] as num?)?.toDouble() ?? 
                              (customer['dueAmount'] as num?)?.toDouble() ?? 0.0;
                final method = (collection['method'] as String?) ?? 'cash';
                final time = (collection['time'] as String?) ?? '';
                final name = (collection['customerName'] as String?) ?? 
                            (customer['name'] as String?) ?? 'Unknown Customer';
                final scheme = (collection['scheme'] as String?) ?? 
                              (customer['scheme'] as String?) ?? 'N/A';
                
                // Calculate GST (3% of amount)
                final gstAmount = amount * 0.03;
                final netAmount = amount - gstAmount;
                
                // Format time properly
                String formattedTime = time;
                if (time.isEmpty) {
                  formattedTime = DateFormat('h:mm a').format(DateTime.now());
                }

                final isCash = method.toLowerCase() == 'cash';
                final methodIcon = isCash ? Icons.money : Icons.account_balance_wallet;
                final methodColor = isCash ? Colors.green : Colors.blue;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailScreen(
                          customerId: customer['id'],
                          customer: customer,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.success.withOpacity(0.15),
                          AppColors.success.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.4),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with check icon and customer name
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 24.0,
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
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  scheme,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20.0),
                      
                      // Amount section
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount Collected',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.0,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  '₹${_formatCurrency(amount)}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Payment method badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 10.0,
                              ),
                              decoration: BoxDecoration(
                                color: methodColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: methodColor.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    methodIcon,
                                    color: methodColor,
                                    size: 18.0,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    method.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: methodColor,
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      // Details row - Time and GST breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white.withOpacity(0.6),
                                size: 16.0,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                formattedTime,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          // GST breakdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Net: ₹${_formatCurrency(netAmount)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'GST (3%): ₹${_formatCurrency(gstAmount)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24.0),
            ] else ...[
              // Empty state for collected customers
              Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      color: Colors.white.withOpacity(0.3),
                      size: 48.0,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'No collections yet today',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Collections will appear here once payments are recorded',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],

            // Divider
            if (collectedCustomers.isNotEmpty && pendingCustomers.isNotEmpty)
              Container(
                height: 1.0,
                color: Colors.white.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
              ),

            const SizedBox(height: 16.0),

            // Pending section
            if (pendingCustomers.isNotEmpty) ...[
              Text(
                'PENDING (${pendingCustomers.length})',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12.0),
              ...pendingCustomers.map((customer) {
                final missedCount = (customer['missedPayments'] as num?)?.toInt() ?? 0;
                final dueAmount = (customer['dueAmount'] as num?)?.toDouble() ?? 0.0;
                final name = (customer['name'] as String?) ?? 'Unknown';
                final phone = (customer['phone'] as String?) ?? '';
                final scheme = (customer['scheme'] as String?) ?? 'N/A';

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
                        ).then((_) => setState(() {}));
                      },
                      borderRadius: BorderRadius.circular(16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: hasMissed
                                    ? AppColors.danger.withOpacity(0.2)
                                    : AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: hasMissed
                                    ? Icon(Icons.warning_amber,
                                        color: AppColors.danger, size: 24.0)
                                    : Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                                children: [
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
                                  if (hasMissed)
                                    Text(
                                      '⚠️ $missedCount Missed Payments',
                                      style: GoogleFonts.inter(
                                        color: AppColors.danger.withOpacity(0.8),
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
                                        color: Colors.orange,
                                        fontSize: 13.0,
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
              }).toList(),
            ],

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final String numberStr = amount.toStringAsFixed(0);

    if (numberStr.length <= 3) {
      return numberStr;
    }

    String result = '';
    int count = 0;

    for (int i = numberStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',' + result;
        count = 0;
      }
      result = numberStr[i] + result;
      count++;
    }

    return result;
  }
}

