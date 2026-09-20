class TaskModel {
  final int id;
  final int? barnId;
  final int? batchId;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final DateTime dueDate;
  final String? dueTime;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.barnId,
    this.batchId,
    this.description,
    this.dueTime,
    this.isRecurring = false,
    this.recurringPattern,
    this.completedAt,
  });

  bool get isOverdue => status != 'completed' && dueDate.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day;
  }

  String get categoryLabel {
    switch (category) {
      case 'feeding': return 'Pemberian Pakan';
      case 'health': return 'Kesehatan';
      case 'cleaning': return 'Kebersihan';
      case 'vaccination': return 'Vaksinasi';
      case 'maintenance': return 'Perawatan';
      default: return 'Lainnya';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'urgent': return 'Mendesak';
      case 'high': return 'Tinggi';
      case 'medium': return 'Sedang';
      default: return 'Rendah';
    }
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      barnId: json['barn_id'] != null ? (json['barn_id'] as num).toInt() : null,
      batchId: json['batch_id'] != null ? (json['batch_id'] as num).toInt() : null,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'other',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      dueDate: DateTime.parse(json['due_date'] as String),
      dueTime: json['due_time'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringPattern: json['recurring_pattern'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'barn_id': barnId,
    'batch_id': batchId,
    'title': title,
    'description': description,
    'category': category,
    'priority': priority,
    'status': status,
    'due_date': dueDate.toIso8601String().split('T')[0],
    'due_time': dueTime,
    'is_recurring': isRecurring,
    'recurring_pattern': recurringPattern,
  };
}

class IncomeRecord {
  final int id;
  final int? barnId;
  final int? batchId;
  final DateTime incomeDate;
  final String incomeType;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final String? buyerName;
  final String? notes;

  IncomeRecord({
    required this.id,
    required this.incomeDate,
    required this.incomeType,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.barnId,
    this.batchId,
    this.buyerName,
    this.notes,
  });

  String get incomeTypeLabel {
    switch (incomeType) {
      case 'egg_sales': return 'Penjualan Telur';
      case 'bird_sales': return 'Penjualan Ayam';
      case 'manure': return 'Penjualan Kotoran';
      default: return 'Lainnya';
    }
  }

  factory IncomeRecord.fromJson(Map<String, dynamic> json) {
    return IncomeRecord(
      id: json['id'] as int,
      barnId: json['barn_id'] != null ? (json['barn_id'] as num).toInt() : null,
      batchId: json['batch_id'] != null ? (json['batch_id'] as num).toInt() : null,
      incomeDate: DateTime.parse(json['income_date'] as String),
      incomeType: json['income_type'] as String? ?? 'other',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      buyerName: json['buyer_name'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'barn_id': barnId,
    'batch_id': batchId,
    'income_date': incomeDate.toIso8601String().split('T')[0],
    'income_type': incomeType,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_amount': totalAmount,
    'buyer_name': buyerName,
    'notes': notes,
  };
}
