class BatchModel {
  final int id;
  final int barnId;
  final String batchName;
  final String birdType;
  final String? breed;
  final String? supplier;
  final int initialCount;
  final int currentCount;
  final DateTime startDate;
  final DateTime? targetHarvestDate;
  final String status;
  final String? notes;

  BatchModel({
    required this.id,
    required this.barnId,
    required this.batchName,
    required this.birdType,
    required this.initialCount,
    required this.currentCount,
    required this.startDate,
    this.breed,
    this.supplier,
    this.targetHarvestDate,
    this.status = 'active',
    this.notes,
  });

  int get ageDays => DateTime.now().difference(startDate).inDays;
  int get mortalityCount => initialCount - currentCount;
  double get mortalityRate =>
      initialCount > 0 ? (mortalityCount / initialCount) * 100 : 0;

  String get birdTypeLabel {
    switch (birdType) {
      case 'broiler': return 'Broiler (Pedaging)';
      case 'layer': return 'Layer (Petelur)';
      case 'breeder': return 'Breeder (Pembibit)';
      default: return birdType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active': return 'Aktif';
      case 'completed': return 'Selesai';
      case 'terminated': return 'Dihentikan';
      default: return status;
    }
  }

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as int,
      barnId: json['barn_id'] as int,
      batchName: json['batch_name'] as String,
      birdType: json['bird_type'] as String? ?? 'broiler',
      breed: json['breed'] as String?,
      supplier: json['supplier'] as String?,
      initialCount: (json['initial_count'] as num).toInt(),
      currentCount: (json['current_count'] as num).toInt(),
      startDate: DateTime.parse(json['start_date'] as String),
      targetHarvestDate: json['target_harvest_date'] != null
          ? DateTime.parse(json['target_harvest_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'barn_id': barnId,
    'batch_name': batchName,
    'bird_type': birdType,
    'breed': breed,
    'supplier': supplier,
    'initial_count': initialCount,
    'current_count': currentCount,
    'start_date': startDate.toIso8601String().split('T')[0],
    'target_harvest_date': targetHarvestDate?.toIso8601String().split('T')[0],
    'status': status,
    'notes': notes,
  };
}
