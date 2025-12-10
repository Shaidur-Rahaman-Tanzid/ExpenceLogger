import 'package:get/get.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';

class VehicleController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late final FirebaseService? _firebaseService;

  // Observable list of vehicles
  final RxList<Vehicle> vehicles = <Vehicle>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      _firebaseService = null;
      print('FirebaseService not available');
    }
    fetchVehicles();
  }

  // Fetch all vehicles from the database
  Future<void> fetchVehicles() async {
    try {
      isLoading.value = true;
      final vehicleList = await _dbHelper.getVehicles();
      vehicles.value = vehicleList;
    } catch (e) {
      print('Error fetching vehicles: $e');
      Get.snackbar(
        'Error',
        'Failed to load vehicles: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new vehicle
  Future<bool> addVehicle(Vehicle vehicle) async {
    try {
      isLoading.value = true;
      print('🚗 Adding vehicle: ${vehicle.make} ${vehicle.model}');
      final id = await _dbHelper.insertVehicle(vehicle);
      print('✅ Vehicle inserted with ID: $id');
      
      if (id > 0) {
        // Create a new vehicle with the generated ID
        final newVehicle = vehicle.copyWith(id: id);
        vehicles.insert(0, newVehicle); // Add to the beginning of the list
        print('✅ Vehicle added to list');
        
        // Auto-sync to Firebase (non-blocking)
        _firebaseService?.autoSyncVehicle(newVehicle);
        print('✅ Firebase sync initiated');
        
        Get.snackbar(
          'Success',
          'Vehicle added successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        print('✅ Returning true from addVehicle');
        return true;
      }
      print('❌ Insert failed, id was: $id');
      return false;
    } catch (e) {
      print('❌ Error adding vehicle: $e');
      Get.snackbar(
        'Error',
        'Failed to add vehicle: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      isLoading.value = true;
      final updatedVehicle = vehicle.copyWith(updatedAt: DateTime.now());
      final result = await _dbHelper.updateVehicle(updatedVehicle);
      
      if (result > 0) {
        // Update the vehicle in the list
        final index = vehicles.indexWhere((v) => v.id == vehicle.id);
        if (index != -1) {
          vehicles[index] = updatedVehicle;
        }
        
        // Auto-sync to Firebase
        _firebaseService?.autoSyncVehicle(updatedVehicle);
        
        Get.snackbar(
          'Success',
          'Vehicle updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating vehicle: $e');
      Get.snackbar(
        'Error',
        'Failed to update vehicle: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a vehicle
  Future<bool> deleteVehicle(int id) async {
    try {
      isLoading.value = true;
      
      // Get vehicle before deletion for Firebase sync
      final vehicle = await _dbHelper.getVehicleById(id);
      
      final result = await _dbHelper.deleteVehicle(id);
      
      if (result > 0) {
        vehicles.removeWhere((vehicle) => vehicle.id == id);
        
        // Auto-sync deletion to Firebase
        if (vehicle != null) {
          _firebaseService?.autoSyncVehicle(vehicle, isDelete: true);
        }
        
        Get.snackbar(
          'Success',
          'Vehicle deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting vehicle: $e');
      Get.snackbar(
        'Error',
        'Failed to delete vehicle: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get vehicle by ID
  Future<Vehicle?> getVehicleById(int id) async {
    try {
      return await _dbHelper.getVehicleById(id);
    } catch (e) {
      print('Error getting vehicle: $e');
      return null;
    }
  }

  // Get vehicles by type
  Future<List<Vehicle>> getVehiclesByType(String type) async {
    try {
      return await _dbHelper.getVehiclesByType(type);
    } catch (e) {
      print('Error getting vehicles by type: $e');
      return [];
    }
  }

  // Get total number of vehicles
  int get totalVehicles => vehicles.length;

  // Get vehicles by fuel type
  List<Vehicle> getVehiclesByFuelType(String fuelType) {
    return vehicles.where((v) => v.fuelType == fuelType).toList();
  }

  // Get total value of all vehicles
  double get totalVehiclesValue {
    return vehicles.fold(0.0, (sum, vehicle) => sum + (vehicle.purchasePrice ?? 0.0));
  }

  // Sync vehicles with Firebase
  Future<void> syncWithFirebase() async {
    if (_firebaseService == null) {
      Get.snackbar(
        'Info',
        'Firebase not available',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      final result = await _firebaseService!.syncVehicles();
      
      if (result['success']) {
        await fetchVehicles(); // Refresh local list
        Get.snackbar(
          'Success',
          'Synced: ${result['uploaded']} uploaded, ${result['downloaded']} downloaded',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error syncing vehicles: $e');
      Get.snackbar(
        'Error',
        'Failed to sync vehicles: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
