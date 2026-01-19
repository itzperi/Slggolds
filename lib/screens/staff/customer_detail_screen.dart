import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import 'record_payment_modal.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  final String staffId;
  const CustomerDetailScreen({super.key, required this.customer, required this.staffId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final response = await Supabase.instance.client
        .from('payments')
        .select('*')
        .eq('customer_id', widget.customer['id'])
        .order('payment_date', ascending: false)
        .limit(10);
    if (mounted) setState(() { _history = response; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildKYCSection(),
                  const SizedBox(height: 24),
                  _buildPaymentSummary(),
                  const SizedBox(height: 24),
                  _buildHistoryHeader(),
                  _isLoading ? const Center(child: CircularProgressIndicator()) : _buildHistoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showPaymentModal(),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
        label: Text('RECORD PAYMENT', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.backgroundDarker,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.5), Colors.black26]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 40, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 40, color: Colors.white38)),
              const SizedBox(height: 12),
              Text(widget.customer['name'] ?? 'Unknown', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(widget.customer['phone'] ?? '', style: GoogleFonts.inter(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionBtn(Icons.call, 'Call', Colors.blue),
        _actionBtn(Icons.chat, 'WhatsApp', Colors.green),
        _actionBtn(Icons.map, 'Location', Colors.red),
        _actionBtn(Icons.note_add, 'Note', Colors.amber),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _buildKYCSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.backgroundLighter, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KYC INFO', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const Icon(Icons.verified, color: AppColors.success, size: 18),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          _kycItem('Address', '123, Anna Salai, Nagercoil'),
          _kycItem('PAN Card', 'ABCDE****F'),
        ],
      ),
    );
  }

  Widget _kycItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPaymentSummary() {
    return Row(
      children: [
        Expanded(child: _summaryCard('NEXT DUE', '₹${widget.customer['next_due_amount']}', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('PENDING', '₹${widget.customer['total_pending_amount']}', AppColors.danger)),
      ],
    );
  }

  Widget _summaryCard(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.backgroundLighter, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
        Text(val, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text('PAYMENT HISTORY', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) return const Center(child: Text('No payments found', style: TextStyle(color: Colors.white24)));
    return Column(
      children: _history.map((p) => _historyItem(p)).toList(),
    );
  }

  Widget _historyItem(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Receipt: ${p['receipt_number']}', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
            Text(p['payment_date'], style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${p['amount']}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
            Text('${p['metal_grams_added']}g', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ]),
        ],
      ),
    );
  }

  void _showPaymentModal() async {
    // We need user_scheme_id. In a real app we'd fetch this from the customer object or a quick query.
    // Fetching user_scheme_id for this customer
    final res = await Supabase.instance.client.from('user_schemes').select('id').eq('customer_id', widget.customer['id']).eq('status', 'active').maybeSingle();
    
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active scheme found')));
      return;
    }

    if (!mounted) return;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentModal(
        customer: widget.customer,
        staffId: widget.staffId,
        userSchemeId: res['id'],
      ),
    );

    if (result == true) {
      _loadHistory();
    }
  }
}
