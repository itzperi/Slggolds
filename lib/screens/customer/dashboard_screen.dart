import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/constants.dart';
import '../../state/customer/customer_providers.dart';
import 'package:shimmer/shimmer.dart';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  bool _animationsCompleted = false;
  bool _isRefreshing = false;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;


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
    
    // Monitor connectivity
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      }
    });
  }
  
  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (mounted) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      }
    } catch (_) {
      // Handle error silently
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(customerProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile not found')));
        }
        
        final customerData = profile['customers'] is List 
            ? profile['customers'][0] 
            : profile['customers'];
        final customerId = customerData['id'];

        // Watch dashboard metrics to determine state (loading vs empty vs active)
        final metricsAsync = ref.watch(customerDashboardProvider(customerId));

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: metricsAsync.when(
            data: (metrics) {
              // CHECK IF NEW USER (No schemes)
              final bool isNewUser = (metrics['schemes_count'] ?? 0) == 0;
              
              if (isNewUser) {
                return _buildEmptyState(profile, customerId);
              }

              return IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDashboardContent(profile, customerId),
                  const SchemesScreen(),
                  const ProfileScreen(),
                ],
              );
            },
            loading: () => _buildFullShimmerLoading(),
            error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
          ),
          bottomNavigationBar: _buildBottomNavigation(),
        );
      },
      loading: () => _buildFullShimmerLoading(),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  // NEW USER EMPTY STATE (Golden Path)
  Widget _buildEmptyState(Map<String, dynamic> profile, String customerId) {
     return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF2A1454), const Color(0xFF140A33)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(profile),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie/Image placeholder could go here
                      Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.white24),
                      const SizedBox(height: 24),
                      Text(
                        "Welcome to SLG-GOLDS!",
                        style: GoogleFonts.outfit(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Ask your collection staff to enroll you in your first Gold or Silver scheme.",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          // In production: open WhatsApp or Phone
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Open WhatsApp to contact staff')),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("Contact Staff"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ); 
  }

  Widget _buildFullShimmerLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF2A1454),
      body: SafeArea(
        child: Column(
          children: [
            _buildShimmerHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildShimmerHero(),
                    const SizedBox(height: 16),
                    _buildShimmerMetrics(),
                    const SizedBox(height: 16),
                    _buildShimmerAssets(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDashboardContent(Map<String, dynamic> profile, String customerId) {
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
            Column(
              children: [
                // HEADER - Top bar with greeting and gold price
                _buildHeader(profile),

                      // MAIN CONTENT - Scrollable with pull-to-refresh
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _refreshDashboard(customerId),

                          color: AppColors.primary,
                          backgroundColor: const Color(0xFF2A1454),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CARD 1 & 2: Main Portfolio Metrics
                                _buildPortfolioGrid(customerId),

                                // CARD 3: Next Payment (Urgency indicator)
                                _buildNextPaymentCard(customerId),

                                // CARD 4: Payments Progress
                                _buildProgressCard(customerId),

                                // CARD 5: Recent Activity
                                _buildRecentActivity(customerId),

                                // TRUST INDICATORS
                                _buildTrustIndicators(),

                                // MY ACTIVE SCHEMES
                                _buildActiveSchemes(customerId),

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

  Future<void> _refreshDashboard(String customerId) async {
    setState(() {
      _isRefreshing = true;
    });

    // Refresh all data providers
    ref.invalidate(customerDashboardProvider(customerId));
    ref.invalidate(marketRatesProvider);
    ref.invalidate(customerSchemesProvider(customerId));
    ref.invalidate(customerPaymentsProvider(customerId));

    await Future.delayed(const Duration(milliseconds: 500));

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



  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }


  Widget _buildHeader(Map<String, dynamic> profile) {
    // Get user initial for avatar
    final userName = profile['name'] ?? 'User';
    final userInitial = userName.isNotEmpty
        ? userName[0].toUpperCase()
        : 'U';

    final ratesAsync = ref.watch(marketRatesProvider);


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
                      userName,
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

          // Right: Offline indicator + Gold & Silver price chips
          Row(
            children: [
              // Offline Indicator
              if (!_isOnline)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: AppColors.warning,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Market Rates
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
                      child: ratesAsync.when(
                        data: (rates) => Column(
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
                                    '₹${_formatNumber(rates['gold'])}',
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
                                  rates['gold_change'] >= 0
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: rates['gold_change'] >= 0
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
                                    '₹${_formatNumber(rates['silver'])}',
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
                                  rates['silver_change'] >= 0
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: rates['silver_change'] >= 0
                                      ? AppColors.success
                                      : AppColors.danger,
                                  size: 12,
                                ),
                              ],
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(height: 32, width: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (_, __) => const Icon(Icons.error_outline, color: Colors.white24, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CARD 1 & 2: Grams and Market Value
  Widget _buildPortfolioGrid(String customerId) {
    final metricsAsync = ref.watch(customerDashboardProvider(customerId));
    return metricsAsync.when(
      data: (metrics) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Total Grams Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.2), Colors.white.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Gold & Silver', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${((metrics['total_grams'] ?? 0) as num).toStringAsFixed(3)} Grams',
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (((metrics['gold_grams'] ?? 0) as num) > 0 || ((metrics['silver_grams'] ?? 0) as num) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                if (((metrics['gold_grams'] ?? 0) as num) > 0)
                                  _buildAssetMiniTag('Gold', '${metrics['gold_grams'] ?? 0}g', AppColors.primary),
                                if (((metrics['silver_grams'] ?? 0) as num) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: _buildAssetMiniTag('Silver', '${metrics['silver_grams'] ?? 0}g', Colors.white60),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Market Value Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet, color: AppColors.success, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Market Value', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_formatCurrency(metrics['market_value'])}',
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                        Text(
                          'Based on live rates',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => _buildShimmerHero(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAssetMiniTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // CARD 3: Next Payment
  Widget _buildNextPaymentCard(String customerId) {
    final metricsAsync = ref.watch(customerDashboardProvider(customerId));
    return metricsAsync.when(
      data: (metrics) {
        final nextDueStr = metrics['next_due'];
        if (nextDueStr == null) return const SizedBox.shrink();
        
        final nextDue = DateTime.parse(nextDueStr);
        final now = DateTime.now();
        final daysDiff = nextDue.difference(DateTime(now.year, now.month, now.day)).inDays;
        
        Color statusColor = AppColors.success;
        String statusText = 'On Track';
        IconData statusIcon = Icons.check_circle_outline;
        
        if (daysDiff < 0) {
          statusColor = AppColors.danger;
          statusText = 'Overdue';
          statusIcon = Icons.error_outline;
        } else if (daysDiff <= 3) {
          statusColor = AppColors.warning;
          statusText = 'Due Soon';
          statusIcon = Icons.access_time;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Payment Due', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEE, dd MMM yyyy').format(nextDue),
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScheduleScreen())),
                  child: Text('View All', style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // CARD 4: Payments Progress
  Widget _buildProgressCard(String customerId) {
    final metricsAsync = ref.watch(customerDashboardProvider(customerId));
    return metricsAsync.when(
      data: (metrics) {
        final progress = (metrics['progress'] as num?)?.toDouble() ?? 0.0;
        final made = metrics['total_payments_made'] ?? 0;
        final total = metrics['total_expected_payments'] ?? 0;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundLighter,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payments Progress', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have completed $made out of $total expected payments across all active schemes.',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }


  Widget _buildKeyMetrics(String customerId) {
    final metricsAsync = ref.watch(customerDashboardProvider(customerId));

    return metricsAsync.when(
      data: (metrics) => TweenAnimationBuilder<double>(
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
                    // Active Schemes Count
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
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Schemes',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${metrics['schemes_count']}',
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

                    const SizedBox(width: 12),

                    // Next Due Date
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
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Due',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metrics['next_due'] != null 
                                  ? DateFormat('dd MMM').format(DateTime.parse(metrics['next_due']))
                                  : 'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
        },
      ),
      loading: () => _buildShimmerMetrics(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }



  Widget _buildAssetHoldings(String customerId) {
    final metricsAsync = ref.watch(customerDashboardProvider(customerId));
    final ratesAsync = ref.watch(marketRatesProvider);

    return metricsAsync.when(
      data: (metrics) => ratesAsync.when(
        data: (rates) => Column(
          children: [
            // Gold Holdings Card
            _buildAssetCard(
              icon: Icons.monetization_on,
              iconColor: AppColors.primary,
              title: 'Gold Holdings',
              amount: '${metrics['gold_grams'].toStringAsFixed(3)} g',
              value: metrics['gold_grams'] * rates['gold'],
              changePercent: 0, // Mock for now or calculate if history available
              borderColor: AppColors.primary,
              isGold: true,
            ),

            const SizedBox(height: 12),

            // Silver Holdings Card
            _buildAssetCard(
              icon: Icons.monetization_on,
              iconColor: AppColors.textSecondary,
              title: 'Silver Holdings',
              amount: '${metrics['silver_grams'].toStringAsFixed(3)} g',
              value: metrics['silver_grams'] * rates['silver'],
              changePercent: 0,
              borderColor: AppColors.textSecondary,
              isGold: false,
            ),
          ],
        ),
        loading: () => _buildShimmerAssets(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => _buildShimmerAssets(),
      error: (_, __) => const SizedBox.shrink(),
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
  Widget _buildPaymentCalendar(String customerId) {
    final metricsAsync = ref.watch(customerDashboardProvider(customerId));
    final today = DateTime.now();

    return metricsAsync.when(
      data: (metrics) {
        final nextDueStr = metrics['next_due'];
        final nextDue = nextDueStr != null ? DateTime.parse(nextDueStr) : null;
        
        // Construct a simple preview based on next due if available
        final List<Map<String, dynamic>> calendarData = [];
        if (nextDue != null) {
          calendarData.add({
            'date': nextDue,
            'dayNum': DateFormat('dd').format(nextDue),
            'dayName': DateFormat('E').format(nextDue),
            'status': 'DUE',
          });
          
          // Add some upcoming mock placeholders for UI richness
          for (int i = 1; i < 5; i++) {
            final date = nextDue.add(Duration(days: i * 30));
            calendarData.add({
              'date': date,
              'dayNum': DateFormat('dd').format(date),
              'dayName': DateFormat('E').format(date),
              'status': 'UPCOMING',
            });
          }
        }

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
      },
      loading: () => _buildShimmerCalendar(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }


  Widget _buildRecentActivity(String customerId) {
    final paymentsAsync = ref.watch(customerPaymentsProvider(customerId));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildComponentPlaceholder(
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

              // Transaction rows
              ...payments.asMap().entries.map((entry) {
                final index = entry.key;
                final txn = entry.value;
                final isLast = index == payments.length - 1;
                
                final amount = (txn['amount'] as num).toDouble();
                final dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(txn['created_at']));
                final status = txn['status'] as String;

                return _buildTransactionRow(
                  date: dateStr,
                  amount: amount,
                  status: status.toUpperCase(),
                  isLast: isLast,
                  schemeName: txn['user_schemes']?['schemes']?['name'] ?? 'Gold Scheme',
                );
              }),
              
              const SizedBox(height: 12),
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
      },
      loading: () => _buildShimmerRecent(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }





  Widget _buildTransactionRow({
    required String date,
    required double amount,
    required String status,
    required bool isLast,
    required String schemeName,
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
                  transactionId: 'TXN-${date.replaceAll(' ', '')}',
                  method: 'N/A',
                  scheme: schemeName,
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
  Widget _buildActiveSchemes(String customerId) {
    final schemesAsync = ref.watch(customerSchemesProvider(customerId));

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
          child: schemesAsync.when(
            data: (schemes) {
              if (schemes.isEmpty) {
                return _buildActiveSchemesEmptyState();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: schemes.length,
                itemBuilder: (context, index) {
                  final s = schemes[index];
                  // Map raw DB data to card expected format
                  final cardData = {
                    'scheme_id': s['scheme_id'],
                    'scheme_name': s['schemes']?['name'] ?? 'Unknown',
                    'scheme_type': s['schemes']?['asset_type'] ?? 'Gold',
                    'payments_made': s['payments_made'] ?? 0,
                    // Use a default or calculated duration if not in metadata
                    'total_payments': (s['schemes']?['duration_months'] as int?) != null ? (s['schemes']!['duration_months'] as int) * 30 : 365,
                    'accumulated_metal': '${s['accumulated_grams'] ?? 0} g',
                  };
                  return _buildActiveSchemeCard(cardData);
                },
              );
            },
            loading: () => _buildShimmerActiveSchemes(),
            error: (_, __) => _buildActiveSchemesEmptyState(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
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

  // COMPONENT PLACEHOLDER (For lists/sections)
  Widget _buildComponentPlaceholder({
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
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white38,
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

  Widget _buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }


  // SHIMMER LOADING WIDGETS
  Widget _buildShimmerHero() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildShimmerMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(2, (index) => Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              margin: EdgeInsets.only(left: index == 1 ? 12 : 0, right: index == 0 ? 12 : 0),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildShimmerAssets() {
    return Column(
      children: List.generate(2, (index) => Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      )),
    );
  }

  Widget _buildShimmerCalendar() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildShimmerRecent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 150, height: 20, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShimmerActiveSchemes() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}


