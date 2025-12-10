class Vehicle {
  int? id;
  String make;
  String model;
  int year;
  String registrationNumber;
  String? color;
  double? purchasePrice;
  DateTime purchaseDate;
  double? currentMileage;
  String? fuelType; // Petrol, Diesel, Electric, Hybrid
  String? vehicleType; // Car, Bike, Truck, etc.
  double? tankCapacity; // Tank capacity in liters
  String? imagePath;
  String? note;
  DateTime createdAt;
  DateTime updatedAt;

  Vehicle({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.registrationNumber,
    this.color,
    this.purchasePrice,
    required this.purchaseDate,
    this.currentMileage,
    this.fuelType,
    this.vehicleType,
    this.tankCapacity,
    this.imagePath,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Vehicle to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'registrationNumber': registrationNumber,
      'color': color,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currentMileage': currentMileage,
      'fuelType': fuelType,
      'vehicleType': vehicleType,
      'tankCapacity': tankCapacity,
      'imagePath': imagePath,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Vehicle from Map
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      registrationNumber: map['registrationNumber'] as String,
      color: map['color'] as String?,
      purchasePrice: map['purchasePrice'] != null
          ? (map['purchasePrice'] as num).toDouble()
          : null,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      currentMileage: map['currentMileage'] != null
          ? (map['currentMileage'] as num).toDouble()
          : null,
      fuelType: map['fuelType'] as String?,
      vehicleType: map['vehicleType'] as String?,
      tankCapacity: map['tankCapacity'] != null
          ? (map['tankCapacity'] as num).toDouble()
          : null,
      imagePath: map['imagePath'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Create a copy of Vehicle with updated fields
  Vehicle copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? registrationNumber,
    String? color,
    double? purchasePrice,
    DateTime? purchaseDate,
    double? currentMileage,
    String? fuelType,
    String? vehicleType,
    double? tankCapacity,
    String? imagePath,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      color: color ?? this.color,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      currentMileage: currentMileage ?? this.currentMileage,
      fuelType: fuelType ?? this.fuelType,
      vehicleType: vehicleType ?? this.vehicleType,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, make: $make, model: $model, year: $year, '
        'registrationNumber: $registrationNumber)';
  }
}
