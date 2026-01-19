import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/payment_service.dart';
import '../../widgets/success_animation_widget.dart';

class RecordPaymentModal extends StatefulWidget {
  final Map<String, dynamic> customer;
  final String staffId;
  final String userSchemeId;

  const RecordPaymentModal({
    super.key,
    required this.customer,
    required this.staffId,
    required this.userSchemeId,
  });

  @override
  State<RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends State<RecordPaymentModal> {
  final _amountController = TextEditingController();
  String _method = 'cash';
  bool _isLoading = false;
  double _currentRate = 0;

  @override
  void initState() {
    super.initState();
    _fetchRate();
  }

  Future<void> _fetchRate() async {
    final rate = await PaymentService.getCurrentMarketRate('gold'); // Logic simplification for modal
    if (mounted) setState(() => _currentRate = rate);
  }

  @override
  Widget build(BuildContext context) {
    final double amount = double.tryParse(_amountController.text) ?? 0;
    final double gst = amount * 0.03;
    final double net = amount - gst;
    final double grams = _currentRate > 0 ? net / _currentRate : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAmountField(),
          const SizedBox(height: 16),
          _buildBreakdown(gst, net, grams),
          const SizedBox(height: 24),
          _buildMethodToggle(),
          if (_method == 'upi') _buildUpiQR(),
          const SizedBox(height: 32),
          _buildRecordButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record Payment', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(widget.customer['name'] ?? 'Customer', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          ],
        ),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white38)),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
        hintText: '0',
        hintStyle: const TextStyle(color: Colors.white12),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildBreakdown(double gst, double net, double grams) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildRow('GST (3%)', '₹${gst.toStringAsFixed(2)}'),
          _buildRow('Net Investment', '₹${net.toStringAsFixed(2)}'),
          _buildRow('Metal Added', '${grams.toStringAsFixed(4)} Grams', color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          Text(val, style: GoogleFonts.inter(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMethodToggle() {
    return Row(
      children: ['cash', 'upi', 'bank'].map((m) {
        final selected = _method == m;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _method = m),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : Colors.white10),
              ),
              child: Center(child: Text(m.toUpperCase(), style: TextStyle(color: selected ? AppColors.primary : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpiQR() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Container(
              height: 150, width: 150,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.qr_code_2, size: 120, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text('Scan to Pay via UPI', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: _isLoading ? null : _submitPayment,
        child: _isLoading ? const CircularProgressIndicator() : Text('RECORD PAYMENT', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.rpc('record_payment_v2', params: {
        'staff_id_param': widget.staffId,
        'customer_id_param': widget.customer['id'],
        'user_scheme_id_param': widget.userSchemeId,
        'amount_param': amount,
        'method_param': _method,
        'device_id_param': 'MOBILE-APP',
      });
      
      if (mounted) {
        // Close modal first
        Navigator.pop(context, true);
        
        // Show success animation
        await SuccessAnimationWidget.show(
          context,
          message: 'Payment Recorded Successfully!',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Sanitized logging - no sensitive data
      debugPrint('Payment submission failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
