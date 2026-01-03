// lib/screens/customer/withdrawal_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';

class WithdrawalScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;

  const WithdrawalScreen({super.key, required this.scheme});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  bool _isFullWithdrawal = true;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = (widget.scheme['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
    final gstPaid = totalPaid * 0.03;
    final netInvestment = totalPaid - gstPaid;
    final previousWithdrawals = (widget.scheme['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final availableBalance = netInvestment - previousWithdrawals;
    
    final accumulatedMetalGrams = (widget.scheme['accumulated_metal_grams'] as num?)?.toDouble() ?? 0.0;
    final metalWithdrawn = (widget.scheme['metal_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final metalAvailable = accumulatedMetalGrams - metalWithdrawn;

    final schemeData = widget.scheme['schemes'] ?? widget.scheme;
    final metalType = schemeData['asset_type'] ?? schemeData['scheme_type'] ?? 'gold';
    final currentRate = metalType.toString().toLowerCase() == 'gold' ? 6500.0 : 78.0; // Fetch from market_rates

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
          'Withdrawal',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scheme info
            Text(
              schemeData['name'] ?? widget.scheme['scheme_name'] ?? 'Scheme',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Available Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE TO WITHDRAW',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${availableBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid:',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹${totalPaid.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Less GST (3%):',
                        style: GoogleFonts.inter(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '- ₹${gstPaid.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Less Withdrawals:',
                        style: GoogleFonts.inter(
                          color: Colors.red.shade300,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '- ₹${previousWithdrawals.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: Colors.red.shade300,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Balance:',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${availableBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accumulated ${metalType.toString().toUpperCase()}:',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${metalAvailable.toStringAsFixed(3)} g',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Rate:',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹${currentRate.toStringAsFixed(2)}/g',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Withdrawal Type
            Text(
              'WITHDRAWAL TYPE',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            RadioListTile<bool>(
              value: true,
              groupValue: _isFullWithdrawal,
              onChanged: (value) => setState(() => _isFullWithdrawal = value!),
              title: Text(
                'Full Withdrawal',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              subtitle: Text(
                '₹${availableBalance.toStringAsFixed(2)} (${metalAvailable.toStringAsFixed(3)} g)',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
              activeColor: AppColors.primary,
            ),

            RadioListTile<bool>(
              value: false,
              groupValue: _isFullWithdrawal,
              onChanged: (value) => setState(() => _isFullWithdrawal = value!),
              title: Text(
                'Partial Withdrawal',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              activeColor: AppColors.primary,
            ),

            if (!_isFullWithdrawal) ...[
              const SizedBox(height: 16),
              Text(
                'Amount to Withdraw',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                    hintText: 'Max: ${availableBalance.toStringAsFixed(0)}',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Submit withdrawal request
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Withdrawal request submitted. Pending approval.',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Request Withdrawal',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A0F3E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Note: Withdrawal requests are processed by office staff within 2-3 business days.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

