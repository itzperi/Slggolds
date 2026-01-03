// lib/screens/customer/scheme_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../utils/mock_data.dart';
import 'schemes_screen.dart';

class SchemeDetailScreen extends StatefulWidget {
  final String schemeId;

  const SchemeDetailScreen({
    super.key,
    required this.schemeId,
  });

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  bool _termsExpanded = false;

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

  Map<String, dynamic> get _schemeData {
    return MockData.schemeDetails[widget.schemeId] ?? MockData.schemeDetails['monthly-gold']!;
  }

  void _toggleVariant() {
    final variantId = _schemeData['variantId'] as String;
    if (MockData.schemeDetails.containsKey(variantId)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SchemeDetailScreen(schemeId: variantId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeData;
    final isGold = scheme['assetType'] == 'gold';
    final isActive = scheme['active'] == true;
    final iconName = scheme['icon'] as String;
    final icon = _getIcon(iconName);

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
                      child: Text(
                        scheme['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Toggle Button
                    if (scheme['variantId'] != null)
                      TextButton.icon(
                        onPressed: _toggleVariant,
                        icon: Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        label: Text(
                          'Switch to ${isGold ? 'Silver' : 'Gold'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Badges
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isGold
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.textSecondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isGold ? 'GOLD SCHEME' : 'SILVER SCHEME',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isGold ? AppColors.primary : AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.success.withOpacity(0.2)
                                        : AppColors.textSecondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Coming Soon',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isActive ? AppColors.success : AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withOpacity(0.2),
                                    AppColors.primary.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, color: AppColors.primary, size: 48),
                            ),
                            const SizedBox(height: 16),
                            // Tagline
                            Text(
                              scheme['tagline'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Investment Summary Card
                      Text(
                        'Investment Summary',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (scheme.containsKey('minDailyAmount') && scheme.containsKey('maxDailyAmount'))
                              _buildSummaryRow(
                                'Daily Amount Range',
                                '₹${_formatCurrency((scheme['minDailyAmount'] as int).toDouble())} - ₹${_formatCurrency((scheme['maxDailyAmount'] as int).toDouble())}',
                              )
                            else
                              _buildSummaryRow('Installment Amount', '₹${_formatCurrency((scheme['installmentAmount'] as int).toDouble())}'),
                            const Divider(color: Colors.white24, height: 24),
                            _buildSummaryRow('Payment Frequency', _capitalizeFirst(scheme['frequency'] as String)),
                            const Divider(color: Colors.white24, height: 24),
                            _buildSummaryRow('Duration', scheme['duration'] as String),
                            if (scheme.containsKey('metalAccumulation')) ...[
                              const Divider(color: Colors.white24, height: 24),
                              _buildSummaryRow(
                                'Metal Accumulation',
                                scheme['metalAccumulation'] as String,
                              ),
                            ],
                            if (scheme.containsKey('entryFee')) ...[
                              const Divider(color: Colors.white24, height: 24),
                              _buildSummaryRow('Entry Fee', '₹${_formatCurrency((scheme['entryFee'] as int).toDouble())}'),
                            ],
                            if (scheme.containsKey('totalInvestment') && (scheme['totalInvestment'] as int) > 0) ...[
                              const Divider(color: Colors.white24, height: 24),
                              _buildSummaryRow('Total Investment', '₹${_formatCurrency((scheme['totalInvestment'] as int).toDouble())}'),
                            ],
                          ],
                        ),
                      ),
                      if (scheme.containsKey('metalAccumulation')) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Note: Metal accumulation is guaranteed as per scheme. Actual value depends on market price at time of redemption.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Features Section
                      Text(
                        'What You Get',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: (scheme['features'] as List).map((feature) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      feature as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // How It Works Section
                      Text(
                        'How This Works',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: (scheme['howItWorks'] as List).asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value as String;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Terms Section (Collapsible)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _termsExpanded = !_termsExpanded;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Terms & Conditions',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Icon(
                                    _termsExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              if (_termsExpanded) ...[
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 16),
                                _buildTermItem('Minimum age: 18 years'),
                                const SizedBox(height: 12),
                                _buildTermItem('Payment must be made on or before due date'),
                                const SizedBox(height: 12),
                                _buildTermItem('Grams allocated based on market price at time of payment'),
                                const SizedBox(height: 12),
                                _buildTermItem('Early redemption may incur charges'),
                                const SizedBox(height: 12),
                                _buildTermItem('All investments are subject to market risks'),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // CTA Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to enrollment
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Start This Investment',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SchemesScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Compare Other Schemes',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTermItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, color: AppColors.textSecondary, size: 6),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'monetization_on':
        return Icons.monetization_on;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.monetization_on;
    }
  }
}

