class ProductionLog {
  final int id;
  final int batchId;
  final DateTime logDate;
  final int? eggsCollected;
  final double? averageWeight;
  final double? feedConsumedKg;
  final double? waterConsumedLiters;
  final int? birdCount;
  final double? fcr;
  final double? productionRate;
  final String? notes;

  ProductionLog({
    required this.id,
    required this.batchId,
    required this.logDate,
    this.eggsCollected,
    this.averageWeight,
    this.feedConsumedKg,
    this.waterConsumedLiters,
    this.birdCount,
    this.fcr,
    this.productionRate,
    this.notes,
  });

  factory ProductionLog.fromJson(Map<String, dynamic> json) {
    return ProductionLog(
      id: json['id'] as int,
      batchId: json['batch_id'] as int,
      logDate: DateTime.parse(json['log_date'] as String),
      eggsCollected: json['eggs_collected'] != null
          ? (json['eggs_collected'] as num).toInt() : null,
      averageWeight: json['average_weight'] != null
          ? (json['average_weight'] as num).toDouble() : null,
      feedConsumedKg: json['feed_consumed_kg'] != null
          ? (json['feed_consumed_kg'] as num).toDouble() : null,
      waterConsumedLiters: json['water_consumed_liters'] != null
          ? (json['water_consumed_liters'] as num).toDouble() : null,
      birdCount: json['bird_count'] != null
          ? (json['bird_count'] as num).toInt() : null,
      fcr: json['fcr'] != null ? (json['fcr'] as num).toDouble() : null,
      productionRate: json['production_rate'] != null
          ? (json['production_rate'] as num).toDouble() : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'log_date': logDate.toIso8601String().split('T')[0],
    'eggs_collected': eggsCollected,
    'average_weight': averageWeight,
    'feed_consumed_kg': feedConsumedKg,
    'water_consumed_liters': waterConsumedLiters,
    'bird_count': birdCount,
    'notes': notes,
  };
}

class HealthCheck {
  final int id;
  final int batchId;
  final DateTime checkDate;
  final String overallStatus;
  final int sickBirdsCount;
  final String? symptoms;
  final String? behavioralNotes;
  final String? actionsTaken;

  HealthCheck({
    required this.id,
    required this.batchId,
    required this.checkDate,
    required this.overallStatus,
    this.sickBirdsCount = 0,
    this.symptoms,
    this.behavioralNotes,
    this.actionsTaken,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      id: json['id'] as int,
      batchId: json['batch_id'] as int,
      checkDate: DateTime.parse(json['check_date'] as String),
      overallStatus: json['overall_status'] as String? ?? 'good',
      sickBirdsCount: (json['sick_birds_count'] as num?)?.toInt() ?? 0,
      symptoms: json['symptoms'] as String?,
      behavioralNotes: json['behavioral_notes'] as String?,
      actionsTaken: json['actions_taken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'check_date': checkDate.toIso8601String().split('T')[0],
    'overall_status': overallStatus,
    'sick_birds_count': sickBirdsCount,
    'symptoms': symptoms,
    'behavioral_notes': behavioralNotes,
    'actions_taken': actionsTaken,
  };
}

class VaccinationScheduleItem {
  final String name;
  final int ageDay;
  final DateTime dueDate;
  final String status;
  final DateTime? completedDate;

  VaccinationScheduleItem({
    required this.name,
    required this.ageDay,
    required this.dueDate,
    required this.status,
    this.completedDate,
  });

  factory VaccinationScheduleItem.fromJson(Map<String, dynamic> json) {
    return VaccinationScheduleItem(
      name: json['name'] as String,
      ageDay: (json['age_day'] as num).toInt(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'pending',
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String) : null,
    );
  }
}
