import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/batch_model.dart';

class ProductionLogPage extends StatefulWidget {
  final BatchModel batch;
  const ProductionLogPage({super.key, required this.batch});
  @override
  State<ProductionLogPage> createState() => _ProductionLogPageState();
}

class _ProductionLogPageState extends State<ProductionLogPage> {
  final _eggsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _feedCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _eggsCtrl.dispose(); _weightCtrl.dispose(); _feedCtrl.dispose();
    _waterCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isLayer => widget.batch.birdType == 'layer';

  Future<void> _save() async {
    final feed = double.tryParse(_feedCtrl.text);
    if (feed == null) { _err('Masukkan jumlah pakan'); return; }
    if (_isLayer && _eggsCtrl.text.isEmpty) { _err('Masukkan jumlah telur'); return; }
    if (!_isLayer && _weightCtrl.text.isEmpty) { _err('Masukkan berat rata-rata'); return; }
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'batch_id': widget.batch.id,
        'log_date': _selectedDate.toIso8601String().split('T')[0],
        'feed_consumed_kg': feed,
        'bird_count': widget.batch.currentCount,
      };
      if (_notesCtrl.text.isNotEmpty) body['notes'] = _notesCtrl.text;
      if (_isLayer && _eggsCtrl.text.isNotEmpty) body['eggs_collected'] = int.parse(_eggsCtrl.text);
      if (!_isLayer && _weightCtrl.text.isNotEmpty) body['average_weight'] = double.parse(_weightCtrl.text);
      if (_waterCtrl.text.isNotEmpty) body['water_consumed_liters'] = double.parse(_waterCtrl.text);
      final res = await http.post(Uri.parse(ApiEndpoints.addProductionLog),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Log berhasil disimpan!'), backgroundColor: AppColors.statusGood));
        Navigator.pop(context, true);
      } else { _err('Gagal menyimpan. Coba lagi.'); }
    } catch (e) { _err('Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  void _err(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.statusDanger));

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _selectedDate,
        firstDate: widget.batch.startDate, lastDate: DateTime.now());
    if (p != null) setState(() => _selectedDate = p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Log Produksi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _banner(), const SizedBox(height: 20),
          _dateCard(), const SizedBox(height: 16),
          _prodCard(), const SizedBox(height: 16),
          _feedCard(), const SizedBox(height: 16),
          _notesCard(), const SizedBox(height: 28),
          _saveBtn(), const SizedBox(height: 40),
        ]),
      ),
    );
  }


  Widget _banner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Text(_isLayer ? '🥚' : '🍗', style: const TextStyle(fontSize: 28)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.batch.batchName, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        Text('${widget.batch.currentCount} ekor — Hari ke-${widget.batch.ageDays}',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
      ]),
    ]),
  );

  Widget _dateCard() => _card('Tanggal Log', Icons.calendar_today_outlined,
    GestureDetector(onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.event_rounded, color: AppColors.primary), const SizedBox(width: 10),
          Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const Spacer(), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ]),
      ),
    ),
  );

  Widget _prodCard() => _card(
    _isLayer ? 'Produksi Telur' : 'Data Berat Ayam',
    _isLayer ? Icons.egg_outlined : Icons.monitor_weight_outlined,
    _tf(ctrl: _isLayer ? _eggsCtrl : _weightCtrl,
        label: _isLayer ? 'Jumlah Telur (butir)' : 'Berat Rata-rata (gram/ekor)',
        icon: _isLayer ? Icons.egg_outlined : Icons.monitor_weight_outlined,
        type: TextInputType.number),
  );

  Widget _feedCard() => _card('Konsumsi Pakan & Air', Icons.grass_outlined,
    Column(children: [
      _tf(ctrl: _feedCtrl, label: 'Pakan Dikonsumsi (kg)', icon: Icons.grass_outlined, type: TextInputType.number),
      const SizedBox(height: 12),
      _tf(ctrl: _waterCtrl, label: 'Air (liter) — Opsional', icon: Icons.water_drop_outlined, type: TextInputType.number),
    ]),
  );

  Widget _notesCard() => _card('Catatan', Icons.notes_rounded,
      _tf(ctrl: _notesCtrl, label: 'Catatan (opsional)', icon: Icons.notes_rounded, lines: 3));

  Widget _card(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: AppColors.primary, size: 18), const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))]),
      const SizedBox(height: 14), child,
    ]),
  );

  Widget _tf({required TextEditingController ctrl, required String label, required IconData icon, TextInputType? type, int lines = 1}) =>
    TextField(controller: ctrl, keyboardType: type, maxLines: lines, style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _saveBtn() => SizedBox(width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Simpan Log Produksi', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
    ),
  );
}
