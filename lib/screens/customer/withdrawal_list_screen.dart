// lib/screens/customer/withdrawal_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import 'withdrawal_screen.dart';

class WithdrawalListScreen extends StatefulWidget {
  const WithdrawalListScreen({super.key});

  @override
  State<WithdrawalListScreen> createState() => _WithdrawalListScreenState();
}

class _WithdrawalListScreenState extends State<WithdrawalListScreen> {
  List<Map<String, dynamic>> _completedSchemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedSchemes();
  }

  Future<void> _fetchCompletedSchemes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        // Mock data for testing
        _completedSchemes = _getMockCompletedSchemes();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Query completed schemes from Supabase
      final response = await Supabase.instance.client
          .from('user_schemes')
          .select('*, schemes(*)')
          .eq('user_id', userId)
          .or('status.eq.completed,status.eq.mature')
          .order('maturity_date', ascending: false);

      if (response != null && response.isNotEmpty) {
        _completedSchemes = (response as List<dynamic>).map((scheme) {
          final schemeMap = scheme as Map<String, dynamic>;
          final schemeData = schemeMap['schemes'] as Map<String, dynamic>? ?? <String, dynamic>{};
          return {
            ...schemeMap,
            'schemes': schemeData,
          } as Map<String, dynamic>;
        }).toList();
      } else {
        // Return mock data if no database entries
        _completedSchemes = _getMockCompletedSchemes();
      }
    } catch (e) {
      print('Error fetching completed schemes: $e');
      // Return mock data on error
      _completedSchemes = _getMockCompletedSchemes();
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getMockCompletedSchemes() {
    // Mock data for testing - replace with actual database query
    return [
      {
        'id': 'us-001',
        'scheme_id': 'gold-scheme-3',
        'status': 'completed',
        'total_amount_paid': 186000.0,
        'total_withdrawn': 0.0,
        'accumulated_metal_grams': 1.32,
        'metal_withdrawn': 0.0,
        'maturity_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'schemes': {
          'id': 'gold-scheme-3',
          'name': 'Gold Scheme 3',
          'asset_type': 'gold',
        },
      },
      {
        'id': 'us-002',
        'scheme_id': 'silver-scheme-1',
        'status': 'completed',
        'total_amount_paid': 18750.0,
        'total_withdrawn': 5000.0,
        'accumulated_metal_grams': 10.3,
        'metal_withdrawn': 2.5,
        'maturity_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'schemes': {
          'id': 'silver-scheme-1',
          'name': 'Silver Scheme 1',
          'asset_type': 'silver',
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
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
          'Withdrawals',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _completedSchemes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCompletedSchemes,
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFF2A1454),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed Schemes',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a scheme to withdraw funds',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._completedSchemes.map((scheme) => _buildSchemeCard(scheme)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'No Completed Schemes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a scheme to withdraw funds',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    final schemeData = scheme['schemes'] ?? {};
    final schemeName = schemeData['name'] ?? 'Unknown Scheme';
    final metalType = schemeData['asset_type'] ?? 'gold';
    final totalPaid = (scheme['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
    final gstPaid = totalPaid * 0.03;
    final netInvestment = totalPaid - gstPaid;
    final previousWithdrawals = (scheme['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final availableBalance = netInvestment - previousWithdrawals;
    final accumulatedMetal = (scheme['accumulated_metal_grams'] as num?)?.toDouble() ?? 0.0;
    final metalWithdrawn = (scheme['metal_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final metalAvailable = accumulatedMetal - metalWithdrawn;

    final isGold = metalType.toString().toLowerCase() == 'gold';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WithdrawalScreen(scheme: scheme),
              ),
            ).then((_) => _fetchCompletedSchemes());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGold ? Icons.monetization_on : Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schemeName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metalType.toString().toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.3),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                // Net Investment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Investment:',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₹${netInvestment.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Withdrawals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Withdrawals:',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₹${previousWithdrawals.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: previousWithdrawals > 0 ? AppColors.danger : Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${availableBalance.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Metal Available',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${metalAvailable.toStringAsFixed(3)} g',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

