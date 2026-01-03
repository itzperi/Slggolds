// lib/screens/customer/schemes_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import 'scheme_detail_screen.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

enum SchemeFilter { all, gold, silver }

class _SchemesScreenState extends State<SchemesScreen> {
  bool _isRefreshing = false;
  SchemeFilter _selectedFilter = SchemeFilter.all;

  Future<void> _refreshSchemes() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call to refresh schemes
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Schemes refreshed',
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

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Investment Schemes',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterButton(
                          label: 'All',
                          filter: SchemeFilter.all,
                          icon: Icons.grid_view,
                        ),
                      ),
                      Expanded(
                        child: _buildFilterButton(
                          label: 'Gold',
                          filter: SchemeFilter.gold,
                          icon: Icons.monetization_on,
                        ),
                      ),
                      Expanded(
                        child: _buildFilterButton(
                          label: 'Silver',
                          filter: SchemeFilter.silver,
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Schemes List with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshSchemes,
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFF2A1454),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: _getFilteredSchemes().map((scheme) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSchemeCard(
                          context: context,
                          schemeId: scheme['schemeId'] as String,
                          title: scheme['title'] as String,
                          description: scheme['description'] as String,
                          duration: scheme['duration'] as String,
                          minDailyAmount: scheme['minDailyAmount'] as int,
                          maxDailyAmount: scheme['maxDailyAmount'] as int,
                          metalAccumulation: scheme['metalAccumulation'] as String,
                          entryFee: scheme['entryFee'] as int,
                          benefits: scheme['benefits'] as List<String>,
                          icon: scheme['icon'] as IconData,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSchemes() {
    final allSchemes = [
      // Gold Schemes 1-9
      {
        'schemeId': 'gold-scheme-1',
        'title': 'Gold Scheme 1',
        'description': 'Invest ₹50-200 daily for gold savings. Accumulate 500 mg of Gold',
        'duration': '12 Months',
        'minDailyAmount': 50,
        'maxDailyAmount': 200,
        'metalAccumulation': '500 mg',
        'entryFee': 100,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-2',
        'title': 'Gold Scheme 2',
        'description': 'Invest ₹250-500 daily for gold savings. Accumulate 1 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 250,
        'maxDailyAmount': 500,
        'metalAccumulation': '1 g',
        'entryFee': 200,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-3',
        'title': 'Gold Scheme 3',
        'description': 'Invest ₹550-1000 daily for gold savings. Accumulate 2 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 550,
        'maxDailyAmount': 1000,
        'metalAccumulation': '2 g',
        'entryFee': 300,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-4',
        'title': 'Gold Scheme 4',
        'description': 'Invest ₹1,050-1,500 daily for gold savings. Accumulate 3 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 1050,
        'maxDailyAmount': 1500,
        'metalAccumulation': '3 g',
        'entryFee': 300,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-5',
        'title': 'Gold Scheme 5',
        'description': 'Invest ₹1,550-2,000 daily for gold savings. Accumulate 5 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 1550,
        'maxDailyAmount': 2000,
        'metalAccumulation': '5 g',
        'entryFee': 300,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-6',
        'title': 'Gold Scheme 6',
        'description': 'Invest ₹2,050-2,500 daily for gold savings. Accumulate 5 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 2050,
        'maxDailyAmount': 2500,
        'metalAccumulation': '5 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-7',
        'title': 'Gold Scheme 7',
        'description': 'Invest ₹2,550-3,000 daily for gold savings. Accumulate 6 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 2550,
        'maxDailyAmount': 3000,
        'metalAccumulation': '6 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-8',
        'title': 'Gold Scheme 8',
        'description': 'Invest ₹3,100-3,900 daily for gold savings. Accumulate 8 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 3100,
        'maxDailyAmount': 3900,
        'metalAccumulation': '8 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      {
        'schemeId': 'gold-scheme-9',
        'title': 'Gold Scheme 9',
        'description': 'Invest ₹3,950-5,000 daily for gold savings. Accumulate 10 g of Gold',
        'duration': '12 Months',
        'minDailyAmount': 3950,
        'maxDailyAmount': 5000,
        'metalAccumulation': '10 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Gold accumulation', 'Higher returns'],
        'icon': Icons.monetization_on,
        'type': 'gold',
      },
      // Silver Schemes 1-9
      {
        'schemeId': 'silver-scheme-1',
        'title': 'Silver Scheme 1',
        'description': 'Invest ₹50-200 daily for silver savings. Accumulate 25 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 50,
        'maxDailyAmount': 200,
        'metalAccumulation': '25 g',
        'entryFee': 100,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-2',
        'title': 'Silver Scheme 2',
        'description': 'Invest ₹250-500 daily for silver savings. Accumulate 50 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 250,
        'maxDailyAmount': 500,
        'metalAccumulation': '50 g',
        'entryFee': 200,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-3',
        'title': 'Silver Scheme 3',
        'description': 'Invest ₹550-1,000 daily for silver savings. Accumulate 100 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 550,
        'maxDailyAmount': 1000,
        'metalAccumulation': '100 g',
        'entryFee': 300,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-4',
        'title': 'Silver Scheme 4',
        'description': 'Invest ₹1,050-1,500 daily for silver savings. Accumulate 150 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 1050,
        'maxDailyAmount': 1500,
        'metalAccumulation': '150 g',
        'entryFee': 300,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-5',
        'title': 'Silver Scheme 5',
        'description': 'Invest ₹1,550-2,000 daily for silver savings. Accumulate 200 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 1550,
        'maxDailyAmount': 2000,
        'metalAccumulation': '200 g',
        'entryFee': 300,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-6',
        'title': 'Silver Scheme 6',
        'description': 'Invest ₹2,050-2,500 daily for silver savings. Accumulate 250 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 2050,
        'maxDailyAmount': 2500,
        'metalAccumulation': '250 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-7',
        'title': 'Silver Scheme 7',
        'description': 'Invest ₹2,550-3,000 daily for silver savings. Accumulate 300 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 2550,
        'maxDailyAmount': 3000,
        'metalAccumulation': '300 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-8',
        'title': 'Silver Scheme 8',
        'description': 'Invest ₹3,100-3,900 daily for silver savings. Accumulate 500 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 3100,
        'maxDailyAmount': 3900,
        'metalAccumulation': '500 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
      {
        'schemeId': 'silver-scheme-9',
        'title': 'Silver Scheme 9',
        'description': 'Invest ₹3,950-5,000 daily for silver savings. Accumulate 550 g of Silver',
        'duration': '12 Months',
        'minDailyAmount': 3950,
        'maxDailyAmount': 5000,
        'metalAccumulation': '550 g',
        'entryFee': 500,
        'benefits': ['Daily/Weekly/Monthly payments', 'Silver accumulation', 'Affordable entry'],
        'icon': Icons.account_balance_wallet,
        'type': 'silver',
      },
    ];

    switch (_selectedFilter) {
      case SchemeFilter.gold:
        return allSchemes.where((scheme) => scheme['type'] == 'gold').toList();
      case SchemeFilter.silver:
        return allSchemes.where((scheme) => scheme['type'] == 'silver').toList();
      case SchemeFilter.all:
      default:
        return allSchemes;
    }
  }

  Widget _buildFilterButton({
    required String label,
    required SchemeFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard({
    required BuildContext context,
    required String schemeId,
    required String title,
    required String description,
    required String duration,
    required int minDailyAmount,
    required int maxDailyAmount,
    required String metalAccumulation,
    required int entryFee,
    required List<String> benefits,
    required IconData icon,
  }) {
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.2), // Reduced from 0.3 to 0.2
                      AppColors.primary.withOpacity(0.08), // Reduced from 0.1 to 0.08
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Duration', duration),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Amount',
                  '₹${_formatCurrency(minDailyAmount.toDouble())} - ₹${_formatCurrency(maxDailyAmount.toDouble())}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      benefit,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchemeDetailScreen(schemeId: schemeId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.9), // More subtle
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2, // Subtle elevation instead of strong shadow
              ),
              child: Text(
                'View Details',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

