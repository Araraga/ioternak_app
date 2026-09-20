import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/batch_model.dart';
import '../models/production_model.dart';

class VaccinationPage extends StatefulWidget {
  final BatchModel batch;
  const VaccinationPage({super.key, required this.batch});
  @override
  State<VaccinationPage> createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage> {
  List<VaccinationScheduleItem> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getVaccinationSchedule(widget.batch.id.toString())));
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body)['data'] as List? ?? []);
        setState(() => _schedule = list.map((e) => VaccinationScheduleItem.fromJson(e)).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
  Color _statusColor(String s) => s == 'completed' ? AppColors.statusGood : s == 'overdue' ? AppColors.statusDanger : AppColors.statusWarning;
  IconData _statusIcon(String s) => s == 'completed' ? Icons.check_circle_rounded : s == 'overdue' ? Icons.warning_rounded : Icons.schedule_rounded;
  String _statusLabel(String s) => s == 'completed' ? 'Selesai' : s == 'overdue' ? 'Terlambat' : 'Terjadwal';

  Future<void> _recordVaccination(VaccinationScheduleItem item) async {
    final nc = TextEditingController(text: item.name);
    final bc = TextEditingController();
    DateTime ad = DateTime.now();
    await showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, sm) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Catat Vaksinasi', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _mf(ctrl: nc, label: 'Nama Vaksin', icon: Icons.vaccines_outlined),
            const SizedBox(height: 12),
            _mf(ctrl: bc, label: 'No. Batch Vaksin (opsional)', icon: Icons.numbers_outlined),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final p = await showDatePicker(context: ctx, initialDate: ad, firstDate: widget.batch.startDate, lastDate: DateTime.now());
                if (p != null) sm(() => ad = p);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.statusInfo.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.event_rounded, color: AppColors.statusInfo, size: 20),
                  const SizedBox(width: 10),
                  Text('Tgl: ${DateFormat("d MMM yyyy", "id_ID").format(ad)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                try {
                  await http.post(Uri.parse(ApiEndpoints.addVaccinationRecord),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'batch_id': widget.batch.id,
                        'vaccination_name': nc.text,
                        'administration_date': ad.toIso8601String().split('T')[0],
                        'bird_age_days': widget.batch.ageDays,
                        'birds_vaccinated': widget.batch.currentCount,
                        if (bc.text.isNotEmpty) 'batch_number': bc.text,
                      }));
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusInfo, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
              child: Text('Simpan Vaksinasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      )),
    );
  }

  Widget _mf({required TextEditingController ctrl, required String label, required IconData icon}) =>
    TextField(controller: ctrl, style: GoogleFonts.inter(), decoration: InputDecoration(
      labelText: label, labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.statusInfo, size: 20), filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.statusInfo, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Jadwal Vaksinasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.statusInfo, foregroundColor: Colors.white, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.statusInfo))
          : _schedule.isEmpty ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedule.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _vaccCard(_schedule[i]),
                ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.vaccines_outlined, size: 60, color: AppColors.textLight), const SizedBox(height: 16),
    Text('Belum ada jadwal vaksinasi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text('Jadwal akan muncul otomatis setelah batch dibuat', style: GoogleFonts.inter(color: AppColors.textSecondary)),
  ]));

  Widget _vaccCard(VaccinationScheduleItem item) {
    final c = _statusColor(item.status);
    final isDone = item.status == 'completed';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(isDone ? 0.2 : 0.4), width: isDone ? 1 : 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(_statusIcon(item.status), color: c, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text('Hari ke-${item.ageDay}  -  ${_fmtDate(item.dueDate)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          if (item.completedDate != null)
            Text('Dilakukan: ${_fmtDate(item.completedDate!)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.statusGood)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(_statusLabel(item.status), style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.bold))),
          if (!isDone) ...[const SizedBox(height: 8),
            GestureDetector(onTap: () => _recordVaccination(item),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.statusInfo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Catat', style: GoogleFonts.inter(fontSize: 11, color: AppColors.statusInfo, fontWeight: FontWeight.bold)))),
          ],
        ]),
      ]),
    );
  }
}