// lib/screens/customer/dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/mock_data.dart';
import 'transaction_detail_screen.dart';
import 'schemes_screen.dart';
import 'scheme_detail_screen.dart';
import 'profile_screen.dart';
import 'gold_asset_detail_screen.dart';
import 'silver_asset_detail_screen.dart';
import 'market_rates_screen.dart';
import 'payment_schedule_screen.dart';
import 'total_investment_screen.dart';
import 'transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final bool _isLoading = false;
  bool _animationsCompleted = false;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _activeSchemes = [];

  @override
  void initState() {
    super.initState();
    // Trigger animations after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _animationsCompleted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(),
          const SchemesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
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
        child: Stack(
          children: [
            // Vignette overlay (optimized - only render once)
            if (_animationsCompleted)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Main content
            _isLoading
                ? _buildLoadingState()
                : Column(
                    children: [
                      // HEADER - Top bar with greeting and gold price
                      _buildHeader(),

                      // MAIN CONTENT - Scrollable with pull-to-refresh
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshDashboard,
                          color: AppColors.primary,
                          backgroundColor: const Color(0xFF2A1454),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            // HERO SECTION - The Wealth Card
                            _buildHeroCard(),

                            // KEY METRICS ROW
                            _buildKeyMetrics(),

                                // ASSET HOLDINGS GRID
                                _buildAssetHoldings(),

                                // PAYMENT CALENDAR
                                _buildPaymentCalendar(),

                                // RECENT ACTIVITY
                                _buildRecentActivity(),

                                // TRUST INDICATORS
                                _buildTrustIndicators(),

                                // MY ACTIVE SCHEMES
                                _buildActiveSchemes(),

                                // Bottom spacing for navigation bar
                                const SizedBox(height: 100),
                              ],
                            ),
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

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call to refresh data
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dashboard refreshed',
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

  // LOADING STATE - Skeleton loaders
  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSkeletonCard(height: 120),
              const SizedBox(height: 16),
              _buildSkeletonCard(height: 60),
              const SizedBox(height: 16),
              _buildSkeletonCard(height: 100),
              const SizedBox(height: 16),
              _buildSkeletonCard(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
                  ),
                );
              }

  // HEADER - Top bar with greeting and gold price chip with change
  Widget _buildHeader() {
    // Get user initial for avatar
    final userInitial = MockData.userName.isNotEmpty
        ? MockData.userName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarker,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Avatar + Greeting with premium typography
          Row(
            children: [
              // User Avatar Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryLight.withOpacity(0.9), // More subtle
                      AppColors.primary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    userInitial,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Greeting with premium typography (optimized - no animation rebuild)
              AnimatedOpacity(
                opacity: _animationsCompleted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vanakkam',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MockData.userName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Right: Gold & Silver price chips
          Flexible(
            child: AnimatedOpacity(
              opacity: _animationsCompleted ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketRatesScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryLight.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Gold price
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Au',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '₹${_formatNumber(MockData.goldPricePerGram)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            MockData.goldPriceChange > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: MockData.goldPriceChange > 0
                                ? AppColors.success
                                : AppColors.danger,
                            size: 12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Silver price
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ag',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '₹${_formatNumber(MockData.silverPricePerGram)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            MockData.silverPriceChange > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: MockData.silverPriceChange > 0
                                ? AppColors.success
                                : AppColors.danger,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HERO SECTION - The Wealth Card with glassmorphism and premium glows (optimized)
  Widget _buildHeroCard() {
    return AnimatedOpacity(
      opacity: _animationsCompleted ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2), // Reduced from 0.4 to 0.2 (50% reduction)
              blurRadius: 35,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main portfolio value with subtle glow
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3), // Reduced from 0.6 to 0.3 (50% reduction)
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '₹${_formatCurrency(MockData.portfolioValue)}',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                  height: 1.1,
                  shadows: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15), // Reduced from 0.3 to 0.15 (50% reduction)
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Net Wealth Accumulated',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 12),

            // Today's change
            Row(
              children: [
                Icon(
                  MockData.isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: MockData.isProfit ? AppColors.success : AppColors.danger,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${MockData.isProfit ? '+' : '-'}₹${_formatCurrency(MockData.todayChange)} today',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MockData.isProfit ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // KEY METRICS ROW - Total Investment, Return % with glassmorphism
  Widget _buildKeyMetrics() {
    final returnPercent = MockData.overallReturnPercent;
    final isPositiveReturn = returnPercent >= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Total Investment
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TotalInvestmentScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Investment',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_formatCurrency(MockData.totalInvestment)}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Return Percentage (optimized - no animation rebuild)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Return',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPositiveReturn ? Icons.trending_up : Icons.trending_down,
                                color: isPositiveReturn ? AppColors.success : AppColors.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${isPositiveReturn ? '+' : ''}${returnPercent.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isPositiveReturn ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
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
      },
    );
  }


  // ASSET HOLDINGS GRID - With value in rupees and percentage change
  Widget _buildAssetHoldings() {
    return Column(
      children: [
        // Gold Holdings Card
        _buildAssetCard(
          icon: Icons.monetization_on,
          iconColor: AppColors.primary,
          title: 'Gold Holdings',
          amount: '${MockData.goldGrams} g',
          value: MockData.goldValue,
          changePercent: MockData.goldChangePercent,
          borderColor: AppColors.primary,
          isGold: true,
        ),

        const SizedBox(height: 12),

        // Silver Holdings Card
        _buildAssetCard(
          icon: Icons.monetization_on,
          iconColor: AppColors.textSecondary,
          title: 'Silver Holdings',
          amount: '${MockData.silverGrams} g',
          value: MockData.silverValue,
          changePercent: MockData.silverChangePercent,
          borderColor: AppColors.textSecondary,
          isGold: false,
        ),
      ],
    );
  }

  Widget _buildAssetCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required double value,
    required double changePercent,
    required Color borderColor,
    required bool isGold,
  }) {
    final isPositive = changePercent >= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (borderColor == AppColors.primary ? 0 : 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: GestureDetector(
              onTap: () {
                if (isGold) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoldAssetDetailScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SilverAssetDetailScreen(),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(
                          color: borderColor,
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: Icon with gradient container
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                iconColor.withOpacity(0.25),
                                iconColor.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 32,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Right: Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPositive ? Icons.trending_up : Icons.trending_down,
                                        color: isPositive ? AppColors.success : AppColors.danger,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isPositive ? AppColors.success : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                amount,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${_formatCurrency(value)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  // PAYMENT CALENDAR - Next 5 upcoming payment dates preview
  Widget _buildPaymentCalendar() {
    final calendarData = MockData.paymentCalendarPreview;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Payment Plan",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Based on your active schemes",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Horizontal scrollable calendar with glassmorphism
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: calendarData.length + 1, // +1 for "View All" button
                itemBuilder: (context, index) {
                  if (index == calendarData.length) {
                    // "View All" button
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentScheduleScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, left: 8),
                        width: 70,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View All',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final dayData = calendarData[index];
                  final date = dayData['date'] as DateTime;
                  final dayNum = dayData['dayNum'] as String;
                  final dayName = dayData['dayName'] as String;
                  final status = dayData['status'] as String;
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  IconData statusIcon;
                  Color statusColor;

                  if (status == 'PAID') {
                    statusIcon = Icons.check_circle;
                    statusColor = AppColors.success;
                  } else if (status == 'MISSED') {
                    statusIcon = Icons.cancel;
                    statusColor = AppColors.danger;
                  } else if (status == 'DUE' || (status == 'UPCOMING' && isToday)) {
                    statusIcon = Icons.circle_outlined;
                    statusColor = AppColors.primary;
                  } else {
                    statusIcon = Icons.circle_outlined;
                    statusColor = AppColors.textSecondary;
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDarker.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(
                              color: AppColors.primary,
                              width: 2,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNum,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 18,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // RECENT ACTIVITY - Enhanced with only PAID transactions
  Widget _buildRecentActivity() {
    // Filter only PAID transactions
    final paidTransactions = MockData.recentTransactions
        .where((transaction) => transaction['status'] == 'PAID')
        .toList();

    if (paidTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        message: 'No recent transactions',
        subtitle: 'Your transaction history will appear here',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Recent Transactions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Transaction rows with slide-up animation
          ...paidTransactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            final isLast = index == paidTransactions.length - 1;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 500 + (index * 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: _buildTransactionRow(
                      date: transaction['date'] as String,
                      amount: transaction['amount'] as int,
                      status: transaction['status'] as String,
                      isLast: isLast,
                    ),
                  ),
                );
              },
            );
          }),

          const SizedBox(height: 16),

          // View All link
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
              child: Text(
                'View All Transactions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow({
    required String date,
    required int amount,
    required String status,
    required bool isLast,
  }) {
    final isPaid = status == 'PAID';
    final statusIcon = isPaid ? Icons.check_circle : Icons.cancel;
    final statusColor = isPaid ? AppColors.success : AppColors.danger;

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(
                  date: date,
                  amount: amount,
                  status: status,
                  transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                  method: 'UPI',
                  scheme: 'Monthly Gold Plan',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Icon + Date
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withOpacity(0.2),
                                  AppColors.primary.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              date,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Amount + Status icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '₹${_formatCurrency(amount.toDouble())}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

        // Divider
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textSecondary.withOpacity(0.05),
          ),
      ],
    );
  }

  // TRUST INDICATORS
  Widget _buildTrustIndicators() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTrustBadge(
            icon: Icons.verified,
            label: 'Verified',
          ),
          const SizedBox(width: 12),
          _buildTrustBadge(
            icon: Icons.security,
            label: 'Secure',
          ),
          const SizedBox(width: 12),
          _buildTrustBadge(
            icon: Icons.workspace_premium,
            label: 'Premium',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // MY ACTIVE SCHEMES
  Widget _buildActiveSchemes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text(
            'My Active Schemes',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        // Horizontal scrollable scheme cards
        SizedBox(
          height: 180,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchActiveSchemes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildActiveSchemesEmptyState();
              }

              final schemes = snapshot.data ?? [];

              if (schemes.isEmpty) {
                return _buildActiveSchemesEmptyState();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: schemes.length,
                itemBuilder: (context, index) {
                  return _buildActiveSchemeCard(schemes[index]);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchActiveSchemes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        final mockSchemes = _getMockActiveSchemes();
        _activeSchemes = mockSchemes;
        return mockSchemes;
      }

      // Query user's active schemes from Supabase
      // Note: Adjust table name and columns based on your actual database schema
      final response = await Supabase.instance.client
          .from('user_schemes')
          .select('*, schemes(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('enrollment_date', ascending: false);

      if (response == null || response.isEmpty) {
        // Return mock data for now if no database entries
        final mockSchemes = _getMockActiveSchemes();
        _activeSchemes = mockSchemes;
        return mockSchemes;
      }

      // Transform the data to match our card structure
      final schemes = (response as List).map((scheme) {
        final schemeData = scheme['schemes'] ?? {};
        return {
          'scheme_id': scheme['scheme_id'] ?? schemeData['id'] ?? '',
          'scheme_name': schemeData['name'] ?? 'Unknown Scheme',
          'scheme_type': schemeData['type'] ?? 'Gold',
          'scheme_number': _extractSchemeNumber(schemeData['name'] ?? ''),
          'enrollment_date': scheme['enrollment_date'] ?? DateTime.now().toIso8601String(),
          'payments_made': scheme['payments_made'] ?? 0,
          'total_payments': scheme['total_payments'] ?? 365,
          'total_amount_paid': scheme['total_amount_paid'] ?? 0.0,
          'accumulated_metal': _calculateAccumulatedMetal(
            scheme['payments_made'] ?? 0,
            scheme['total_payments'] ?? 365,
            schemeData['metalAccumulation'] ?? '0 g',
            schemeData['type'] ?? 'Gold',
          ),
          'payment_frequency': scheme['payment_frequency'] ?? 'daily',
          'min_amount': schemeData['minDailyAmount'] ?? schemeData['min_amount'] ?? 0.0,
          'max_amount': schemeData['maxDailyAmount'] ?? schemeData['max_amount'] ?? 0.0,
        };
      }).toList();
      
      _activeSchemes = schemes;
      return schemes;
    } catch (e) {
      // If database query fails, return mock data
      print('Error fetching active schemes: $e');
      final mockSchemes = _getMockActiveSchemes();
      _activeSchemes = mockSchemes;
      return mockSchemes;
    }
  }

  List<Map<String, dynamic>> _getMockActiveSchemes() {
    // Return mock active schemes for testing
    // In production, this should come from the database
    return [
      {
        'scheme_id': 'gold-scheme-3',
        'scheme_name': 'Gold Scheme 3',
        'scheme_type': 'Gold',
        'scheme_number': '3',
        'enrollment_date': DateTime.now().subtract(const Duration(days: 240)).toIso8601String(),
        'payments_made': 240,
        'total_payments': 365,
        'total_amount_paid': 186000.0,
        'accumulated_metal': '1.32g',
        'payment_frequency': 'daily',
        'min_amount': 750.0,
        'max_amount': 1000.0,
      },
      {
        'scheme_id': 'silver-scheme-1',
        'scheme_name': 'Silver Scheme 1',
        'scheme_type': 'Silver',
        'scheme_number': '1',
        'enrollment_date': DateTime.now().subtract(const Duration(days: 150)).toIso8601String(),
        'payments_made': 150,
        'total_payments': 365,
        'total_amount_paid': 18750.0,
        'accumulated_metal': '10.3g',
        'payment_frequency': 'daily',
        'min_amount': 125.0,
        'max_amount': 150.0,
      },
    ];
  }


  String _extractSchemeNumber(String schemeName) {
    // Extract scheme number from name like "Gold Scheme 3" -> "3"
    final match = RegExp(r'(\d+)').firstMatch(schemeName);
    return match?.group(1) ?? '1';
  }

  String _calculateAccumulatedMetal(
    int paymentsMade,
    int totalPayments,
    String targetMetal,
    String metalType,
  ) {
    try {
      // Extract numeric value from target metal (e.g., "2 g" -> 2.0, "500 mg" -> 0.5)
      final targetValue = _parseMetalAmount(targetMetal);
      final progress = paymentsMade / totalPayments;
      final accumulated = progress * targetValue;

      // Format based on amount
      if (accumulated < 1.0) {
        return '${(accumulated * 1000).toStringAsFixed(0)}mg';
      } else {
        return '${accumulated.toStringAsFixed(2)}g';
      }
    } catch (e) {
      return '0g';
    }
  }

  double _parseMetalAmount(String metalString) {
    // Parse strings like "2 g", "500 mg", "1g", etc.
    final cleaned = metalString.toLowerCase().trim();
    if (cleaned.contains('mg')) {
      final value = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      return value / 1000; // Convert mg to g
    } else {
      return double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
  }

  Widget _buildActiveSchemeCard(Map<String, dynamic> scheme) {
    final isGold = scheme['scheme_type'] == 'Gold';
    final schemeName = '${scheme['scheme_type']} Scheme ${scheme['scheme_number']}';
    final paymentsMade = scheme['payments_made'] as int;
    final totalPayments = scheme['total_payments'] as int;
    final accumulatedMetal = scheme['accumulated_metal'] as String;
    final schemeId = scheme['scheme_id'] as String;
    final totalPaid = (scheme['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
    final gstAmount = totalPaid * 0.03;
    final netInvestment = totalPaid * 0.97;
    final withdrawals = (scheme['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final currentBalance = netInvestment - withdrawals;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SchemeDetailScreen(
                  schemeId: schemeId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and name
                Row(
                  children: [
                    Icon(
                      isGold ? Icons.monetization_on : Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schemeName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress
                Text(
                  '$paymentsMade/$totalPayments payments',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                // Accumulated metal
                Text(
                  'Accumulated:',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$accumulatedMetal ${scheme['scheme_type']}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (totalPaid > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Total Paid: ₹${_formatCurrency(totalPaid)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  if (gstAmount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'GST (3%): ₹${_formatCurrency(gstAmount)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Net: ₹${_formatCurrency(netInvestment)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (withdrawals > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Withdrawals: ₹${_formatCurrency(withdrawals)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ₹${_formatCurrency(currentBalance)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const Spacer(),
                // View Details link
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 14,
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

  Widget _buildActiveSchemesEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance,
              color: Colors.white.withOpacity(0.3),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'No active schemes yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1; // Navigate to Schemes tab
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              child: Text(
                'Browse Schemes',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION - With active indicator and premium styling
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1035),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _showFeedback();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1B1035),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 26,
        selectedIconTheme: IconThemeData(
          color: AppColors.primary,
          size: 26,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.6),
          size: 24,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: _currentIndex == 0
                  ? BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Icons.dashboard,
              ),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: _currentIndex == 1
                  ? BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(Icons.account_balance),
            ),
            label: 'Schemes',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: _currentIndex == 2
                  ? BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(Icons.person_outline),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Helper method to format currency with Indian numbering system
  String _formatCurrency(double amount) {
    return _formatNumber(amount.toInt());
  }

  String _formatNumber(int number) {
    final String numberStr = number.toString();

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

  // Micro-interaction feedback
  void _showFeedback() {
    HapticFeedback.lightImpact();
  }
}

