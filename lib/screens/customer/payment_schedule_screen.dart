// lib/screens/customer/payment_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../utils/mock_data.dart';

class PaymentScheduleScreen extends StatefulWidget {
  const PaymentScheduleScreen({super.key});

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen> {
  bool _showAllPaid = false;
  bool _isRefreshing = false;

  Future<void> _refreshSchedule() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call to refresh schedule
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment schedule refreshed',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    final String numberStr = amount.toInt().toString();
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

  @override
  Widget build(BuildContext context) {
    final schedule = MockData.paymentSchedule;
    final upcoming = schedule.where((item) => item['status'] == 'UPCOMING').take(10).toList();
    final paid = schedule.where((item) => item['status'] == 'PAID').toList();
    final missed = schedule.where((item) => item['status'] == 'MISSED').toList();
    final displayedPaid = _showAllPaid ? paid : paid.take(30).toList();

    // Get unique scheme names for subtitle
    final schemeNames = MockData.activeSchemes.map((s) => s['schemeName'] as String).join(', ');

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Schedule',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            schemeNames,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshSchedule,
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFF2A1454),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upcoming Payments
                        if (upcoming.isNotEmpty) ...[
                        Text(
                          'Upcoming Payments',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...upcoming.map((item) => _buildPaymentItem(item)),
                        const SizedBox(height: 32),
                      ],

                      // Missed Payments
                      if (missed.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${missed.length} missed payment${missed.length > 1 ? 's' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...missed.map((item) => _buildPaymentItem(item)),
                        const SizedBox(height: 32),
                      ],

                      // Paid Payments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paid Payments',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (paid.length > 30)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAllPaid = !_showAllPaid;
                                });
                              },
                              child: Text(
                                _showAllPaid ? 'Show Less' : 'Show All (${paid.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...displayedPaid.map((item) => _buildPaymentItem(item)),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> item) {
    final status = item['status'] as String;
    final dateFormatted = item['dateFormatted'] as String;
    final dayName = item['dayName'] as String;
    final schemeName = item['schemeName'] as String;
    final amount = item['amount'] as int;
    final installmentNumber = item['installmentNumber'] as int?;

    IconData statusIcon;
    Color statusColor;
    Color backgroundColor;

    if (status == 'PAID') {
      statusIcon = Icons.check_circle;
      statusColor = AppColors.success;
      backgroundColor = Colors.white.withOpacity(0.1);
    } else if (status == 'MISSED') {
      statusIcon = Icons.cancel;
      statusColor = AppColors.danger;
      backgroundColor = AppColors.danger.withOpacity(0.1);
    } else {
      statusIcon = Icons.circle_outlined;
      statusColor = AppColors.primary;
      backgroundColor = Colors.white.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status == 'MISSED'
                ? AppColors.danger.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 16),
            // Date and Scheme Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          dateFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dayName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schemeName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (installmentNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Installment #$installmentNumber',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${_formatCurrency(amount.toDouble())}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (status == 'PAID' && item['receiptId'] != null)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to receipt
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

