// lib/screens/staff/collect_payment_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../utils/constants.dart';
import '../../services/payment_service.dart';
import '../../services/role_routing_service.dart';
import '../../services/offline_payment_queue.dart';

class CollectPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CollectPaymentScreen({super.key, required this.customer});

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = ''; // 'cash' or 'upi'
  bool _isLoading = false;
  double? _currentMetalRate;

  @override
  void initState() {
    super.initState();
    // Amount field starts empty - user enters amount manually
    _amountController.text = '';
    _amountController.addListener(() {
      setState(() {}); // Rebuild to show GST breakdown
    });
    _loadMarketRate();
  }

  Future<void> _loadMarketRate() async {
    try {
      final scheme = widget.customer['scheme'] as String? ?? '';
      final isGold = scheme.toLowerCase().contains('gold');
      final assetType = isGold ? 'gold' : 'silver';
      final rate = await PaymentService.getCurrentMarketRate(assetType);
      if (mounted) {
        setState(() {
          _currentMetalRate = rate;
        });
      }
    } catch (e) {
      // GAP-078: Remove hardcoded/mock fallbacks and fail gracefully
      _showError('Unable to load current market rate. Please try again later.');
      if (mounted) {
        setState(() {
          _currentMetalRate = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _onPaymentDone() async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showError('Please enter amount');
      return;
    }

    // Only validate minimum amount - allow any amount above (bulk payments allowed)
    final minAmount = widget.customer['minAmount'] as double;
    if (amount < minAmount) {
      _showError('Minimum amount is ₹${minAmount.toStringAsFixed(0)}');
      return;
    }

    if (_paymentMethod.isEmpty) {
      _showError('Please select payment method');
      return;
    }

    // Record payment to database
    setState(() => _isLoading = true);

    try {
      // Get current staff profile ID
      final staffProfileId = await RoleRoutingService.getCurrentProfileId();
      if (staffProfileId == null) {
        throw Exception('Staff profile not found');
      }

      // Get customer UUID from database
      final customerId = await PaymentService.getCustomerIdFromData(widget.customer);
      if (customerId == null) {
        throw Exception('Customer not found in database');
      }

      // Get user_scheme_id
      final userSchemeId = await PaymentService.getUserSchemeId(customerId);
      if (userSchemeId == null) {
        throw Exception('Active scheme not found for customer');
      }

      // Determine asset type from scheme
      final scheme = widget.customer['scheme'] as String? ?? '';
      final isGold = scheme.toLowerCase().contains('gold');
      final assetType = isGold ? 'gold' : 'silver';

      // Get current market rate (required - no hardcoded fallback)
      final metalRate = await PaymentService.getCurrentMarketRate(assetType);

      // Get device ID and timestamp
      final deviceId = PaymentService.getDeviceId();
      final clientTimestamp = DateTime.now();
      // Generate unique ID for idempotency (timestamp + random)
      final clientPaymentId = '${clientTimestamp.millisecondsSinceEpoch}_${Random().nextInt(10000)}';

      // GAP-047: Try to insert payment online, fallback to offline queue on network error
      try {
        await PaymentService.insertPayment(
          userSchemeId: userSchemeId,
          customerId: customerId,
          staffId: staffProfileId,
          amount: amount,
          paymentMethod: _paymentMethod,
          metalRatePerGram: metalRate,
          deviceId: deviceId,
          clientTimestamp: clientTimestamp,
        );

        setState(() => _isLoading = false);

        // Success animation + message
        if (mounted) {
          await _showSuccessAnimation('Payment recorded successfully!');
          if (!mounted) return;
          Navigator.pop(context, true); // Return true to indicate refresh needed
        }
      } catch (e) {
        // Check if this is a network error (offline scenario)
        final errorStr = e.toString().toLowerCase();
        final isNetworkError = errorStr.contains('network') ||
            errorStr.contains('connection') ||
            errorStr.contains('timeout') ||
            errorStr.contains('socket') ||
            errorStr.contains('failed host lookup');

        if (isNetworkError) {
          // GAP-047: Enqueue payment for offline sync
          try {
            await OfflinePaymentQueue.enqueue(
              OfflinePaymentQueueItem(
                customerId: customerId,
                userSchemeId: userSchemeId,
                staffId: staffProfileId,
                amount: amount,
                paymentMethod: _paymentMethod,
                metalRatePerGram: metalRate,
                deviceId: deviceId,
                clientTimestamp: clientTimestamp,
                clientPaymentId: clientPaymentId,
              ),
            );

            setState(() => _isLoading = false);

            // Show queued message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment queued. Will sync when online.',
                    style: GoogleFonts.inter(fontSize: 14.0),
                  ),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );

              // Navigate back
              Navigator.pop(context, true);
            }
          } catch (queueError) {
            // Queue full or other queue error
            setState(() => _isLoading = false);
            if (queueError is OfflineQueueFullException) {
              _showError('Offline queue is full. Please try again when online.');
            } else {
              _showError('Failed to queue payment: ${queueError.toString()}');
            }
          }
        } else {
          // Non-network error (validation, RLS, etc.) - show error
          setState(() => _isLoading = false);
          _showError('Failed to record payment: ${e.toString()}');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to record payment: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14.0),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Future<void> _showSuccessAnimation(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    'assets/lottie/payment_success.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minAmount = widget.customer['minAmount'] as double;
    final maxAmount = widget.customer['maxAmount'] as double? ?? minAmount * 2; // Fallback for midAmount calculation
    final midAmount = (minAmount + maxAmount) / 2.0;
    final missedCount = widget.customer['missedPayments'] as int;

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
                        'Collect Payment',
                        style: GoogleFonts.inter(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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
                      // Customer info
                      Text(
                        widget.customer['name'] ?? 'Unknown',
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
                        '${widget.customer['scheme'] ?? 'N/A'} (${widget.customer['frequency'] ?? 'N/A'})',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 16.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Minimum: ₹${minAmount.toStringAsFixed(0)} (Bulk payments allowed)',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.0,
                          ),
                        ),
                      ),

                      if (missedCount > 0) ...[
                        const SizedBox(height: 16.0),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange, size: 18.0),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Missed Payments: $missedCount',
                                    style: GoogleFonts.inter(
                                      color: Colors.orange,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Total Due: ₹${(minAmount * missedCount).toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      const SizedBox(height: 24.0),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 24.0),

                      // Amount field
                      Text(
                        'Amount to Collect',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 18.0,
                            ),
                            hintText: 'Enter amount',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16.0),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12.0),

                      // Quick amount chips
                      Text(
                        'Quick Amounts:',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          _buildQuickAmountChip(minAmount),
                          _buildQuickAmountChip(midAmount),
                          if (missedCount > 0)
                            _buildQuickAmountChip(minAmount * missedCount),
                          // Add common bulk payment amounts
                          _buildQuickAmountChip(5000),
                          _buildQuickAmountChip(10000),
                          _buildQuickAmountChip(25000),
                        ],
                      ),

                      const SizedBox(height: 24.0),

                      // Payment method
                      Text(
                        'Payment Method',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      RadioListTile<String>(
                        value: 'cash',
                        groupValue: _paymentMethod,
                        onChanged: (value) => setState(() => _paymentMethod = value!),
                        title: Text(
                          'Cash',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),

                      RadioListTile<String>(
                        value: 'upi',
                        groupValue: _paymentMethod,
                        onChanged: (value) => setState(() => _paymentMethod = value!),
                        title: Text(
                          'UPI',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 24.0),

                      // GST Breakdown (shown when amount is entered)
                      if (_amountController.text.isNotEmpty)
                        _buildGSTBreakdown(),

                      const SizedBox(height: 24.0),

                      // Payment Done button
                      SizedBox(
                        width: double.infinity,
                        height: 56.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onPaymentDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                )
                              : Text(
                                  'Payment Done',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      SizedBox(
                        width: double.infinity,
                        height: 56.0,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildQuickAmountChip(double amount) {
    return ActionChip(
      label: Text('₹${amount.toStringAsFixed(0)}'),
      onPressed: () => _onQuickAmount(amount),
      backgroundColor: Colors.white.withOpacity(0.05),
      labelStyle: GoogleFonts.inter(
        color: AppColors.primary,
        fontSize: 14.0,
      ),
      side: BorderSide(
        color: AppColors.primary.withOpacity(0.3),
        width: 1.0,
      ),
    );
  }

  Widget _buildGSTBreakdown() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();

    final gstAmount = amount * 0.03;
    final netAmount = amount * 0.97;
    
    // Determine if gold or silver scheme (for labels only)
    final scheme = widget.customer['scheme'] as String? ?? '';
    final isGold = scheme.toLowerCase().contains('gold');

    // Use current metal rate if available; otherwise, hide rate/grams section
    final rate = _currentMetalRate ?? 0.0;
    if (rate <= 0) return const SizedBox.shrink();
    final metalAdded = netAmount / rate;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Breakdown',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Amount Collected
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount Collected',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.0,
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          
          // GST (3%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GST (3%)',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontSize: 14.0,
                ),
              ),
              Text(
                '- ₹${gstAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          
          // Net Investment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Investment',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹${netAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Metal Rate and Added (optional - only show if rate is available)
          if (_currentMetalRate != null) ...[
          const SizedBox(height: 16.0),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isGold ? "Gold" : "Silver"} Rate',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.0,
                ),
              ),
              Text(
                '₹${rate.toStringAsFixed(0)}/g',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isGold ? "Gold" : "Silver"} Added',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${metalAdded.toStringAsFixed(4)} g',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }
}
