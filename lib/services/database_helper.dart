import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/vehicle.dart';
import '../models/odo_entry.dart';
import '../models/fuel_entry.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database configuration
  static const String _databaseName = 'money_mate.db';
  static const int _databaseVersion = 9; // Added fuelEfficiency column
  static const String _tableName = 'expenses';
  static const String _budgetTable = 'budgets';
  static const String _goalsTable = 'saving_goals';
  static const String _vehicleTable = 'vehicles';
  static const String _odoEntriesTable = 'odo_entries';
  static const String _fuelEntriesTable = 'fuel_entries';

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        voiceNotePath TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_budgetTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_goalsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0,
        deadline TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_vehicleTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        registrationNumber TEXT NOT NULL,
        color TEXT,
        purchasePrice REAL,
        purchaseDate TEXT NOT NULL,
        currentMileage REAL,
        fuelType TEXT,
        vehicleType TEXT,
        tankCapacity REAL,
        fuelEfficiency REAL,
        imagePath TEXT,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create ODO entries table
    await db.execute('''
      CREATE TABLE $_odoEntriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        odometerReading REAL NOT NULL,
        recordedAt TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES $_vehicleTable (id) ON DELETE CASCADE
      )
    ''');

    // Create fuel entries table
    await db.execute('''
      CREATE TABLE $_fuelEntriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        fuelAmount REAL NOT NULL,
        fuelCost REAL NOT NULL,
        odometerReading REAL NOT NULL,
        isFullTank INTEGER NOT NULL DEFAULT 1,
        refuelDate TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES $_vehicleTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_odo_vehicle ON $_odoEntriesTable(vehicleId)');
    await db.execute('CREATE INDEX idx_fuel_vehicle ON $_fuelEntriesTable(vehicleId)');
  }

  // Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_budgetTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          period TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $_goalsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL DEFAULT 0,
          deadline TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          ALTER TABLE $_tableName ADD COLUMN voiceNotePath TEXT
        ''');
      } catch (e) {
        // Column may already exist, ignore error
        print('voiceNotePath column might already exist: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          ALTER TABLE $_tableName ADD COLUMN imagePath TEXT
        ''');
      } catch (e) {
        // Column may already exist, ignore error
        print('imagePath column might already exist: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE $_vehicleTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            make TEXT NOT NULL,
            model TEXT NOT NULL,
            year INTEGER NOT NULL,
            registrationNumber TEXT NOT NULL,
            color TEXT,
            purchasePrice REAL,
            purchaseDate TEXT NOT NULL,
            currentMileage REAL,
            fuelType TEXT,
            vehicleType TEXT,
            imagePath TEXT,
            note TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      } catch (e) {
        print('vehicles table might already exist: $e');
      }
    }
    if (oldVersion < 6) {
      try {
        // Create ODO entries table
        await db.execute('''
          CREATE TABLE $_odoEntriesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleId INTEGER NOT NULL,
            odometerReading REAL NOT NULL,
            recordedAt TEXT NOT NULL,
            note TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (vehicleId) REFERENCES $_vehicleTable (id) ON DELETE CASCADE
          )
        ''');
        
        // Create fuel entries table
        await db.execute('''
          CREATE TABLE $_fuelEntriesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleId INTEGER NOT NULL,
            fuelAmount REAL NOT NULL,
            fuelCost REAL NOT NULL,
            odometerReading REAL NOT NULL,
            isFullTank INTEGER NOT NULL DEFAULT 1,
            refuelDate TEXT NOT NULL,
            note TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (vehicleId) REFERENCES $_vehicleTable (id) ON DELETE CASCADE
          )
        ''');
        
        // Create indexes for better query performance
        await db.execute('CREATE INDEX idx_odo_vehicle ON $_odoEntriesTable(vehicleId)');
        await db.execute('CREATE INDEX idx_fuel_vehicle ON $_fuelEntriesTable(vehicleId)');
      } catch (e) {
        print('ODO/Fuel entries tables might already exist: $e');
      }
    }
    if (oldVersion < 7) {
      try {
        // Add tankCapacity column to vehicles table
        await db.execute('''
          ALTER TABLE $_vehicleTable ADD COLUMN tankCapacity REAL
        ''');
      } catch (e) {
        print('tankCapacity column might already exist: $e');
      }
    }
    if (oldVersion < 8) {
      // Ensure odo_entries and fuel_entries tables exist
      // This handles cases where tables might have been missed in onCreate
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_odoEntriesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleId INTEGER NOT NULL,
            odometerReading REAL NOT NULL,
            recordedAt TEXT NOT NULL,
            note TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (vehicleId) REFERENCES $_vehicleTable (id) ON DELETE CASCADE
          )
        ''');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_fuelEntriesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleId INTEGER NOT NULL,
            fuelAmount REAL NOT NULL,
            fuelCost REAL NOT NULL,
            odometerReading REAL NOT NULL,
            isFullTank INTEGER NOT NULL DEFAULT 1,
            refuelDate TEXT NOT NULL,
            note TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (vehicleId) REFERENCES $_vehicleTable (id) ON DELETE CASCADE
          )
        ''');
        
        // Create indexes if they don't exist
        await db.execute('CREATE INDEX IF NOT EXISTS idx_odo_vehicle ON $_odoEntriesTable(vehicleId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fuel_vehicle ON $_fuelEntriesTable(vehicleId)');
      } catch (e) {
        print('Error creating odo/fuel tables in upgrade: $e');
      }
    }
    if (oldVersion < 9) {
      try {
        // Add fuelEfficiency column to vehicles table
        await db.execute('''
          ALTER TABLE $_vehicleTable ADD COLUMN fuelEfficiency REAL
        ''');
      } catch (e) {
        print('fuelEfficiency column might already exist: $e');
      }
    }
  }

  // Insert an expense into the database
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      _tableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all expenses from the database
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC', // Most recent first
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Update an existing expense
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense by id
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Optional: Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Optional: Get expenses within a date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Optional: Get total expenses
  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_tableName',
    );
    return result[0]['total'] as double? ?? 0.0;
  }

  // Optional: Clear all expenses (useful for testing)
  Future<void> clearAllExpenses() async {
    final db = await database;
    await db.delete(_tableName);
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ========== Budget Methods ==========

  // Insert a budget
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert(
      _budgetTable,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all budgets
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _budgetTable,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // Get budget by category
  Future<Budget?> getBudgetByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _budgetTable,
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // Update a budget
  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      _budgetTable,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // Delete a budget
  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete(_budgetTable, where: 'id = ?', whereArgs: [id]);
  }

  // ========== Saving Goals Methods ==========

  // Insert a saving goal
  Future<int> insertGoal(SavingGoal goal) async {
    final db = await database;
    return await db.insert(
      _goalsTable,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all saving goals
  Future<List<SavingGoal>> getGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _goalsTable,
      orderBy: 'deadline ASC',
    );

    return List.generate(maps.length, (i) {
      return SavingGoal.fromMap(maps[i]);
    });
  }

  // Update a saving goal
  Future<int> updateGoal(SavingGoal goal) async {
    final db = await database;
    return await db.update(
      _goalsTable,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Delete a saving goal
  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(_goalsTable, where: 'id = ?', whereArgs: [id]);
  }

  // ========== Vehicle Methods ==========

  // Check if registration number already exists
  Future<bool> isRegistrationNumberExists(String registrationNumber, {int? excludeId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _vehicleTable,
      where: excludeId != null 
          ? 'registrationNumber = ? AND id != ?' 
          : 'registrationNumber = ?',
      whereArgs: excludeId != null 
          ? [registrationNumber, excludeId] 
          : [registrationNumber],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // Insert a vehicle
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    
    // Check for duplicate registration number only if it's not empty
    if (vehicle.registrationNumber.trim().isNotEmpty) {
      final exists = await isRegistrationNumberExists(vehicle.registrationNumber);
      if (exists) {
        throw Exception('A vehicle with registration number ${vehicle.registrationNumber} already exists');
      }
    }
    
    return await db.insert(
      _vehicleTable,
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Get all vehicles
  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _vehicleTable,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Vehicle.fromMap(maps[i]);
    });
  }

  // Get vehicle by ID
  Future<Vehicle?> getVehicleById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _vehicleTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  // Update a vehicle
  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    
    // Check for duplicate registration number only if it's not empty (excluding current vehicle)
    if (vehicle.registrationNumber.trim().isNotEmpty) {
      final exists = await isRegistrationNumberExists(
        vehicle.registrationNumber, 
        excludeId: vehicle.id,
      );
      if (exists) {
        throw Exception('A vehicle with registration number ${vehicle.registrationNumber} already exists');
      }
    }
    
    return await db.update(
      _vehicleTable,
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  // Delete a vehicle
  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete(_vehicleTable, where: 'id = ?', whereArgs: [id]);
  }

  // Get vehicles by type
  Future<List<Vehicle>> getVehiclesByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _vehicleTable,
      where: 'vehicleType = ?',
      whereArgs: [type],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Vehicle.fromMap(maps[i]);
    });
  }

  // ========== ODO Entry Methods ==========

  // Insert an ODO entry
  Future<int> insertOdoEntry(OdoEntry entry) async {
    final db = await database;
    return await db.insert(
      _odoEntriesTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all ODO entries for a vehicle
  Future<List<OdoEntry>> getOdoEntriesByVehicle(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _odoEntriesTable,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'recordedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return OdoEntry.fromMap(maps[i]);
    });
  }

  // Get latest ODO entry for a vehicle
  Future<OdoEntry?> getLatestOdoEntry(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _odoEntriesTable,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'recordedAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return OdoEntry.fromMap(maps.first);
  }

  // Update an ODO entry
  Future<int> updateOdoEntry(OdoEntry entry) async {
    final db = await database;
    return await db.update(
      _odoEntriesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete an ODO entry
  Future<int> deleteOdoEntry(int id) async {
    final db = await database;
    return await db.delete(_odoEntriesTable, where: 'id = ?', whereArgs: [id]);
  }

  // ========== Fuel Entry Methods ==========

  // Insert a fuel entry
  Future<int> insertFuelEntry(FuelEntry entry) async {
    final db = await database;
    return await db.insert(
      _fuelEntriesTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all fuel entries for a vehicle
  Future<List<FuelEntry>> getFuelEntriesByVehicle(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _fuelEntriesTable,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'refuelDate DESC',
    );

    return List.generate(maps.length, (i) {
      return FuelEntry.fromMap(maps[i]);
    });
  }

  // Get latest fuel entry for a vehicle
  Future<FuelEntry?> getLatestFuelEntry(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _fuelEntriesTable,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'refuelDate DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return FuelEntry.fromMap(maps.first);
  }

  // Update a fuel entry
  Future<int> updateFuelEntry(FuelEntry entry) async {
    final db = await database;
    return await db.update(
      _fuelEntriesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete a fuel entry
  Future<int> deleteFuelEntry(int id) async {
    final db = await database;
    return await db.delete(_fuelEntriesTable, where: 'id = ?', whereArgs: [id]);
  }

  // Get fuel entries between two dates
  Future<List<FuelEntry>> getFuelEntriesByDateRange(int vehicleId, DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _fuelEntriesTable,
      where: 'vehicleId = ? AND refuelDate BETWEEN ? AND ?',
      whereArgs: [vehicleId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'refuelDate DESC',
    );

    return List.generate(maps.length, (i) {
      return FuelEntry.fromMap(maps[i]);
    });
  }
}
