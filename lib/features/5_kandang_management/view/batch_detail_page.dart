import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/batch_model.dart';
import '../models/production_model.dart';
import 'production_log_page.dart';
import 'health_check_page.dart';
import 'vaccination_page.dart';

class BatchDetailPage extends StatefulWidget {
  final BatchModel batch;
  const BatchDetailPage({super.key, required this.batch});
  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductionLog> _productionLogs = [];
  List<HealthCheck> _healthChecks = [];
  List<VaccinationScheduleItem> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadProductionLogs(), _loadHealthChecks(), _loadVaccinations()]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProductionLogs() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getProductionLogs(widget.batch.id.toString())));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List? ?? [];
        _productionLogs = list.map((e) => ProductionLog.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadHealthChecks() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getHealthChecks(widget.batch.id.toString())));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List? ?? [];
        _healthChecks = list.map((e) => HealthCheck.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadVaccinations() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getVaccinationSchedule(widget.batch.id.toString())));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List? ?? [];
        _vaccinations = list.map((e) => VaccinationScheduleItem.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  String _fmtNum(num n) => NumberFormat('#,###', 'id_ID').format(n);
  String _fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildSliverAppBar()],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [_buildOverviewTab(), _buildProductionTab(), _buildHealthTab()],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActionSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Log Cepat', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final batch = widget.batch;
    return SliverAppBar(
      expandedHeight: 200, pinned: true, elevation: 0, backgroundColor: AppColors.primary,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _loadData)],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF1ABC9C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    _headerBadge(batch.birdType == 'layer' ? '🥚 Layer' : '🍗 Broiler'),
                    const SizedBox(width: 8),
                    _headerBadge(' Hari'),
                  ]),
                  const SizedBox(height: 8),
                  Text(batch.batchName, style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (batch.breed != null) Text(batch.breed!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController, indicatorColor: Colors.white, indicatorWeight: 3, labelColor: Colors.white,
        unselectedLabelColor: Colors.white60, labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [Tab(text: 'Ringkasan'), Tab(text: 'Produksi'), Tab(text: 'Kesehatan')],
      ),
    );
  }

  Widget _headerBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _buildOverviewTab() {
    final batch = widget.batch;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPopulationCard(batch), const SizedBox(height: 12),
          _buildBatchInfoCard(batch), const SizedBox(height: 12),
          _buildVaccinationStatusCard(), const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPopulationCard(BatchModel batch) {
    final mortalityColor = batch.mortalityRate < 5 ? AppColors.statusGood : batch.mortalityRate < 10 ? AppColors.statusWarning : AppColors.statusDanger;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A2332), Color(0xFF2D3A50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A2332).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Populasi Ternak', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statItem(label: 'Awal DOC', value: _fmtNum(batch.initialCount), unit: 'ekor', color: Colors.white)),
              Container(width: 1, height: 50, color: Colors.white12),
              Expanded(child: _statItem(label: 'Saat Ini', value: _fmtNum(batch.currentCount), unit: 'ekor', color: Colors.white)),
              Container(width: 1, height: 50, color: Colors.white12),
              Expanded(child: _statItem(label: 'Mortalitas', value: '%', unit: ' ekor', color: mortalityColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: batch.currentCount / batch.initialCount,
              backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(mortalityColor), minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text('% populasi masih hidup',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statItem({required String label, required String value, required String unit, required Color color}) {
    return Column(children: [
      Text(value, style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2), Text(unit, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 2), Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
    ]);
  }

  Widget _buildBatchInfoCard(BatchModel batch) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Info Batch', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _infoRow('Tanggal Mulai', _fmtDate(batch.startDate)),
          if (batch.targetHarvestDate != null) _infoRow('Target Panen', _fmtDate(batch.targetHarvestDate!)),
          if (batch.supplier != null) _infoRow('Supplier', batch.supplier!),
          _infoRow('Jenis Ternak', batch.birdTypeLabel),
          _infoRow('Status', batch.statusLabel),
          if (batch.notes != null && batch.notes!.isNotEmpty) _infoRow('Catatan', batch.notes!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildVaccinationStatusCard() {
    if (_vaccinations.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(child: Column(children: [
          const Icon(Icons.vaccines_outlined, color: AppColors.textLight, size: 32),
          const SizedBox(height: 8), Text('Belum ada jadwal vaksinasi', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        ])),
      );
    }
    final overdue = _vaccinations.where((v) => v.status == 'overdue').toList();
    final pending = _vaccinations.where((v) => v.status == 'pending').take(3).toList();
    final completed = _vaccinations.where((v) => v.status == 'completed').length;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jadwal Vaksinasi', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('$completed selesai • ${_vaccinations.length} total', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VaccinationPage(batch: widget.batch))).then((_) => _loadData()),
              child: Text('Lihat Semua', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
            ),
          ]),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.statusDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.statusDanger.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.warning_rounded, color: AppColors.statusDanger, size: 16), const SizedBox(width: 6),
                    Text(' Vaksinasi Terlambat', style: GoogleFonts.inter(color: AppColors.statusDanger, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                  ...overdue.map((v) => Padding(padding: const EdgeInsets.only(top: 4), child: Text('*  (Hari ke-)', style: GoogleFonts.inter(color: AppColors.statusDanger, fontSize: 12)))),
                ],
              ),
            ),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...pending.map((v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                const Icon(Icons.schedule_rounded, color: AppColors.statusWarning, size: 16), const SizedBox(width: 8),
                Expanded(child: Text(v.name, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary))),
                Text(_fmtDate(v.dueDate), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            )),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusGood, size: 14), const SizedBox(width: 6),
            Text(' vaksinasi selesai', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildProductionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Log Produksi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductionLogPage(batch: widget.batch))).then((_) => _loadData()),
              icon: const Icon(Icons.add_rounded, size: 16), label: Text('Tambah', style: GoogleFonts.inter(fontSize: 13)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), elevation: 0),
            ),
          ]),
          const SizedBox(height: 12),
          if (_productionLogs.isEmpty)
            _buildEmptyState('Belum ada log produksi', 'Mulai catat produksi harian', Icons.analytics_outlined)
          else
            ..._productionLogs.map((log) => _buildProductionLogCard(log)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 14), Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildProductionLogCard(ProductionLog log) {
    final isLayer = widget.batch.birdType == 'layer';
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _dateBadge(log.logDate), const Spacer(),
            if (log.fcr != null) _smallBadge('FCR: ', AppColors.statusInfo),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              if (isLayer && log.eggsCollected != null) _chip(Icons.egg_outlined, ' telur', AppColors.statusWarning),
              if (!isLayer && log.averageWeight != null) _chip(Icons.monitor_weight_outlined, 'g/ekor', AppColors.statusInfo),
              if (log.feedConsumedKg != null) _chip(Icons.grass_outlined, 'kg pakan', AppColors.statusGood),
              if (log.waterConsumedLiters != null) _chip(Icons.water_drop_outlined, 'L air', const Color(0xFF42A5F5)),
            ],
          ),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 8), Text(log.notes!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _dateBadge(DateTime d) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(DateFormat('d MMM', 'id_ID').format(d), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
  );

  Widget _smallBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color), const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildHealthTab() {
    final latestHealth = _healthChecks.isNotEmpty ? _healthChecks.first : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthStatusCard(latestHealth), const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _actionButton(Icons.health_and_safety_outlined, 'Health Check', AppColors.statusGood, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HealthCheckPage(batch: widget.batch))).then((_) => _loadData()))),
            const SizedBox(width: 10),
            Expanded(child: _actionButton(Icons.vaccines_outlined, 'Vaksinasi', AppColors.statusInfo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => VaccinationPage(batch: widget.batch))).then((_) => _loadData()))),
          ]),
          const SizedBox(height: 12),
          if (_healthChecks.isNotEmpty) ...[
            Text('Riwayat Health Check', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10), ..._healthChecks.map((hc) => _buildHealthCheckCard(hc)),
          ] else
            _buildEmptyState('Belum ada riwayat health check', 'Lakukan pemeriksaan rutin setiap hari', Icons.medical_services_outlined),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(HealthCheck? latest) {
    Color color; String text; IconData icon;
    if (latest == null) { color = AppColors.textLight; text = 'Belum ada data'; icon = Icons.help_outline_rounded; }
    else if (latest.overallStatus == 'good') { color = AppColors.statusGood; text = 'Sehat'; icon = Icons.check_circle_rounded; }
    else if (latest.overallStatus == 'warning') { color = AppColors.statusWarning; text = 'Perlu Perhatian'; icon = Icons.warning_rounded; }
    else { color = AppColors.statusDanger; text = 'Kritis'; icon = Icons.dangerous_rounded; }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status Kesehatan', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          Text(text, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          if (latest != null) ...[
            Text('Cek terakhir: ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            if (latest.sickBirdsCount > 0) Text(' ekor sakit', style: GoogleFonts.inter(fontSize: 12, color: AppColors.statusDanger, fontWeight: FontWeight.w600)),
          ],
        ])),
      ]),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 6), Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildHealthCheckCard(HealthCheck hc) {
    Color c; String label;
    if (hc.overallStatus == 'good') { c = AppColors.statusGood; label = 'Sehat'; }
    else if (hc.overallStatus == 'warning') { c = AppColors.statusWarning; label = 'Waspada'; }
    else { c = AppColors.statusDanger; label = 'Kritis'; }
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Row(children: [
        Container(width: 4, height: 50, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_fmtDate(hc.checkDate), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const Spacer(), _smallBadge(label, c),
          ]),
          if (hc.sickBirdsCount > 0) Text(' ekor sakit', style: GoogleFonts.inter(fontSize: 12, color: AppColors.statusDanger)),
          if (hc.symptoms != null && hc.symptoms!.isNotEmpty) Text('Gejala: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16), Text('Log Cepat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          _quickTile(Icons.analytics_outlined, 'Log Produksi', 'Catat telur/berat & pakan hari ini', AppColors.statusWarning, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ProductionLogPage(batch: widget.batch))).then((_) => _loadData()); }),
          _quickTile(Icons.health_and_safety_outlined, 'Health Check', 'Periksa kondisi ternak hari ini', AppColors.statusGood, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => HealthCheckPage(batch: widget.batch))).then((_) => _loadData()); }),
          _quickTile(Icons.vaccines_outlined, 'Catat Vaksinasi', 'Rekam vaksinasi yang dilakukan', AppColors.statusInfo, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => VaccinationPage(batch: widget.batch))).then((_) => _loadData()); }),
        ]),
      ),
    );
  }

  Widget _quickTile(IconData icon, String label, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
      onTap: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
