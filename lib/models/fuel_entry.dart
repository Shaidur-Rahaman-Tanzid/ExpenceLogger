class FuelEntry {
  final int? id;
  final int vehicleId;
  final double fuelAmount; // in liters
  final double fuelCost; // total cost
  final double odometerReading; // ODO reading at time of refuel
  final bool isFullTank; // whether tank was filled completely
  final DateTime refuelDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  FuelEntry({
    this.id,
    required this.vehicleId,
    required this.fuelAmount,
    required this.fuelCost,
    required this.odometerReading,
    this.isFullTank = true,
    required this.refuelDate,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculate price per liter
  double get pricePerLiter => fuelAmount > 0 ? fuelCost / fuelAmount : 0;

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'fuelAmount': fuelAmount,
      'fuelCost': fuelCost,
      'odometerReading': odometerReading,
      'isFullTank': isFullTank ? 1 : 0,
      'refuelDate': refuelDate.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      fuelAmount: (map['fuelAmount'] as num).toDouble(),
      fuelCost: (map['fuelCost'] as num).toDouble(),
      odometerReading: (map['odometerReading'] as num).toDouble(),
      isFullTank: (map['isFullTank'] as int) == 1,
      refuelDate: DateTime.parse(map['refuelDate'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Copy with method
  FuelEntry copyWith({
    int? id,
    int? vehicleId,
    double? fuelAmount,
    double? fuelCost,
    double? odometerReading,
    bool? isFullTank,
    DateTime? refuelDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      fuelAmount: fuelAmount ?? this.fuelAmount,
      fuelCost: fuelCost ?? this.fuelCost,
      odometerReading: odometerReading ?? this.odometerReading,
      isFullTank: isFullTank ?? this.isFullTank,
      refuelDate: refuelDate ?? this.refuelDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
