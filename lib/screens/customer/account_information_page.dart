// lib/screens/customer/account_information_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../utils/mock_data.dart';

class AccountInformationPage extends StatefulWidget {
  const AccountInformationPage({super.key});

  @override
  State<AccountInformationPage> createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  bool _isLoading = false;
  bool _isPersonalExpanded = true;
  bool _isNomineeExpanded = true;
  bool _isSchemeExpanded = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Mock data for account information - replace with actual data from backend
  final Map<String, String> accountData = {
    'fullName': 'Ravi Kumar',
    'dateOfBirth': '15 Jan 1990',
    'fatherName': 'Rajesh Kumar',
    'birthPlace': 'Chennai, Tamil Nadu',
    'aadhaarNo': '1234 5678 9012',
    'gender': 'Male',
    'businessAddress': '123 Business Street, Chennai, Tamil Nadu - 600001',
    'residentialAddress': '456 Residential Avenue, Chennai, Tamil Nadu - 600002',
    'cellNo': '+91 98765 43210',
    'email': 'ravi@example.com',
  };

  final Map<String, String> nomineeData = {
    'fullName': 'Priya Kumar',
    'gender': 'Female',
    'fatherName': 'Suresh Kumar',
    'age': '28',
    'relationship': 'Spouse',
    'birthPlace': 'Chennai, Tamil Nadu',
    'address': '456 Residential Avenue, Chennai, Tamil Nadu - 600002',
  };

  final Map<String, String> schemeData = {
    'customerId': 'CUST-2024-001',
    'bookNo': 'BK-2024-123',
    'schemeNo': 'SCH-2024-456',
    'schemeType': 'Monthly',
    'schemeMetal': 'Gold',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account information refreshed',
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard',
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2A1454),
              const Color(0xFF140A33),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionOption(
              icon: Icons.picture_as_pdf,
              label: 'Download PDF',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement PDF download
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'PDF download feature coming soon',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Share feature coming soon',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              icon: Icons.print,
              label: 'Print',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement print
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Print feature coming soon',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSearch(String fieldLabel, String fieldValue) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return fieldLabel.toLowerCase().contains(query) ||
        fieldValue.toLowerCase().contains(query);
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
              // App Bar with back button and actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Account Information',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showQuickActions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search fields...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable content with pull-to-refresh
              Expanded(
                child: _isLoading && _searchQuery.isEmpty
                    ? _buildLoadingState()
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: AppColors.primary,
                        backgroundColor: const Color(0xFF2A1454),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Personal Information Section
                              _buildSectionCard(
                                title: 'Personal Information',
                                icon: Icons.person,
                                isExpanded: _isPersonalExpanded,
                                onToggle: () {
                                  setState(() {
                                    _isPersonalExpanded = !_isPersonalExpanded;
                                  });
                                },
                                children: [
                                  // Basic Info Group
                                  _buildFieldGroup(
                                    'Basic Information',
                                    [
                                      _buildInfoField(
                                        'Full Name',
                                        accountData['fullName']!,
                                        Icons.badge_outlined,
                                        copyable: false,
                                      ),
                                      _buildInfoField(
                                        'Date of Birth',
                                        accountData['dateOfBirth']!,
                                        Icons.calendar_today_outlined,
                                        copyable: false,
                                      ),
                                      _buildInfoField(
                                        'Gender',
                                        accountData['gender']!,
                                        Icons.person_outline,
                                        copyable: false,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Family Info Group
                                  _buildFieldGroup(
                                    'Family Information',
                                    [
                                      _buildInfoField(
                                        'Father\'s Name',
                                        accountData['fatherName']!,
                                        Icons.family_restroom,
                                        copyable: false,
                                      ),
                                      _buildInfoField(
                                        'Birth Place',
                                        accountData['birthPlace']!,
                                        Icons.place_outlined,
                                        copyable: false,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Contact Info Group
                                  _buildFieldGroup(
                                    'Contact Information',
                                    [
                                      _buildInfoField(
                                        'Cell No.',
                                        accountData['cellNo']!,
                                        Icons.phone_outlined,
                                        copyable: true,
                                        onCopy: () => _copyToClipboard(
                                          accountData['cellNo']!,
                                          'Phone number',
                                        ),
                                      ),
                                      _buildInfoField(
                                        'Email',
                                        accountData['email']!,
                                        Icons.email_outlined,
                                        copyable: true,
                                        onCopy: () => _copyToClipboard(
                                          accountData['email']!,
                                          'Email',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Address Group
                                  _buildFieldGroup(
                                    'Address',
                                    [
                                      _buildInfoField(
                                        'Business Address',
                                        accountData['businessAddress']!,
                                        Icons.business_outlined,
                                        copyable: true,
                                        onCopy: () => _copyToClipboard(
                                          accountData['businessAddress']!,
                                          'Business address',
                                        ),
                                      ),
                                      _buildInfoField(
                                        'Residential Address',
                                        accountData['residentialAddress']!,
                                        Icons.home_outlined,
                                        copyable: true,
                                        onCopy: () => _copyToClipboard(
                                          accountData['residentialAddress']!,
                                          'Residential address',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Identity Group
                                  _buildFieldGroup(
                                    'Identity',
                                    [
                                      _buildInfoField(
                                        'Aadhaar No.',
                                        accountData['aadhaarNo']!,
                                        Icons.credit_card_outlined,
                                        copyable: true,
                                        onCopy: () => _copyToClipboard(
                                          accountData['aadhaarNo']!,
                                          'Aadhaar number',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Nominee Section
                              _buildSectionCard(
                                title: 'Nominee Information',
                                icon: Icons.people_outline,
                                isExpanded: _isNomineeExpanded,
                                onToggle: () {
                                  setState(() {
                                    _isNomineeExpanded = !_isNomineeExpanded;
                                  });
                                },
                                children: [
                                  _buildInfoField(
                                    'Nominee Full Name',
                                    nomineeData['fullName']!,
                                    Icons.person_outline,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Nominee Gender',
                                    nomineeData['gender']!,
                                    Icons.person_outline,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Nominee Father Name',
                                    nomineeData['fatherName']!,
                                    Icons.family_restroom,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Nominee Age',
                                    nomineeData['age']!,
                                    Icons.cake_outlined,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Nominee Relationship',
                                    nomineeData['relationship']!,
                                    Icons.favorite_outline,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Nominee Birth Place',
                                    nomineeData['birthPlace']!,
                                    Icons.place_outlined,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Nominee Address',
                                    nomineeData['address']!,
                                    Icons.home_outlined,
                                    copyable: true,
                                    onCopy: () => _copyToClipboard(
                                      nomineeData['address']!,
                                      'Nominee address',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Scheme Details Section
                              _buildSectionCard(
                                title: 'Scheme Details',
                                icon: Icons.account_balance_wallet_outlined,
                                isExpanded: _isSchemeExpanded,
                                onToggle: () {
                                  setState(() {
                                    _isSchemeExpanded = !_isSchemeExpanded;
                                  });
                                },
                                children: [
                                  _buildInfoField(
                                    'Customer ID',
                                    schemeData['customerId']!,
                                    Icons.verified_user_outlined,
                                    copyable: true,
                                    isImportant: true,
                                    onCopy: () => _copyToClipboard(
                                      schemeData['customerId']!,
                                      'Customer ID',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Book No.',
                                    schemeData['bookNo']!,
                                    Icons.book_outlined,
                                    copyable: true,
                                    onCopy: () => _copyToClipboard(
                                      schemeData['bookNo']!,
                                      'Book number',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Scheme No.',
                                    schemeData['schemeNo']!,
                                    Icons.numbers_outlined,
                                    copyable: true,
                                    onCopy: () => _copyToClipboard(
                                      schemeData['schemeNo']!,
                                      'Scheme number',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Scheme Type',
                                    schemeData['schemeType']!,
                                    Icons.schedule_outlined,
                                    copyable: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Scheme Metal',
                                    schemeData['schemeMetal']!,
                                    schemeData['schemeMetal'] == 'Gold'
                                        ? Icons.monetization_on_outlined
                                        : Icons.currency_rupee_outlined,
                                    copyable: false,
                                    isImportant: true,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading account information...',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final filteredChildren = children.where((child) {
      // Simple filter - in a real app, you'd filter based on search query
      return true;
    }).toList();

    if (filteredChildren.isEmpty && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // Section Header
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              // Section Divider
              if (isExpanded)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              // Section Content
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: filteredChildren),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldGroup(String groupTitle, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            groupTitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...fields,
      ],
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    IconData icon, {
    bool copyable = false,
    bool isImportant = false,
    VoidCallback? onCopy,
  }) {
    // Filter based on search query
    if (!_matchesSearch(label, value)) {
      return const SizedBox.shrink();
    }

    final displayValue = value.isEmpty || value == 'null' ? '—' : value;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImportant
              ? AppColors.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          width: isImportant ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isImportant)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'IMPORTANT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayValue,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: displayValue == '—'
                        ? AppColors.textSecondary
                        : Colors.white.withOpacity(0.9),
                    fontFeatures: label.contains('ID') ||
                            label.contains('No.') ||
                            label.contains('Aadhaar')
                        ? [const FontFeature.tabularFigures()]
                        : [],
                  ),
                ),
              ],
            ),
          ),
          // Copy button
          if (copyable)
            GestureDetector(
              onTap: onCopy ?? () => _copyToClipboard(value, label),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.copy_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
