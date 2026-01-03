import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundDarker,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Content
              _buildSection(
                number: '1',
                title: 'INFORMATION WE COLLECT',
                content: [
                  'Personal details (name, phone, email, address, Aadhaar)',
                  'Nominee information',
                  'Payment records',
                  'Device information for security',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '2',
                title: 'HOW WE USE IT',
                content: [
                  'Account management',
                  'Processing payments',
                  'Sending payment reminders',
                  'KYC compliance',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '3',
                title: 'DATA SHARING',
                content: [
                  'Payment gateways (secured)',
                  'Regulatory authorities (if required by law)',
                  'We DO NOT sell your data',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '4',
                title: 'DATA SECURITY',
                content: [
                  'Encrypted storage',
                  'Secure servers',
                  'Limited staff access',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '5',
                title: 'YOUR RIGHTS',
                content: [
                  'Access your data anytime',
                  'Request corrections',
                  'Request deletion (after settling schemes)',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '6',
                title: 'CONTACT',
                content: [
                  'For privacy concerns: privacy@slggolds.com',
                ],
              ),

              const SizedBox(height: 32),

              // Last Updated
              Text(
                'Last Updated: December 2024',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required List<String> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number + '. ',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...content.map((item) => Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}




