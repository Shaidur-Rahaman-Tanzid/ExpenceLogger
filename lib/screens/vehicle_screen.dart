import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/personalization_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../widgets/app_drawer.dart';
import '../models/vehicle.dart';
import 'vehicle_details_screen.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PersonalizationController personalizationController =
        Get.find<PersonalizationController>();
    final VehicleController vehicleController = Get.find<VehicleController>();
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                personalizationController.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () => personalizationController.toggleDarkMode(
                !personalizationController.isDarkMode.value,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () => vehicleController.syncWithFirebase(),
          ),
        ],
      ),
      drawer: AppDrawer(scaffoldKey: scaffoldKey),
      body: Obx(() {
        if (vehicleController.isLoading.value &&
            vehicleController.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vehicleController.vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Vehicles',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first vehicle',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vehicleController.fetchVehicles(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicleController.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleController.vehicles[index];
              return VehicleCard(
                key: ValueKey(vehicle.id),
                vehicle: vehicle,
                onTap: () => _showVehicleDetails(context, vehicle),
                onDelete: () async {
                  await vehicleController.deleteVehicle(vehicle.id!);
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-vehicle'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(vehicle.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Vehicle'),
              content: Text(
                'Are you sure you want to delete ${vehicle.make} ${vehicle.model}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          await onDelete();
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 30,
            child: Icon(_getVehicleIcon(vehicle.vehicleType), size: 30),
          ),
          title: Text(
            '${vehicle.make} ${vehicle.model}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${vehicle.year} • ${vehicle.registrationNumber}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (vehicle.currentMileage != null)
                Text(
                  '${vehicle.currentMileage!.toStringAsFixed(0)} km',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (vehicle.vehicleType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.vehicleType!,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (vehicle.fuelType != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    vehicle.fuelType!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      case 'suv':
        return Icons.airport_shuttle;
      case 'van':
        return Icons.airport_shuttle;
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.directions_car_outlined;
    }
  }
}
