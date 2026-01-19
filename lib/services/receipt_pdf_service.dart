// lib/services/receipt_pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ReceiptPdfService {
  /// Generates a PDF receipt for a transaction
  static Future<File> generateReceipt({
    required String transactionId,
    required String customerName,
    required String schemeName,
    required DateTime date,
    required double amount,
    required double gstAmount,
    required double netAmount,
    required String paymentMethod,
    required double gramsAdded,
    String? metalType,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 2,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SLG THANGANGAL',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Gold & Silver Savings Scheme',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Receipt Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Receipt No:', transactionId),
                        pw.SizedBox(height: 8),
                        _buildDetailRow(
                          'Date:',
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildDetailRow('Customer:', customerName),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Scheme:', schemeName),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Transaction Table
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                    ),
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          _buildTableCell('Description', isHeader: true),
                          _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                        ],
                      ),
                      // Payment Amount
                      pw.TableRow(
                        children: [
                          _buildTableCell('Payment Amount'),
                          _buildTableCell(
                            '₹${_formatCurrency(amount)}',
                            align: pw.TextAlign.right,
                          ),
                        ],
                      ),
                      // GST
                      pw.TableRow(
                        children: [
                          _buildTableCell('GST (3%)'),
                          _buildTableCell(
                            '₹${_formatCurrency(gstAmount)}',
                            align: pw.TextAlign.right,
                            color: PdfColors.orange,
                          ),
                        ],
                      ),
                      // Net Amount
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.amber50,
                        ),
                        children: [
                          _buildTableCell(
                            'Net Amount',
                            isBold: true,
                          ),
                          _buildTableCell(
                            '₹${_formatCurrency(netAmount)}',
                            align: pw.TextAlign.right,
                            isBold: true,
                            color: PdfColors.amber700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Gold/Silver Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.amber200),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${metalType ?? "Gold/Silver"} Added:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${gramsAdded.toStringAsFixed(3)} grams',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Payment Method
                _buildDetailRow('Payment Method:', paymentMethod),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Thank you for your investment!',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'For queries, contact: support@slgthangangal.com',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'This is a computer-generated receipt',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save PDF to device
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/receipt_$transactionId.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.grey800 : PdfColors.black),
        ),
        textAlign: align,
      ),
    );
  }

  static String _formatCurrency(double amount) {
    final numberStr = amount.toInt().toString();
    if (numberStr.length <= 3) {
      return numberStr;
    }
    String result = '';
    int count = 0;
    for (int i = numberStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = numberStr[i] + result;
      count++;
    }
    return result;
  }
}
