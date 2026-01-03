import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Terms & Conditions',
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
                  'Terms & Conditions',
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
                title: 'ELIGIBILITY',
                content: [
                  'Must be 18+ years old',
                  'Must provide valid Aadhaar and contact details',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '2',
                title: 'SERVICES',
                content: [
                  'SLG Thangangal provides gold investment schemes',
                  'Payment schedules: Daily/Weekly/Monthly as selected',
                  'Gold rates as per market on payment date',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '3',
                title: 'PAYMENTS',
                content: [
                  'Payments must be made on time as per scheme',
                  'Late payments may incur penalties',
                  'Field staff will collect payments',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '4',
                title: 'SCHEME RULES',
                content: [
                  'Schemes mature as per agreed duration',
                  'Early withdrawal may have penalties',
                  'Scheme cannot be transferred without approval',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '5',
                title: 'USER RESPONSIBILITIES',
                content: [
                  'Keep login details secure',
                  'Inform us of any changes in contact/address',
                  'Ensure timely payments',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '6',
                title: 'LIABILITY',
                content: [
                  'Gold rates subject to market fluctuations',
                  'Company not liable for payment gateway issues',
                  'Terms can be modified with notice',
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                number: '7',
                title: 'DISPUTES',
                content: [
                  'Governed by Indian law',
                  'Jurisdiction: Chennai, Tamil Nadu',
                ],
              ),

              const SizedBox(height: 32),

              // Contact Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact:',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'support@slggolds.com | +91 9028455583',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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




