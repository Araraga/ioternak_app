import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/local_notification_service.dart';

class TaskPage extends StatefulWidget {
  final int barnId;
  const TaskPage({super.key, required this.barnId});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, today, recurring

  static const List<String> _daysIndo = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  static const List<String> _monthsIndo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String formatIndoDate(DateTime dt) {
    final dayName = _daysIndo[dt.weekday - 1];
    final monthName = _monthsIndo[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  static String formatShortDate(DateTime dt) {
    final dayName = _daysIndo[dt.weekday - 1];
    final monthName = _monthsIndo[dt.month - 1];
    return '$dayName, ${dt.day} $monthName';
  }

  @override
  void initState() {
    super.initState();
    LocalNotificationService.instance.requestPermission();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.getTasks(widget.barnId.toString())));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] ?? [];
        if (mounted) {
          setState(() => _tasks = list);
        }
        _syncLocalNotifications(list);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _syncLocalNotifications(List<dynamic> tasks) {
    for (var t in tasks) {
      final task = Map<String, dynamic>.from(t);
      final id = int.tryParse(task['id'].toString()) ?? 0;
      if (id <= 0) continue;
      final title = task['title']?.toString() ?? 'Jadwal Kandang';
      final desc = task['description']?.toString() ?? '';
      final rawDueDate = task['due_date'];
      final rawDueTime = task['due_time'];
      final isRecurring = task['is_recurring'] == true;
      final pattern = task['recurring_pattern']?.toString();

      DateTime? scheduledDateTime;
      if (rawDueDate != null) {
        try {
          final dt = DateTime.parse(rawDueDate.toString());
          int hour = 8;
          int minute = 0;
          if (rawDueTime != null && rawDueTime.toString().isNotEmpty) {
            final parts = rawDueTime.toString().split(':');
            if (parts.isNotEmpty) hour = int.tryParse(parts[0]) ?? 8;
            if (parts.length > 1) minute = int.tryParse(parts[1]) ?? 0;
          }
          scheduledDateTime = DateTime(dt.year, dt.month, dt.day, hour, minute);
        } catch (_) {}
      }

      if (scheduledDateTime != null) {
        LocalNotificationService.instance.scheduleTaskReminder(
          id: id,
          title: title,
          body: desc,
          scheduledDate: scheduledDateTime,
          isRecurring: isRecurring,
          recurringPattern: pattern,
        );
      }
    }
  }

  Future<void> _deleteTask(int taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Pengingat?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Jadwal dan pengingat notifikasi HP ini akan dihapus permanen.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await http.delete(Uri.parse(ApiEndpoints.deleteTask(taskId.toString())));
      await LocalNotificationService.instance.cancelReminder(taskId);
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal pengingat berhasil dihapus')),
        );
      }
    } catch (_) {}
  }

  List<dynamic> get _filteredTasks {
    final now = DateTime.now();
    if (_filter == 'today') {
      return _tasks.where((t) {
        final d = t['due_date'];
        if (d == null) return false;
        try {
          final dt = DateTime.parse(d.toString());
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (_filter == 'recurring') {
      return _tasks.where((t) => t['is_recurring'] == true).toList();
    }
    return _tasks;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalCount = _tasks.length;
    final recurringCount = _tasks.where((t) => t['is_recurring'] == true).length;
    final todayCount = _tasks.where((t) {
      final d = t['due_date'];
      if (d == null) return false;
      try {
        final dt = DateTime.parse(d.toString());
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Jadwal & Pengingat Kandang',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildHeaderStats(totalCount, recurringCount),
                _buildFilterTabs(totalCount, todayCount, recurringCount),
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: _filteredTasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _buildTaskCard(_filteredTasks[i]),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskModal(),
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.notification_add_rounded, color: Colors.white),
        label: Text('Tambah Pengingat',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
      ),
    );
  }

  Widget _buildHeaderStats(int totalCount, int recurringCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$totalCount Pengingat',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                        Text('Notifikasi HP Aktif',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E44AD).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8E44AD).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded, color: Color(0xFF8E44AD), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$recurringCount Rutin',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF8E44AD))),
                        Text('Berulang Otomatis',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(int totalCount, int todayCount, int recurringCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('Semua ($totalCount)', 'all'),
          const SizedBox(width: 8),
          _filterChip('Hari Ini ($todayCount)', 'today'),
          const SizedBox(width: 8),
          _filterChip('Berulang ($recurringCount)', 'recurring'),
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

  Widget _buildTaskCard(dynamic t) {
    final Map<String, dynamic> task = Map<String, dynamic>.from(t);
    final int taskId = int.tryParse(task['id'].toString()) ?? 0;
    final title = task['title'] ?? 'Tanpa Judul';
    final desc = task['description'];
    final priority = task['priority'] ?? 'medium';
    final category = task['category'] ?? 'other';
    final rawDueDate = task['due_date'];
    final rawDueTime = task['due_time'];
    final isRecurring = task['is_recurring'] == true;
    final recurringPattern = task['recurring_pattern'];

    String dateStr = '-';
    if (rawDueDate != null) {
      try {
        dateStr = formatShortDate(DateTime.parse(rawDueDate.toString()));
      } catch (_) {
        dateStr = rawDueDate.toString().split('T')[0];
      }
    }

    String? timeStr;
    if (rawDueTime != null && rawDueTime.toString().isNotEmpty) {
      final parts = rawDueTime.toString().split(':');
      if (parts.length >= 2) {
        timeStr = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')} WIB';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (desc != null && desc.toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildScheduleBadges(dateStr, timeStr, isRecurring, recurringPattern),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _categoryTag(category.toString()),
                      const SizedBox(width: 6),
                      _priorityBadge(priority.toString()),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
              onPressed: () => _deleteTask(taskId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleBadges(String dateStr, String? timeStr, bool isRecurring, dynamic recurringPattern) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, size: 12, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(dateStr, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            ],
          ),
        ),
        if (timeStr != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(timeStr, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ],
            ),
          ),
        if (isRecurring)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync_rounded, size: 12, color: Colors.purple),
                const SizedBox(width: 3),
                Text(recurringPattern?.toString() ?? 'Berulang', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.purple)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_active_rounded, size: 11, color: Color(0xFF10B981)),
              const SizedBox(width: 3),
              Text(
                'Notif HP',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryTag(String cat) {
    IconData icon;
    String label;
    Color color;

    switch (cat.toLowerCase()) {
      case 'feeding':
      case 'pakan':
        icon = Icons.restaurant_rounded;
        label = 'PAKAN';
        color = const Color(0xFF27AE60);
        break;
      case 'health':
      case 'kesehatan':
      case 'biosecurity':
        icon = Icons.health_and_safety_rounded;
        label = 'KESEHATAN';
        color = const Color(0xFFE74C3C);
        break;
      case 'cleaning':
      case 'sanitasi':
      case 'pembersihan':
        icon = Icons.cleaning_services_rounded;
        label = 'SANITASI';
        color = const Color(0xFF16A085);
        break;
      case 'vaccination':
      case 'vaksinasi':
        icon = Icons.vaccines_rounded;
        label = 'VAKSINASI';
        color = const Color(0xFF8E44AD);
        break;
      case 'maintenance':
      case 'pemeliharaan':
      case 'listrik_alat':
        icon = Icons.build_circle_rounded;
        label = 'PERAWATAN';
        color = const Color(0xFFE67E22);
        break;
      case 'production':
      case 'produksi':
        icon = Icons.egg_rounded;
        label = 'PRODUKSI';
        color = const Color(0xFFD4AC0D);
        break;
      default:
        icon = Icons.task_alt_rounded;
        label = 'UMUM';
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String p) {
    Color c;
    String label;
    switch (p.toLowerCase()) {
      case 'high':
      case 'urgent':
      case 'tinggi':
        c = AppColors.statusDanger;
        label = 'TINGGI';
        break;
      case 'medium':
      case 'sedang':
        c = AppColors.statusWarning;
        label = 'SEDANG';
        break;
      case 'low':
      case 'rendah':
      default:
        c = AppColors.statusGood;
        label = 'RENDAH';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: c),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'today'
                  ? 'Tidak Ada Pengingat Hari Ini'
                  : _filter == 'recurring'
                      ? 'Belum Ada Jadwal Berulang'
                      : 'Belum Ada Jadwal Pengingat',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Tekan tombol di bawah untuk menambah jadwal pengingat. Notifikasi HP otomatis muncul saat waktunya tiba.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTaskSheet(
        barnId: widget.barnId,
        onTaskCreated: _loadTasks,
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final int barnId;
  final VoidCallback onTaskCreated;
  const _AddTaskSheet({required this.barnId, required this.onTaskCreated});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'feeding', 'label': 'Pakan', 'icon': Icons.restaurant_rounded},
    {'id': 'health', 'label': 'Kesehatan', 'icon': Icons.health_and_safety_rounded},
    {'id': 'cleaning', 'label': 'Sanitasi', 'icon': Icons.cleaning_services_rounded},
    {'id': 'vaccination', 'label': 'Vaksinasi', 'icon': Icons.vaccines_rounded},
    {'id': 'maintenance', 'label': 'Perawatan', 'icon': Icons.build_circle_rounded},
    {'id': 'production', 'label': 'Produksi', 'icon': Icons.egg_rounded},
    {'id': 'other', 'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  static const List<String> _daysList = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  String _selectedCategory = 'feeding';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isRecurring = false;
  String _recurringType = 'daily';
  final List<String> _selectedDays = ['Senin', 'Rabu', 'Jumat'];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, left: 20, right: 14, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_add_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tambah Jadwal & Pengingat',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Atur waktu & hari, notifikasi otomatis muncul di HP Anda',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Tugas / Jadwal *',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleCtrl,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Pemberian Pakan Siang / Vaksinasi',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Deskripsi & Catatan (Opsional)',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Porsi 10 kg, periksa nipple minum',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.description_outlined, color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildDateTimeSection(),
                  const SizedBox(height: 18),
                  _buildRecurrenceSection(),
                  const SizedBox(height: 18),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jadwal Hari, Tanggal & Jam *',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Pilih Tanggal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildQuickDayChip('Hari Ini', _isSameDay(_selectedDate, DateTime.now()), () {
                setState(() => _selectedDate = DateTime.now());
              }),
              const SizedBox(width: 6),
              _buildQuickDayChip('Besok', _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1))), () {
                setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1)));
              }),
              const SizedBox(width: 6),
              _buildQuickDayChip('Lusa', _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 2))), () {
                setState(() => _selectedDate = DateTime.now().add(const Duration(days: 2)));
              }),
              const Spacer(),
              Text(
                _TaskPageState.formatIndoDate(_selectedDate),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Atur Jam & Menit',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (DateTime newTime) {
                  _selectedTime = TimeOfDay(hour: newTime.hour, minute: newTime.minute);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Jadwal Berulang',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Switch.adaptive(
                value: _isRecurring,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
            ],
          ),
          if (_isRecurring) ...[
            const Divider(height: 14),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Setiap Hari')),
                    selected: _recurringType == 'daily',
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: _recurringType == 'daily' ? FontWeight.bold : FontWeight.normal,
                      color: _recurringType == 'daily' ? AppColors.primaryDark : Colors.black87,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _recurringType = 'daily');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Hari Tertentu')),
                    selected: _recurringType == 'weekly',
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: _recurringType == 'weekly' ? FontWeight.bold : FontWeight.normal,
                      color: _recurringType == 'weekly' ? AppColors.primaryDark : Colors.black87,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _recurringType = 'weekly');
                    },
                  ),
                ),
              ],
            ),
            if (_recurringType == 'weekly') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _daysList.map((day) {
                  final isDaySel = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day.substring(0, 3)),
                    selected: isDaySel,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isDaySel ? FontWeight.bold : FontWeight.normal,
                      color: isDaySel ? AppColors.primaryDark : Colors.black87,
                    ),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori Kegiatan *',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _categories.map((cat) {
            final catId = cat['id'] as String;
            final isSel = _selectedCategory == catId;
            final catIcon = cat['icon'] as IconData;
            final catLabel = cat['label'] as String;

            return ChoiceChip(
              avatar: Icon(catIcon, size: 14, color: isSel ? AppColors.primaryDark : Colors.grey.shade600),
              label: Text(catLabel),
              selected: isSel,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? AppColors.primaryDark : Colors.black87,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = catId);
              },
            );
          }).toList(),
        ),
      ],
    );
  }



  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Simpan Pengingat (Aktifkan Notif)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickDayChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTask() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengingat wajib diisi!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final nav = Navigator.of(context);

    final formattedDate =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    String? pattern;
    if (_isRecurring) {
      pattern = _recurringType == 'daily' ? 'Setiap Hari' : _selectedDays.join(', ');
    }

    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.createTask),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barn_id': widget.barnId,
          'title': title,
          'description': _descCtrl.text.trim(),
          'category': _selectedCategory,
          'priority': 'high',
          'due_date': formattedDate,
          'due_time': formattedTime,
          'is_recurring': _isRecurring,
          'recurring_pattern': pattern,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final resData = jsonDecode(res.body)['data'];
          final int taskId = (resData != null && resData['id'] != null)
              ? (int.tryParse(resData['id'].toString()) ?? (DateTime.now().millisecondsSinceEpoch % 100000))
              : (DateTime.now().millisecondsSinceEpoch % 100000);

          final scheduledDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );

          await LocalNotificationService.instance.scheduleTaskReminder(
            id: taskId,
            title: title,
            body: _descCtrl.text.trim(),
            scheduledDate: scheduledDateTime,
            isRecurring: _isRecurring,
            recurringPattern: pattern,
          );
        } catch (_) {}

        nav.pop();
        widget.onTaskCreated();
      } else {
        String err = 'Gagal menyimpan pengingat';
        try {
          final d = jsonDecode(res.body);
          if (d['message'] != null) err = d['message'];
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.statusDanger),
          );
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusDanger),
        );
      }
      setState(() => _isSaving = false);
    }
  }
}

