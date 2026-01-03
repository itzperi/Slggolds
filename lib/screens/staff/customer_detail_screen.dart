// lib/screens/staff/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/staff_data_service.dart';
import 'collect_payment_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customer,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await StaffDataService.getPaymentHistory(widget.customerId);
      setState(() {
        _paymentHistory = history.take(15).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = widget.customer['name'][0].toUpperCase();
    final last15Payments = _paymentHistory;

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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Customer Details',
                        style: GoogleFonts.inter(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.phone, color: AppColors.primary),
                      onPressed: () => _callCustomer(widget.customer['phone']),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer info card
                      _buildCustomerInfoCard(firstLetter),
                      const SizedBox(height: 24.0),

                      // Scheme
                      _buildSectionTitle('SCHEME'),
                      const SizedBox(height: 12.0),
                      _buildSchemeCard(),
                      const SizedBox(height: 24.0),

                      // Payment status
                      _buildSectionTitle('PAYMENT STATUS'),
                      const SizedBox(height: 12.0),
                      _buildPaymentStatusCard(),
                      const SizedBox(height: 24.0),

                      // Payment history
                      _buildSectionTitle('PAYMENT HISTORY (Last 15)'),
                      const SizedBox(height: 12.0),
                      _buildPaymentHistoryList(last15Payments),
                      const SizedBox(height: 24.0),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CollectPaymentScreen(
                                      customer: widget.customer,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Text(
                                'Collect Payment',
                                style: GoogleFonts.inter(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          OutlinedButton(
                            onPressed: () => _callCustomer(widget.customer['phone']),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Icon(
                              Icons.phone,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(String firstLetter) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3.0,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: GoogleFonts.inter(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            widget.customer['name'] ?? 'Unknown',
            style: GoogleFonts.inter(
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.customer['phone'] ?? 'N/A',
            style: GoogleFonts.inter(
              fontSize: 16.0,
              color: Colors.white.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.customer['address'] ?? 'Address not available',
              style: GoogleFonts.inter(
                fontSize: 14.0,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              'Customer ID: ${widget.customer['customerId'] ?? widget.customer['id'] ?? 'N/A'}',
              style: GoogleFonts.inter(
                fontSize: 12.0,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSchemeCard() {
    final minAmount = widget.customer['minAmount'] as double;
    final maxAmount = widget.customer['maxAmount'] as double;
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Scheme', widget.customer['scheme'] ?? 'N/A'),
          _buildInfoRow('Frequency', '${widget.customer['frequency'] ?? 'N/A'} Payment'),
          _buildInfoRow('Range', '₹${_formatCurrency(minAmount)} - ₹${_formatCurrency(maxAmount)}'),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    final totalPayments = widget.customer['totalPayments'] as int;
    final missedPayments = widget.customer['missedPayments'] as int;
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Total Payments', totalPayments.toString()),
          _buildInfoRow('Missed Payments', missedPayments.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.0,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Center(
          child: Text(
            'No payment history',
            style: GoogleFonts.inter(
              fontSize: 14.0,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        children: payments.asMap().entries.map((entry) {
          final index = entry.key;
          final payment = entry.value;
          final isLast = index == payments.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      payment['status'] == 'paid'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: payment['status'] == 'paid'
                          ? AppColors.success
                          : AppColors.danger,
                      size: 20.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatShortDate(payment['date']),
                            style: GoogleFonts.inter(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (payment['status'] == 'paid')
                            Text(
                              '₹${_formatCurrency(payment['amount'] as double)} • ${_formatMethod(payment['method'])}',
                              style: GoogleFonts.inter(
                                fontSize: 12.0,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            )
                          else
                            Text(
                              'Missed',
                              style: GoogleFonts.inter(
                                fontSize: 12.0,
                                color: AppColors.danger,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1.0,
                  color: Colors.white.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatShortDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMethod(String method) {
    if (method == 'cash') return 'Cash';
    if (method == 'upi') return 'UPI';
    return method.toUpperCase();
  }
}
