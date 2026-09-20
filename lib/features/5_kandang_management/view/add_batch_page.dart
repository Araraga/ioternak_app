import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/batch_model.dart';

class AddBatchPage extends StatefulWidget {
  final int barnId;
  final BatchModel? existing;
  const AddBatchPage({super.key, required this.barnId, this.existing});
  @override
  State<AddBatchPage> createState() => _AddBatchPageState();
}class _AddBatchPageState extends State<AddBatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _birdType = "broiler";
  DateTime _startDate = DateTime.now();
  DateTime? _targetDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    if (b != null) {
      _nameCtrl.text = b.batchName;
      _breedCtrl.text = b.breed ?? "";
      _supplierCtrl.text = b.supplier ?? "";
      _countCtrl.text = b.initialCount.toString();
      _notesCtrl.text = b.notes ?? "";
      _birdType = b.birdType;
      _startDate = b.startDate;
      _targetDate = b.targetHarvestDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _breedCtrl.dispose(); _supplierCtrl.dispose();
    _countCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        "barn_id": widget.barnId,
        "batch_name": _nameCtrl.text.trim(),
        "bird_type": _birdType,
        "initial_count": int.parse(_countCtrl.text.trim()),
        "current_count": int.parse(_countCtrl.text.trim()),
        "start_date": _startDate.toIso8601String().split("T")[0],
      };
      if (_breedCtrl.text.isNotEmpty) body["breed"] = _breedCtrl.text.trim();
      if (_supplierCtrl.text.isNotEmpty) body["supplier"] = _supplierCtrl.text.trim();
      if (_notesCtrl.text.isNotEmpty) body["notes"] = _notesCtrl.text.trim();
      if (_targetDate != null) body["target_harvest_date"] = _targetDate!.toIso8601String().split("T")[0];
      http.Response res;
      if (widget.existing != null) {
        res = await http.put(Uri.parse(ApiEndpoints.updateBatch(widget.existing!.id.toString())),
            headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiEndpoints.createBatch),
            headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      }
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existing != null ? "Batch diperbarui!" : "Batch baru dibuat!"),
          backgroundColor: AppColors.statusGood));
        Navigator.pop(context, true);
      } else {
        String msg = "Gagal menyimpan.";
        try {
          final errJson = jsonDecode(res.body);
          if (errJson['message'] != null) msg = errJson['message'];
        } catch (_) {}
        _err(msg);
      }
    } catch (e) { _err("Error: $e"); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  void _err(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.statusDanger));

  Future<void> _pickDate(bool isStart) async {
    final init = isStart ? _startDate : (_targetDate ?? DateTime.now().add(const Duration(days: 35)));
    final p = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (p != null) setState(() => isStart ? _startDate = p : _targetDate = p);
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existing != null ? "Edit Batch" : "Batch Baru",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTypeSelector(), const SizedBox(height: 16),
            _buildInfoCard(), const SizedBox(height: 16),
            _buildDatesCard(), const SizedBox(height: 16),
            _buildNotesCard(), const SizedBox(height: 28),
            _buildSaveButton(), const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      {"key": "broiler", "label": "Broiler", "emoji": "Broiler", "sub": "Pedaging"},
      {"key": "layer", "label": "Layer", "emoji": "Layer", "sub": "Petelur"},
      {"key": "breeder", "label": "Breeder", "emoji": "Breeder", "sub": "Pembibit"},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Jenis Ternak", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      Row(children: types.map((t) {
        final sel = _birdType == t["key"];
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _birdType = t["key"]!),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade200, width: sel ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(children: [
              Text(t["label"]!, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: sel ? Colors.white : AppColors.primary)), const SizedBox(height: 4),
              Text(t["label"]!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? Colors.white : AppColors.textPrimary)),
              Text(t["sub"]!, style: GoogleFonts.inter(fontSize: 10, color: sel ? Colors.white70 : AppColors.textSecondary)),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }  Widget _buildInfoCard() {
    return _sectionCard("Informasi Batch", Icons.info_outline_rounded, Column(children: [
      _tf(ctrl: _nameCtrl, label: "Nama Batch *", icon: Icons.label_outline_rounded, req: true),
      const SizedBox(height: 12),
      _tf(ctrl: _countCtrl, label: "Jumlah DOC (ekor) *", icon: Icons.numbers_outlined, type: TextInputType.number, req: true),
      const SizedBox(height: 12),
      _tf(ctrl: _breedCtrl, label: "Strain / Ras (opsional)", icon: Icons.category_outlined),
      const SizedBox(height: 12),
      _tf(ctrl: _supplierCtrl, label: "Supplier DOC (opsional)", icon: Icons.store_outlined),
    ]));
  }

  Widget _buildDatesCard() {
    return _sectionCard("Jadwal", Icons.calendar_month_outlined, Column(children: [
      _dateTile("Tanggal Mulai *", _startDate, () => _pickDate(true)), const SizedBox(height: 10),
      _dateTile("Target Panen (opsional)", _targetDate, () => _pickDate(false)),
    ]));
  }

  Widget _buildNotesCard() {
    return _sectionCard("Catatan", Icons.notes_rounded, _tf(ctrl: _notesCtrl, label: "Catatan (opsional)", icon: Icons.notes_rounded, lines: 3));
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.event_rounded, color: AppColors.primary), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            Text(date != null ? DateFormat("d MMMM yyyy", "id_ID").format(date) : "Pilih Tanggal",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const Spacer(), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: AppColors.primary, size: 18), const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))]),
        const SizedBox(height: 14), child,
      ]),
    );
  }

  Widget _tf({required TextEditingController ctrl, required String label, required IconData icon,
      TextInputType? type, int lines = 1, bool req = false}) {
    return TextFormField(
      controller: ctrl, keyboardType: type, maxLines: lines, style: GoogleFonts.inter(),
      validator: req ? (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null : null,
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20), filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.statusDanger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(widget.existing != null ? "Perbarui Batch" : "Buat Batch Baru", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
    ));
  }
}