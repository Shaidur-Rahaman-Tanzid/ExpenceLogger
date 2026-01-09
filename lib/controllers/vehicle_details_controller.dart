import 'package:get/get.dart';
import '../models/vehicle.dart';
import '../models/odo_entry.dart';
import '../models/fuel_entry.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';
import 'expense_controller.dart';

class VehicleDetailsController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late final FirebaseService _firebaseService;
  
  // Observable variables
  final Rx<Vehicle?> vehicle = Rx<Vehicle?>(null);
  final RxList<OdoEntry> odoEntries = <OdoEntry>[].obs;
  final RxList<FuelEntry> fuelEntries = <FuelEntry>[].obs;
  final RxBool isLoading = false.obs;
  
  // Calculated values
  final RxDouble averageFuelConsumption = 0.0.obs; // liters per 100 km
  final RxDouble estimatedFuelLevel = 0.0.obs; // current fuel in liters
  final RxDouble estimatedRange = 0.0.obs; // km remaining
  final RxDouble totalFuelCost = 0.0.obs;
  final RxDouble totalFuelAdded = 0.0.obs;
  
  int get vehicleId => vehicle.value?.id ?? 0;

  @override
  void onInit() {
    super.onInit();
    _firebaseService = Get.find<FirebaseService>();
  }

  // Initialize with vehicle
  void initializeVehicle(Vehicle v) {
    vehicle.value = v;
    fetchAllData();
  }

  // Refresh vehicle data from database
  Future<void> refreshVehicle() async {
    if (vehicleId == 0) return;
    try {
      final updatedVehicle = await _dbHelper.getVehicleById(vehicleId);
      if (updatedVehicle != null) {
        vehicle.value = updatedVehicle;
      }
    } catch (e) {
      print('Error refreshing vehicle: $e');
    }
  }

  // Fetch all data
  Future<void> fetchAllData() async {
    await Future.wait([
      fetchOdoEntries(),
      fetchFuelEntries(),
    ]);
    calculateFuelStatistics();
  }

  // Fetch ODO entries
  Future<void> fetchOdoEntries() async {
    if (vehicleId == 0) return;
    
    try {
      isLoading.value = true;
      final entries = await _dbHelper.getOdoEntriesByVehicle(vehicleId);
      odoEntries.value = entries;
    } catch (e) {
      print('Error fetching ODO entries: $e');
      Get.snackbar('Error', 'Failed to load ODO entries');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch fuel entries
  Future<void> fetchFuelEntries() async {
    if (vehicleId == 0) return;
    
    try {
      isLoading.value = true;
      final entries = await _dbHelper.getFuelEntriesByVehicle(vehicleId);
      fuelEntries.value = entries;
    } catch (e) {
      print('Error fetching fuel entries: $e');
      Get.snackbar('Error', 'Failed to load fuel entries');
    } finally {
      isLoading.value = false;
    }
  }

  // Add ODO entry
  Future<bool> addOdoEntry(OdoEntry entry) async {
    try {
      isLoading.value = true;
      final id = await _dbHelper.insertOdoEntry(entry);
      
      if (id > 0) {
        final newEntry = entry.copyWith(id: id);
        await fetchOdoEntries();
        
        // Auto-sync to Firebase
        _firebaseService.autoSyncOdoEntry(vehicleId, newEntry.toMap());
        
        // Update vehicle's current mileage if this is the latest reading
        if (entry.odometerReading > (vehicle.value?.currentMileage ?? 0)) {
          final updatedVehicle = vehicle.value?.copyWith(currentMileage: entry.odometerReading);
          if (updatedVehicle != null) {
            await _dbHelper.updateVehicle(updatedVehicle);
            vehicle.value = updatedVehicle;
          }
        }
        
        // Recalculate fuel statistics with updated mileage
        calculateFuelStatistics();
        
        Get.snackbar('Success', 'ODO entry added successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding ODO entry: $e');
      Get.snackbar('Error', 'Failed to add ODO entry');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add fuel entry
  Future<bool> addFuelEntry(FuelEntry entry) async {
    try {
      isLoading.value = true;
      final id = await _dbHelper.insertFuelEntry(entry);
      
      if (id > 0) {
        final newEntry = entry.copyWith(id: id);
        await fetchFuelEntries();
        calculateFuelStatistics();
        
        // Auto-sync to Firebase
        _firebaseService.autoSyncFuelEntry(vehicleId, newEntry.toMap());
        
        // Update vehicle's current mileage if this is the latest reading
        if (entry.odometerReading > (vehicle.value?.currentMileage ?? 0)) {
          final updatedVehicle = vehicle.value?.copyWith(currentMileage: entry.odometerReading);
          if (updatedVehicle != null) {
            await _dbHelper.updateVehicle(updatedVehicle);
            vehicle.value = updatedVehicle;
          }
        }
        
        // Create expense entry for the fuel cost
        final vehicleName = vehicle.value?.make ?? 'Vehicle';
        final vehicleModel = vehicle.value?.model ?? '';
        final expense = Expense(
          title: 'Fuel - $vehicleName $vehicleModel',
          amount: entry.fuelCost,
          category: 'Transportation',
          date: entry.refuelDate,
          note: 'Fuel: ${entry.fuelAmount.toStringAsFixed(2)}L at ${entry.odometerReading.toStringAsFixed(0)}km${entry.note != null ? '\n${entry.note}' : ''}',
        );
        
        // Add expense to database using ExpenseController
        try {
          final expenseController = Get.find<ExpenseController>();
          await expenseController.addExpense(expense);
        } catch (e) {
          // If ExpenseController not found, add directly to database
          await _dbHelper.insertExpense(expense);
        }
        
        Get.snackbar('Success', 'Fuel entry and expense added successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding fuel entry: $e');
      Get.snackbar('Error', 'Failed to add fuel entry');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete ODO entry
  Future<bool> deleteOdoEntry(int id) async {
    try {
      isLoading.value = true;
      final result = await _dbHelper.deleteOdoEntry(id);
      
      if (result > 0) {
        // Auto-sync deletion to Firebase
        _firebaseService.autoSyncOdoEntry(vehicleId, {'id': id}, isDelete: true);
        
        await fetchOdoEntries();
        
        // Update vehicle's current mileage to latest remaining ODO entry or fuel entry
        double latestMileage = vehicle.value?.currentMileage ?? 0;
        
        if (odoEntries.isNotEmpty) {
          // Find the latest ODO reading
          final sortedOdo = List.from(odoEntries)..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
          latestMileage = sortedOdo.first.odometerReading;
        } else if (fuelEntries.isNotEmpty) {
          // If no ODO entries, use latest fuel entry ODO
          final sortedFuel = List.from(fuelEntries)..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
          latestMileage = sortedFuel.first.odometerReading;
        }
        
        // Update vehicle if mileage changed
        if (latestMileage != vehicle.value?.currentMileage) {
          final updatedVehicle = vehicle.value?.copyWith(currentMileage: latestMileage);
          if (updatedVehicle != null) {
            await _dbHelper.updateVehicle(updatedVehicle);
            vehicle.value = updatedVehicle;
          }
        }
        
        // Recalculate stats after deleting ODO entry
        calculateFuelStatistics();
        Get.snackbar('Success', 'ODO entry deleted');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting ODO entry: $e');
      Get.snackbar('Error', 'Failed to delete ODO entry');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete fuel entry
  Future<bool> deleteFuelEntry(int id) async {
    try {
      isLoading.value = true;
      
      // Get the fuel entry before deleting to find associated expense
      final fuelEntry = fuelEntries.firstWhereOrNull((entry) => entry.id == id);
      
      final result = await _dbHelper.deleteFuelEntry(id);
      
      if (result > 0) {
        // Auto-sync deletion to Firebase
        _firebaseService.autoSyncFuelEntry(vehicleId, {'id': id}, isDelete: true);
        
        // Delete associated expense if fuel entry was found
        if (fuelEntry != null) {
          try {
            // Find and delete the matching expense
            final expenses = await _dbHelper.getExpenses();
            final matchingExpense = expenses.firstWhereOrNull((expense) =>
                expense.amount == fuelEntry.fuelCost &&
                expense.date.year == fuelEntry.refuelDate.year &&
                expense.date.month == fuelEntry.refuelDate.month &&
                expense.date.day == fuelEntry.refuelDate.day &&
                expense.category == 'Transportation' &&
                expense.title.startsWith('Fuel -'));
            
            if (matchingExpense != null && matchingExpense.id != null) {
              await _dbHelper.deleteExpense(matchingExpense.id!);
              
              // Also update ExpenseController if available
              try {
                final expenseController = Get.find<ExpenseController>();
                await expenseController.fetchExpenses();
              } catch (e) {
                // ExpenseController not found, that's okay
              }
            }
          } catch (e) {
            print('Could not delete associated expense: $e');
          }
        }
        
        await fetchFuelEntries();
        calculateFuelStatistics();
        Get.snackbar('Success', 'Fuel entry and expense deleted');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting fuel entry: $e');
      Get.snackbar('Error', 'Failed to delete fuel entry');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Calculate fuel statistics and predictions
  void calculateFuelStatistics() {
    print('🔵 calculateFuelStatistics called');
    print('🔵 fuelEntries count: ${fuelEntries.length}');
    print('🔵 User-provided fuel efficiency: ${vehicle.value?.fuelEfficiency} km/L');
    
    if (fuelEntries.isEmpty) {
      print('⚠️ No fuel entries, resetting all stats');
      // Use user-provided fuel efficiency if available
      if (vehicle.value?.fuelEfficiency != null && vehicle.value!.fuelEfficiency! > 0) {
        // Convert km/L to L/100km
        averageFuelConsumption.value = 100 / vehicle.value!.fuelEfficiency!;
        print('✅ Using user-provided efficiency: ${averageFuelConsumption.value} L/100km');
      } else {
        averageFuelConsumption.value = 0.0;
      }
      estimatedFuelLevel.value = 0.0;
      estimatedRange.value = 0.0;
      totalFuelCost.value = 0.0;
      totalFuelAdded.value = 0.0;
      return;
    }

    // Sort fuel entries by date (oldest first)
    final sortedEntries = List<FuelEntry>.from(fuelEntries)
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));

    // Calculate total fuel cost and amount
    totalFuelCost.value = sortedEntries.fold(0.0, (sum, entry) => sum + entry.fuelCost);
    totalFuelAdded.value = sortedEntries.fold(0.0, (sum, entry) => sum + entry.fuelAmount);
    print('💰 Total cost: ${totalFuelCost.value}, Total fuel: ${totalFuelAdded.value}');

    // Calculate average fuel consumption (L/100km)
    // Method 1: Use at least 2 full tank entries (most accurate)
    final fullTankEntries = sortedEntries.where((e) => e.isFullTank).toList();
    print('⛽ Full tank entries: ${fullTankEntries.length}');
    
    if (fullTankEntries.length >= 2) {
      double totalDistance = 0.0;
      double totalFuel = 0.0;
      
      for (int i = 1; i < fullTankEntries.length; i++) {
        final distance = fullTankEntries[i].odometerReading - fullTankEntries[i - 1].odometerReading;
        final fuel = fullTankEntries[i].fuelAmount;
        
        print('📊 Entry $i: distance=$distance, fuel=$fuel');
        
        if (distance > 0) {
          totalDistance += distance;
          totalFuel += fuel;
        }
      }
      
      print('📈 Total distance: $totalDistance, Total fuel for calc: $totalFuel');
      
      if (totalDistance > 0) {
        averageFuelConsumption.value = (totalFuel / totalDistance) * 100;
        print('✅ Average consumption: ${averageFuelConsumption.value} L/100km');
      }
    } else if (sortedEntries.length >= 2) {
      // Method 2: Calculate from any two consecutive fuel entries (even if not full tank)
      print('⚠️ Using fallback: consecutive fuel entries');
      
      double totalDistance = 0.0;
      double totalFuel = 0.0;
      int validSegments = 0;
      
      for (int i = 1; i < sortedEntries.length; i++) {
        final distance = sortedEntries[i].odometerReading - sortedEntries[i - 1].odometerReading;
        final fuel = sortedEntries[i].fuelAmount;
        
        print('📊 Entry $i: distance=$distance, fuel=$fuel');
        
        // Only use if distance is reasonable (more than 0, less than 2000km between fills)
        if (distance > 0 && distance < 2000) {
          totalDistance += distance;
          totalFuel += fuel;
          validSegments++;
        }
      }
      
      print('� Total distance: $totalDistance, Total fuel for calc: $totalFuel, Valid segments: $validSegments');
      
      if (totalDistance > 0 && validSegments > 0) {
        averageFuelConsumption.value = (totalFuel / totalDistance) * 100;
        print('✅ Average consumption (from consecutive entries): ${averageFuelConsumption.value} L/100km');
      }
    } else if (sortedEntries.length == 1) {
      // Method 3: Single fuel entry - use current ODO vs fuel entry ODO
      print('⚠️ Single fuel entry - using current ODO');
      
      final fuelEntry = sortedEntries.first;
      final currentOdo = vehicle.value?.currentMileage ?? fuelEntry.odometerReading;
      final distanceTraveled = currentOdo - fuelEntry.odometerReading;
      
      print('📏 Fuel entry ODO: ${fuelEntry.odometerReading}, Current ODO: $currentOdo');
      print('📏 Distance traveled: $distanceTraveled km');
      
      // If vehicle has traveled at least 50km since refuel, we can estimate consumption
      if (distanceTraveled >= 50 && fuelEntry.isFullTank) {
        // Use tank capacity if available, otherwise use fuel amount
        final tankCapacity = vehicle.value?.tankCapacity ?? fuelEntry.fuelAmount;
        final estimatedFuelUsed = tankCapacity - (tankCapacity * 0.2); // Assume 80% of tank used
        
        averageFuelConsumption.value = (estimatedFuelUsed / distanceTraveled) * 100;
        print('✅ Estimated consumption (from single full tank): ${averageFuelConsumption.value} L/100km');
      } else if (vehicle.value?.fuelEfficiency != null && vehicle.value!.fuelEfficiency! > 0) {
        // Use user-provided fuel efficiency as fallback
        averageFuelConsumption.value = 100 / vehicle.value!.fuelEfficiency!;
        print('✅ Using user-provided efficiency: ${averageFuelConsumption.value} L/100km (${vehicle.value!.fuelEfficiency} km/L)');
      }
    } else if (vehicle.value?.fuelEfficiency != null && vehicle.value!.fuelEfficiency! > 0) {
      // Fallback: Use user-provided fuel efficiency
      averageFuelConsumption.value = 100 / vehicle.value!.fuelEfficiency!;
      print('✅ Using user-provided efficiency as fallback: ${averageFuelConsumption.value} L/100km (${vehicle.value!.fuelEfficiency} km/L)');
    } else {
      print('⚠️ Not enough data for consumption calculation');
    }

    // Estimate current fuel level and range
    if (sortedEntries.isNotEmpty) {
      final latestFuel = sortedEntries.last;
      final currentOdo = vehicle.value?.currentMileage ?? latestFuel.odometerReading;
      final distanceSinceLastFill = currentOdo - latestFuel.odometerReading;
      
      print('🚗 Current ODO: $currentOdo, Last fill ODO: ${latestFuel.odometerReading}');
      print('📏 Distance since last fill: $distanceSinceLastFill');
      
      if (distanceSinceLastFill >= 0) {
        if (averageFuelConsumption.value > 0) {
          // We have consumption data - calculate fuel consumed
          final fuelConsumed = (distanceSinceLastFill * averageFuelConsumption.value) / 100;
          print('⛽ Fuel consumed since last fill: $fuelConsumed L');
          
          // Estimate remaining fuel (assuming last entry was a full tank or known amount)
          double remainingFuel = latestFuel.fuelAmount - fuelConsumed;
          print('💧 Initial remaining fuel: $remainingFuel L');
          
          // Add any partial fills after the last full tank
          if (latestFuel.isFullTank) {
            for (var entry in sortedEntries.reversed) {
              if (entry.id == latestFuel.id) break;
              if (!entry.isFullTank) {
                remainingFuel += entry.fuelAmount;
              } else {
                break;
              }
            }
          }
          
          // Clamp remaining fuel to reasonable values
          remainingFuel = remainingFuel.clamp(0.0, 200.0); // Max 200L for safety
          estimatedFuelLevel.value = remainingFuel;
          print('✅ Estimated fuel level: ${estimatedFuelLevel.value} L');
          
          // Calculate estimated range using km/L conversion
          // Formula: Range (km) = Fuel (L) × (100 / L/100km) = Fuel (L) × km/L
          // Since averageFuelConsumption is in L/100km, we need: Fuel / (L/100km / 100)
          if (remainingFuel > 0) {
            final kmPerLiter = 100 / averageFuelConsumption.value;
            estimatedRange.value = remainingFuel * kmPerLiter;
            print('✅ Estimated range: ${estimatedRange.value} km (${remainingFuel}L × ${kmPerLiter.toStringAsFixed(2)} km/L)');
          } else {
            estimatedRange.value = 0.0;
            print('⚠️ No fuel remaining, range = 0');
          }
        } else {
          // No consumption data yet, just show the last fuel amount
          estimatedFuelLevel.value = latestFuel.fuelAmount;
          estimatedRange.value = 0.0;
          print('⚠️ No consumption data, showing last fuel amount: ${latestFuel.fuelAmount} L');
        }
      } else {
        // Current ODO is less than fuel entry ODO (data error)
        estimatedFuelLevel.value = latestFuel.fuelAmount;
        estimatedRange.value = 0.0;
        print('⚠️ ODO mismatch, showing last fuel amount');
      }
    }
    
    print('📊 Final stats - Consumption: ${averageFuelConsumption.value}, Fuel: ${estimatedFuelLevel.value}, Range: ${estimatedRange.value}');
  }

  // Get average cost per liter
  double get averageCostPerLiter {
    if (totalFuelAdded.value > 0) {
      return totalFuelCost.value / totalFuelAdded.value;
    }
    return 0.0;
  }

  // Get total distance covered (from fuel entries)
  double get totalDistanceCovered {
    if (fuelEntries.length < 2) return 0.0;
    
    final sorted = List<FuelEntry>.from(fuelEntries)
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));
    
    return sorted.last.odometerReading - sorted.first.odometerReading;
  }
}
