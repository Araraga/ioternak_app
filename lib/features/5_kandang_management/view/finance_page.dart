import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';

class FinancePage extends StatefulWidget {
  final int? barnId;
  final String? barnName;
  const FinancePage({super.key, this.barnId, this.barnName});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  Map<String, dynamic>? _summary;
  List<dynamic> _income = [];
  List<dynamic> _expense = [];
  bool _isLoading = true;
  String _tab = 'all'; // all, income, expense

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final barnParam = widget.barnId?.toString();
      final sRes = await http.get(Uri.parse(ApiEndpoints.getFinancialSummary(barnParam)));
      final iRes = await http.get(Uri.parse(ApiEndpoints.getIncome(barnParam)));
      final eRes = await http.get(Uri.parse(ApiEndpoints.getExpenses(barnParam)));

      if (sRes.statusCode == 200) _summary = jsonDecode(sRes.body)['data'];
      if (iRes.statusCode == 200) _income = jsonDecode(iRes.body)['data'] ?? [];
      if (eRes.statusCode == 200) _expense = jsonDecode(eRes.body)['data'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _fmt(num n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(n);
  String _fmtDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.barnName != null
        ? 'Keuangan - ${widget.barnName}'
        : 'Keuangan & Kas Keseluruhan';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    _buildTabs(),
                    const SizedBox(height: 14),
                    _buildTransactionList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final inc = num.tryParse(_summary?['total_income']?.toString() ?? '0') ?? 0;
    final exp = num.tryParse(_summary?['total_expense']?.toString() ?? '0') ?? 0;
    final profit = num.tryParse(_summary?['net_profit']?.toString() ?? '0') ?? (inc - exp);
    final isProfit = profit >= 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isProfit
                ? const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)])
                : const LinearGradient(colors: [Color(0xFFE74C3C), Color(0xFFC0392B)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: (isProfit ? const Color(0xFF2ECC71) : Colors.red).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Laba / Rugi Bersih', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                _fmt(profit),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    isProfit ? 'Surplus Finansial' : 'Defisit Operasional',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Pemasukan',
                amount: _fmt(inc),
                color: Colors.green,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Total Pengeluaran',
                amount: _fmt(exp),
                color: Colors.red,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddTransactionModal(isIncome: true),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text('Catat Pemasukan', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddTransactionModal(isIncome: false),
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            label: Text('Catat Pengeluaran', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChip('Semua (${_income.length + _expense.length})', 'all'),
          const SizedBox(width: 8),
          _tabChip('Pemasukan (${_income.length})', 'income'),
          const SizedBox(width: 8),
          _tabChip('Pengeluaran (${_expense.length})', 'expense'),
        ],
      ),
    );
  }

  Widget _tabChip(String label, String value) {
    final isSelected = _tab == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      onSelected: (val) {
        if (val) setState(() => _tab = value);
      },
    );
  }

  Widget _buildTransactionList() {
    List<Widget> items = [];

    if (_tab == 'all' || _tab == 'income') {
      for (var i in _income) {
        items.add(_trxCard(Map<String, dynamic>.from(i), true));
      }
    }

    if (_tab == 'all' || _tab == 'expense') {
      for (var e in _expense) {
        items.add(_trxCard(Map<String, dynamic>.from(e), false));
      }
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'Belum Ada Catatan Transaksi',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Gunakan tombol di atas untuk mencatat pemasukan atau pengeluaran.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(children: items);
  }

  Widget _trxCard(Map<String, dynamic> data, bool isIncome) {
    final c = isIncome ? Colors.green : Colors.red;
    final amt = num.tryParse(data['total_amount']?.toString() ?? data['amount']?.toString() ?? '0') ?? 0;
    final date = data['income_date'] ?? data['expense_date'] ?? data['date'];
    final type = data['income_type'] ?? data['expense_category'] ?? data['category'] ?? 'Lainnya';
    final notes = data['notes'] ?? data['description'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: c,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toString().toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes.toString(),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 2),
                Text(_fmtDate(date?.toString()), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          ),
          Text(
            (isIncome ? '+' : '-') + _fmt(amt),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: c),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal({required bool isIncome}) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final incomeCats = ['penjualan_ayam', 'penjualan_telur', 'pupuk_kotoran', 'lainnya'];
    final expenseCats = ['pakan', 'bibit_doc', 'vaksin_obat', 'listrik_air', 'tenaga_kerja', 'peralatan', 'lainnya'];

    String selectedCategory = isIncome ? incomeCats[0] : expenseCats[0];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isIncome ? 'Catat Pemasukan Baru' : 'Catat Pengeluaran Baru',
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal (Rp)',
                    hintText: 'Contoh: 1500000',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Kategori Transaksi', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: (isIncome ? incomeCats : expenseCats).map((cat) {
                    final isSel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat.replaceAll('_', ' ').toUpperCase()),
                      selected: isSel,
                      selectedColor: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.15),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? (isIncome ? Colors.green : Colors.red) : Colors.black87,
                      ),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Keterangan / Catatan',
                    hintText: 'Contoh: Pembelian pakan starter 10 sak',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amt = num.tryParse(amtCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0;
                            if (amt <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Nominal transaksi harus lebih dari 0!')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final nav = Navigator.of(ctx);
                            try {
                              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                              if (isIncome) {
                                await http.post(
                                  Uri.parse(ApiEndpoints.addIncome),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'barn_id': widget.barnId,
                                    'income_type': selectedCategory,
                                    'total_amount': amt,
                                    'notes': noteCtrl.text.trim(),
                                    'income_date': today,
                                  }),
                                );
                              } else {
                                await http.post(
                                  Uri.parse(ApiEndpoints.addExpense),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'barn_id': widget.barnId,
                                    'expense_category': selectedCategory,
                                    'total_amount': amt,
                                    'notes': noteCtrl.text.trim(),
                                    'expense_date': today,
                                  }),
                                );
                              }
                              nav.pop();
                              if (mounted) {
                                _loadData();
                              }
                            } catch (_) {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIncome ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isSaving ? 'Menyimpan...' : 'Simpan Transaksi',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
