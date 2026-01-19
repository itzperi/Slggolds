// lib/screens/customer/transaction_detail_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/constants.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String date;
  final double amount;
  final String status;
  final String? transactionId;
  final String? method;
  final String? scheme;

  const TransactionDetailScreen({
    super.key,
    required this.date,
    required this.amount,
    required this.status,
    this.transactionId,
    this.method,
    this.scheme,
  });

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

  Future<File> _generateReceiptPdf() async {
    final pdf = pw.Document();

    final gstAmount = amount.toDouble() * 0.03;
    final netAmount = amount.toDouble() * 0.97;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SLG Thangangal',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Payment Receipt',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Amount Paid',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '₹${_formatCurrency(amount.toDouble())}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('GST (3%): ₹${_formatCurrency(gstAmount)}'),
                pw.Text('Net Investment: ₹${_formatCurrency(netAmount)}'),
                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('Date: $date'),
                pw.Text('Status: $status'),
                if (method != null) pw.Text('Payment Method: $method'),
                if (scheme != null) pw.Text('Scheme: $scheme'),
                if (transactionId != null)
                  pw.Text('Transaction ID: $transactionId'),
                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text(
                  'This is a system-generated receipt. Please keep it for your records.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/receipt_${transactionId ?? DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _downloadReceipt() async {
    final file = await _generateReceiptPdf();
    // On mobile, "downloading" is effectively sharing/saving via system sheet.
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'SLG Thangangal payment receipt',
    );
  }

  Future<void> _shareReceipt() async {
    final file = await _generateReceiptPdf();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'SLG Thangangal payment receipt',
    );
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transaction Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Status
                        Center(
                          child: Text(
                            'Payment Successful',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Amount
                        Center(
                          child: Text(
                            '₹${_formatCurrency(amount.toDouble())}',
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // GST Breakdown
                        _buildDetailRow('Amount Paid', '₹${_formatCurrency(amount.toDouble())}'),
                        const SizedBox(height: 16),
                        _buildDetailRow('GST (3%)', '₹${_formatCurrency(amount.toDouble() * 0.03)}', color: Colors.orange),
                        const SizedBox(height: 16),
                        _buildDetailRow('Net Investment', '₹${_formatCurrency(amount.toDouble() * 0.97)}', color: AppColors.primary),

                        const SizedBox(height: 40),

                        // Details
                        _buildDetailRow('Date', date),
                        const SizedBox(height: 16),
                        _buildDetailRow('Status', status),
                        if (method != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('Payment Method', method!),
                        ],
                        if (scheme != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('Scheme', scheme!),
                        ],
                        if (transactionId != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('Transaction ID', transactionId!),
                        ],

                        const SizedBox(height: 40),

                        // Divider
                        Divider(
                          color: Colors.white.withOpacity(0.1),
                          thickness: 1,
                        ),

                        const SizedBox(height: 24),

                        // Download/Share buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await _downloadReceipt();
                                },
                                icon: const Icon(Icons.download, color: AppColors.primary),
                                label: Text(
                                  'Download',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _shareReceipt();
                                },
                                icon: const Icon(Icons.share, color: Colors.white),
                                label: Text(
                                  'Share',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.9), // More subtle
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2, // Subtle elevation
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
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
              color: color ?? Colors.white,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

