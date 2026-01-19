// lib/screens/customer/withdrawal_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/constants.dart';
import '../../widgets/success_animation_widget.dart';

class WithdrawalScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;

  const WithdrawalScreen({super.key, required this.scheme});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  bool _isFullWithdrawal = true;
  final _amountController = TextEditingController();
  double? _currentRate;
  bool _isLoadingRate = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRate();
  }

  Future<void> _loadCurrentRate() async {
    setState(() {
      _isLoadingRate = true;
    });

    try {
      final schemeData = widget.scheme['schemes'] ?? widget.scheme;
      final metalType = schemeData['asset_type'] ?? schemeData['scheme_type'] ?? 'gold';

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('market_rates')
          .select('price_per_gram, asset_type')
          .eq('asset_type', metalType.toString().toLowerCase())
          .order('rate_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response['price_per_gram'] == null) {
        throw Exception('No market rate available for $metalType');
      }

      setState(() {
        _currentRate = (response['price_per_gram'] as num).toDouble();
        _isLoadingRate = false;
      });
    } catch (e) {
      setState(() {
        _currentRate = null;
        _isLoadingRate = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load current market rate. Please try again later.',
              style: GoogleFonts.inter(fontSize: 14.0),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Calculate grams to withdraw based on amount and current rate
  double _calculateGramsToWithdraw() {
    final totalPaid = (widget.scheme['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
    final gstPaid = totalPaid * 0.03;
    final netInvestment = totalPaid - gstPaid;
    final previousWithdrawals = (widget.scheme['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final availableBalance = netInvestment - previousWithdrawals;
    
    final accumulatedMetalGrams = (widget.scheme['accumulated_metal_grams'] as num?)?.toDouble() ?? 0.0;
    final metalWithdrawn = (widget.scheme['metal_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final metalAvailable = accumulatedMetalGrams - metalWithdrawn;

    if (_isFullWithdrawal) {
      return metalAvailable;
    } else {
      final requestedAmount = double.tryParse(_amountController.text) ?? 0.0;
      if (_currentRate != null && _currentRate! > 0) {
        return requestedAmount / _currentRate!;
      }
      // Fallback: use available metal grams proportionally
      if (availableBalance > 0) {
        return (requestedAmount / availableBalance) * metalAvailable;
      }
      return 0.0;
    }
  }

  /// Submit withdrawal request to database
  Future<void> _submitWithdrawal() async {
    // Validate inputs
    if (!_isFullWithdrawal) {
      final requestedAmount = double.tryParse(_amountController.text);
      if (requestedAmount == null || requestedAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enter a valid withdrawal amount',
                style: GoogleFonts.inter(fontSize: 14.0),
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final totalPaid = (widget.scheme['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
      final gstPaid = totalPaid * 0.03;
      final netInvestment = totalPaid - gstPaid;
      final previousWithdrawals = (widget.scheme['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
      final availableBalance = netInvestment - previousWithdrawals;

      if (requestedAmount > availableBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Requested amount exceeds available balance',
                style: GoogleFonts.inter(fontSize: 14.0),
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile to find customer_id
      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('Profile not found');
      }

      final profileId = profileResponse['id'] as String;

      // Get customer_id from customers table
      final customerResponse = await supabase
          .from('customers')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (customerResponse == null) {
        throw Exception('Customer record not found');
      }

      final customerId = customerResponse['id'] as String;
      final userSchemeId = widget.scheme['id'] as String? ?? widget.scheme['user_scheme_id'] as String?;

      if (userSchemeId == null) {
        throw Exception('Scheme ID not found');
      }

      // Calculate requested grams
      final requestedGrams = _calculateGramsToWithdraw();

      if (requestedGrams <= 0) {
        throw Exception('Invalid withdrawal amount');
      }

      // Prepare withdrawal data
      final withdrawalData = {
        'user_scheme_id': userSchemeId,
        'customer_id': customerId,
        'withdrawal_type': _isFullWithdrawal ? 'full' : 'partial',
        'requested_amount': _isFullWithdrawal ? null : double.parse(_amountController.text),
        'requested_grams': requestedGrams,
        'status': 'pending',
        'client_timestamp': DateTime.now().toIso8601String(),
      };

      // Insert withdrawal request
      await supabase.from('withdrawals').insert(withdrawalData);

      if (mounted) {
        await _showSuccessAnimation(
          'Withdrawal request submitted successfully.\nPending approval.',
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit withdrawal request: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.inter(fontSize: 14.0),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

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
    final currentRate = _currentRate;

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
                        _isLoadingRate
                            ? 'Loading...'
                            : currentRate != null
                                ? '₹${currentRate.toStringAsFixed(2)}/g'
                                : 'Unavailable',
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
                onPressed: _isSubmitting ? null : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF1A0F3E),
                          ),
                        ),
                      )
                    : Text(
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

  Future<void> _showSuccessAnimation(String message) async {
    await SuccessAnimationWidget.show(
      context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }
}

