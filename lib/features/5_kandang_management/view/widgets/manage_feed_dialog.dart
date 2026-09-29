import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../cubit/barn_cubit.dart';
import '../../cubit/barn_state.dart';

class ManageFeedDialog extends StatefulWidget {
  final String? barnId;
  final String? barnName;

  const ManageFeedDialog({
    super.key,
    this.barnId,
    this.barnName,
  });

  static Future<void> show(BuildContext context, {String? barnId, String? barnName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageFeedDialog(
        barnId: barnId,
        barnName: barnName,
      ),
    );
  }

  @override
  State<ManageFeedDialog> createState() => _ManageFeedDialogState();
}

class _ManageFeedDialogState extends State<ManageFeedDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _activeBarnId;
  String _activeBarnName = 'Kandang';

  final _addKgCtrl = TextEditingController();
  final _addCostCtrl = TextEditingController();
  bool _recordToFinance = true;

  final _transferKgCtrl = TextEditingController();

  final _manualGudangCtrl = TextEditingController();
  final _manualAlatCtrl = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _activeBarnId = widget.barnId ?? '1';
    _activeBarnName = widget.barnName ?? 'Kandang';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initValues();
    });
  }

  void _initValues() {
    final storage = context.read<StorageService>();
    final cubit = context.read<BarnCubit>();

    // If barnId wasn't passed, find the first available barn from cubit
    final state = cubit.state;
    if (state is BarnLoaded && state.barns.isNotEmpty && widget.barnId == null) {
      final firstBarn = state.barns.first;
      _activeBarnId = firstBarn['id']?.toString() ?? '1';
      _activeBarnName = firstBarn['barn_name']?.toString() ?? 'Kandang';
    }

    final gudang = storage.getFeedStockGudang(_activeBarnId);
    final alat = storage.getFeedStockAlat(_activeBarnId);

    _manualGudangCtrl.text = gudang > 0 ? gudang.toStringAsFixed(1) : '0';
    _manualAlatCtrl.text = alat > 0 ? alat.toStringAsFixed(1) : '0';
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addKgCtrl.dispose();
    _addCostCtrl.dispose();
    _transferKgCtrl.dispose();
    _manualGudangCtrl.dispose();
    _manualAlatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final gudang = storage.getFeedStockGudang(_activeBarnId);
    final alat = storage.getFeedStockAlat(_activeBarnId);
    final total = gudang + alat;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Stok Pakan',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _activeBarnName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Current Stock Overview Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _stockBadge(
                      label: 'Gudang',
                      value: '${gudang.toStringAsFixed(1)} kg',
                      icon: Icons.warehouse_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade300),
                  Expanded(
                    child: _stockBadge(
                      label: 'Alat IoPakan',
                      value: '${alat.toStringAsFixed(1)} kg',
                      icon: Icons.precision_manufacturing_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade300),
                  Expanded(
                    child: _stockBadge(
                      label: 'Total Stok',
                      value: '${total.toStringAsFixed(1)} kg',
                      icon: Icons.all_inclusive_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: '+ Beli / Tambah'),
              Tab(text: 'Tuang ke Alat'),
              Tab(text: 'Atur Manual'),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 260,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddStockTab(gudang),
                    _buildTransferTab(gudang, alat),
                    _buildManualTab(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // TAB 1: TAMBAH STOK GUDANG (BELI PAKAN)
  Widget _buildAddStockTab(double currentGudang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _addKgCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Jumlah Pakan Baru (kg)',
            hintText: 'Contoh: 50 (1 sak = 50 kg)',
            suffixText: 'kg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addCostCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Total Biaya Pembelian (Rp)',
            hintText: 'Contoh: 450000 (opsional)',
            prefixText: 'Rp ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          value: _recordToFinance,
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: Text(
            'Catat otomatis ke Pembukuan Kas (Pengeluaran)',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
          ),
          onChanged: (val) => setState(() => _recordToFinance = val ?? true),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _submitAddStock(currentGudang),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _isProcessing ? 'Menyimpan...' : 'Simpan & Tambah Stok',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAddStock(double currentGudang) async {
    final addKg = double.tryParse(_addKgCtrl.text.replaceAll(',', '.').trim()) ?? 0;
    if (addKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah kg pakan yang valid!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final cubit = context.read<BarnCubit>();

    await cubit.addFeedStockGudang(_activeBarnId, addKg);

    // Record to finance if checked
    final cost = num.tryParse(_addCostCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0;
    if (_recordToFinance && cost > 0) {
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await http.post(
          Uri.parse(ApiEndpoints.addExpense),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'barn_id': int.tryParse(_activeBarnId),
            'expense_category': 'feed',
            'item_name': 'Pembelian Pakan ($addKg kg)',
            'quantity': addKg,
            'unit_price': (cost / addKg).round(),
            'total_amount': cost,
            'expense_date': today,
            'notes': 'Dicatat via Kelola Stok Pakan',
          }),
        );
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambahkan ${addKg.toStringAsFixed(1)} kg pakan ke gudang!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      cubit.fetchBarns();
    }
  }

  // TAB 2: TUANG KE ALAT
  Widget _buildTransferTab(double currentGudang, double currentAlat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tuang pakan dari gudang ke wadah/dispenser IoPakan',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _transferKgCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Jumlah Pakan Dituang (kg)',
            hintText: 'Contoh: 5 atau 10',
            suffixText: 'kg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tersedia di Gudang: ${currentGudang.toStringAsFixed(1)} kg',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _submitTransfer(currentGudang),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _isProcessing ? 'Memproses...' : 'Tuang ke Alat IoPakan',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitTransfer(double currentGudang) async {
    final transferKg = double.tryParse(_transferKgCtrl.text.replaceAll(',', '.').trim()) ?? 0;
    if (transferKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah pakan yang akan dituang!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (transferKg > currentGudang) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok gudang tidak mencukupi (${currentGudang.toStringAsFixed(1)} kg)!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final cubit = context.read<BarnCubit>();
    final ok = await cubit.transferFeedStockToAlat(_activeBarnId, transferKg);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${transferKg.toStringAsFixed(1)} kg pakan berhasil dituang ke alat!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        cubit.fetchBarns();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal melakukan transfer pakan'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // TAB 3: ATUR MANUAL
  Widget _buildManualTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _manualGudangCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Stok Gudang (kg)',
            suffixText: 'kg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualAlatCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Stok di Alat (kg)',
            suffixText: 'kg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _submitManual,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _isProcessing ? 'Menyimpan...' : 'Simpan Nilai Stok',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitManual() async {
    final gudang = double.tryParse(_manualGudangCtrl.text.replaceAll(',', '.').trim()) ?? 0;
    final alat = double.tryParse(_manualAlatCtrl.text.replaceAll(',', '.').trim()) ?? 0;

    setState(() => _isProcessing = true);
    final storage = context.read<StorageService>();
    final cubit = context.read<BarnCubit>();

    await storage.saveFeedStockGudang(_activeBarnId, gudang);
    await storage.saveFeedStockAlat(_activeBarnId, alat);

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok pakan berhasil disesuaikan!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      cubit.fetchBarns();
    }
  }
}
