import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../controllers/vehicle_details_controller.dart';
import '../services/currency_service.dart';
import 'add_odo_entry_screen.dart';
import 'add_fuel_entry_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late VehicleDetailsController controller;
  final CurrencyService _currencyService = Get.find<CurrencyService>();

  @override
  void initState() {
    super.initState();
    // Initialize controller with vehicle - use unique tag to avoid conflicts
    controller = Get.put(
      VehicleDetailsController(),
      tag: 'vehicle_${widget.vehicle.id}',
    );
    controller.initializeVehicle(widget.vehicle);
  }

  @override
  void dispose() {
    // Clean up controller when leaving screen
    Get.delete<VehicleDetailsController>(tag: 'vehicle_${widget.vehicle.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              '${controller.vehicle.value?.make ?? widget.vehicle.make} ${controller.vehicle.value?.model ?? widget.vehicle.model}',
            ),
          ),
          actions: [
            // Edit vehicle button
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Vehicle',
              onPressed: () => _editVehicle(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.speed), text: 'ODO Meter'),
              Tab(icon: Icon(Icons.local_gas_station), text: 'Fuel'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Vehicle stats card
            _buildStatsCard(controller),

            // Tabs content
            Expanded(
              child: TabBarView(
                children: [
                  _buildOdoTab(controller, context),
                  _buildFuelTab(controller, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to edit vehicle screen
  Future<void> _editVehicle(BuildContext context) async {
    final result = await Get.toNamed(
      '/add-vehicle',
      arguments: controller.vehicle.value,
    );

    // If vehicle was updated, refresh the data
    if (result == true) {
      await controller.refreshVehicle();
      await controller.fetchAllData();
    }
  }

  Widget _buildStatsCard(VehicleDetailsController controller) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Title
            Text(
              'Vehicle Statistics',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid using Wrap for better responsiveness
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.local_gas_station,
                  label: 'Avg Consumption',
                  value: controller.averageFuelConsumption.value > 0
                      ? '${controller.averageFuelConsumption.value.toStringAsFixed(1)} L/100km'
                      : 'N/A',
                ),
                _buildStatItem(
                  icon: Icons.water_drop,
                  label: 'Est. Fuel Level',
                  value: controller.fuelEntries.isNotEmpty
                      ? '${controller.estimatedFuelLevel.value.toStringAsFixed(1)} L'
                      : 'N/A',
                ),
                _buildStatItem(
                  icon: Icons.route,
                  label: 'Est. Range',
                  value:
                      controller.fuelEntries.isNotEmpty &&
                          controller.averageFuelConsumption.value > 0
                      ? '${controller.estimatedRange.value.toStringAsFixed(0)} km'
                      : 'N/A',
                ),
                _buildStatItem(
                  icon: Icons.speed,
                  label: 'Current ODO',
                  value:
                      '${controller.vehicle.value?.currentMileage?.toStringAsFixed(0) ?? '0'} km',
                ),
                _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'Total Fuel Cost',
                  value: controller.totalFuelCost.value > 0
                      ? '${_currencyService.selectedCurrencySymbol.value}${controller.totalFuelCost.value.toStringAsFixed(2)}'
                      : '${_currencyService.selectedCurrencySymbol.value}0.00',
                ),
                _buildStatItem(
                  icon: Icons.show_chart,
                  label: 'Avg Cost/L',
                  value: controller.averageCostPerLiter > 0
                      ? '${_currencyService.selectedCurrencySymbol.value}${controller.averageCostPerLiter.toStringAsFixed(2)}'
                      : '${_currencyService.selectedCurrencySymbol.value}0.00',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOdoTab(
    VehicleDetailsController controller,
    BuildContext context,
  ) {
    return Obx(() {
      if (controller.odoEntries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No ODO entries yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _addOdoEntry(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Add First Entry'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.odoEntries.length,
              itemBuilder: (context, index) {
                final entry = controller.odoEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.speed, color: Colors.blue.shade700),
                    ),
                    title: Text(
                      '${entry.odometerReading.toStringAsFixed(0)} km',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy').format(entry.recordedAt),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteOdoEntry(context, controller, entry.id!),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _addOdoEntry(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('ADD ODO ENTRY'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFuelTab(
    VehicleDetailsController controller,
    BuildContext context,
  ) {
    return Obx(() {
      if (controller.fuelEntries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_gas_station, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No fuel entries yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _addFuelEntry(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Add First Entry'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.fuelEntries.length,
              itemBuilder: (context, index) {
                final entry = controller.fuelEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(
                        Icons.local_gas_station,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      '${entry.fuelAmount.toStringAsFixed(1)} L',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cost: ${_currencyService.selectedCurrencySymbol.value}${entry.fuelCost.toStringAsFixed(2)}',
                        ),
                        Text(
                          'ODO: ${entry.odometerReading.toStringAsFixed(0)} km',
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(entry.refuelDate),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (entry.isFullTank)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Full',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteFuelEntry(context, controller, entry.id!),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _addFuelEntry(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('ADD FUEL ENTRY'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _addOdoEntry(BuildContext context, VehicleDetailsController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOdoEntryScreen(vehicleId: widget.vehicle.id!),
      ),
    ).then((_) => controller.fetchOdoEntries());
  }

  void _addFuelEntry(
    BuildContext context,
    VehicleDetailsController controller,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFuelEntryScreen(vehicleId: widget.vehicle.id!),
      ),
    ).then((_) => controller.fetchAllData());
  }

  void _deleteOdoEntry(
    BuildContext context,
    VehicleDetailsController controller,
    int id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ODO Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteOdoEntry(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteFuelEntry(
    BuildContext context,
    VehicleDetailsController controller,
    int id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fuel Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteFuelEntry(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
