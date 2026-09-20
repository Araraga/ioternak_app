import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/batch_model.dart';
import 'add_batch_page.dart';
import 'batch_detail_page.dart';

class FlockManagementPage extends StatefulWidget {
  final int barnId;
  const FlockManagementPage({super.key, required this.barnId});

  @override
  State<FlockManagementPage> createState() => _FlockManagementPageState();
}

class _FlockManagementPageState extends State<FlockManagementPage> {
  List<BatchModel> _batches = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getBatches(widget.barnId.toString())));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        setState(() => _batches = list.map((e) => BatchModel.fromJson(e)).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<BatchModel> get _filteredBatches {
    if (_filter == 'active') {
      return _batches.where((b) => b.status == 'active').toList();
    } else if (_filter == 'completed') {
      return _batches.where((b) => b.status != 'active').toList();
    }
    return _batches;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manajemen Flock & Batch', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildFilterTabs(),
                Expanded(
                  child: _filteredBatches.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadBatches,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredBatches.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _buildBatchCard(_filteredBatches[i]),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddBatchPage(barnId: widget.barnId)),
        ).then((v) {
          if (v == true) _loadBatches();
        }),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Batch Baru', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _filterChip('Semua (${_batches.length})', 'all'),
          const SizedBox(width: 8),
          _filterChip('Aktif (${_batches.where((b) => b.status == 'active').length})', 'active'),
          const SizedBox(width: 8),
          _filterChip('Selesai (${_batches.where((b) => b.status != 'active').length})', 'completed'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
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
        if (val) setState(() => _filter = value);
      },
    );
  }

  Widget _buildBatchCard(BatchModel b) {
    final isDone = b.status != 'active';
    final targetDays = b.birdType == 'layer' ? 500 : 35;
    final progress = (b.ageDays / targetDays).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailPage(batch: b)),
      ).then((_) => _loadBatches()),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    b.birdType == 'layer' ? '🥚 LAYER' : '🍗 BROILER',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                if (b.breed != null && b.breed!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      b.breed!,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.grey.shade200 : AppColors.statusGood.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDone ? 'Selesai' : 'Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDone ? Colors.grey.shade700 : AppColors.statusGood,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              b.batchName,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              'Batch #${b.id}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricPill(
                    Icons.pets_rounded,
                    'Populasi',
                    '${NumberFormat('#,###', 'id_ID').format(b.currentCount)} ekor',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricPill(
                    Icons.calendar_today_rounded,
                    'Usia DOC',
                    '${b.ageDays} hari',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricPill(
                    Icons.health_and_safety_rounded,
                    'Mortalitas',
                    '${b.mortalityRate.toStringAsFixed(1)}%',
                    color: b.mortalityRate <= 5.0 ? AppColors.statusGood : AppColors.statusDanger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Siklus Pertumbuhan (${(progress * 100).toInt()}%)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                Text('Target: $targetDays hari', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(IconData icon, String label, String value, {Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: c)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_outlined, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Belum Ada Flock/Batch', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Mulai siklus baru dengan menambahkan batch ternak.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

}
