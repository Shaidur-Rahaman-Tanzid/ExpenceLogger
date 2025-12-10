class OdoEntry {
  final int? id;
  final int vehicleId;
  final double odometerReading; // in kilometers
  final DateTime recordedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  OdoEntry({
    this.id,
    required this.vehicleId,
    required this.odometerReading,
    required this.recordedAt,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'odometerReading': odometerReading,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory OdoEntry.fromMap(Map<String, dynamic> map) {
    return OdoEntry(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      odometerReading: (map['odometerReading'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Copy with method
  OdoEntry copyWith({
    int? id,
    int? vehicleId,
    double? odometerReading,
    DateTime? recordedAt,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OdoEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      odometerReading: odometerReading ?? this.odometerReading,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
