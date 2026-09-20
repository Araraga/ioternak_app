import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/batch_model.dart';

class HealthCheckPage extends StatefulWidget {
  final BatchModel batch;
  const HealthCheckPage({super.key, required this.batch});
  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  String _status = 'good';
  final _sickCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _behaviorCtrl = TextEditingController();
  final _actionsCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _sickCtrl.dispose(); _symptomsCtrl.dispose();
    _behaviorCtrl.dispose(); _actionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'batch_id': widget.batch.id,
        'barn_id': widget.batch.barnId,
        'overall_status': _status,
        'sick_birds_count': int.tryParse(_sickCtrl.text) ?? 0,
      };
      if (_symptomsCtrl.text.isNotEmpty) body['symptoms'] = _symptomsCtrl.text;
      if (_behaviorCtrl.text.isNotEmpty) body['behavioral_notes'] = _behaviorCtrl.text;
      if (_actionsCtrl.text.isNotEmpty) body['actions_taken'] = _actionsCtrl.text;
      final res = await http.post(Uri.parse(ApiEndpoints.addHealthCheck),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Health check berhasil dicatat!'), backgroundColor: AppColors.statusGood));
        Navigator.pop(context, true);
      } else {
        _err('Gagal menyimpan. Coba lagi.');
      }
    } catch (e) { _err('Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  void _err(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.statusDanger));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Health Check Harian', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.statusGood, foregroundColor: Colors.white, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildBanner(), const SizedBox(height: 20),
          _buildStatusCard(), const SizedBox(height: 16),
          _buildDetailCard(), const SizedBox(height: 28),
          _buildSaveButton(), const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.statusGood.withOpacity(0.1), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.statusGood.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.health_and_safety_outlined, color: AppColors.statusGood, size: 28),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.batch.batchName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
        Text('${widget.batch.currentCount} ekor - Hari ke-${widget.batch.ageDays}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    ]),
  );

  Widget _buildStatusCard() {
    final items = [
      {'key': 'good', 'label': 'Sehat', 'icon': Icons.check_circle_rounded, 'color': AppColors.statusGood},
      {'key': 'warning', 'label': 'Perlu Perhatian', 'icon': Icons.warning_rounded, 'color': AppColors.statusWarning},
      {'key': 'critical', 'label': 'Kritis', 'icon': Icons.dangerous_rounded, 'color': AppColors.statusDanger},
    ];
    return _sectionCard('Status Kesehatan Hari Ini', Icons.monitor_heart_outlined,
      Column(children: items.map((item) {
        final sel = _status == (item['key'] as String);
        final c = item['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _status = item['key'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? c.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? c : Colors.grey.shade200, width: sel ? 2 : 1)),
            child: Row(children: [
              Icon(item['icon'] as IconData, color: sel ? c : AppColors.textLight, size: 22),
              const SizedBox(width: 12),
              Text(item['label'] as String, style: GoogleFonts.inter(
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  color: sel ? c : AppColors.textSecondary)),
              const Spacer(),
              if (sel) Icon(Icons.check_rounded, color: c, size: 18),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildDetailCard() => _sectionCard('Detail Pemeriksaan', Icons.medical_services_outlined,
    Column(children: [
      _tf(ctrl: _sickCtrl, label: 'Jumlah Ayam Sakit (ekor)', icon: Icons.sick_outlined, type: TextInputType.number),
      const SizedBox(height: 12),
      _tf(ctrl: _symptomsCtrl, label: 'Gejala yang diamati', icon: Icons.notes_rounded, lines: 2),
      const SizedBox(height: 12),
      _tf(ctrl: _behaviorCtrl, label: 'Perubahan perilaku', icon: Icons.psychology_outlined, lines: 2),
      const SizedBox(height: 12),
      _tf(ctrl: _actionsCtrl, label: 'Tindakan yang dilakukan', icon: Icons.handyman_outlined, lines: 2),
    ]),
  );

  Widget _sectionCard(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: AppColors.statusGood, size: 18), const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))]),
      const SizedBox(height: 14), child,
    ]),
  );

  Widget _tf({required TextEditingController ctrl, required String label, required IconData icon,
      TextInputType? type, int lines = 1}) => TextField(
    controller: ctrl, keyboardType: type, maxLines: lines, style: GoogleFonts.inter(),
    decoration: InputDecoration(
      labelText: label, labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.statusGood, size: 20),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.statusGood, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  Widget _buildSaveButton() => SizedBox(width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusGood, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Simpan Health Check', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
    ),
  );
}