import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/fuel_entry.dart';
import '../controllers/vehicle_details_controller.dart';

class AddFuelEntryScreen extends StatefulWidget {
  final int vehicleId;
  final FuelEntry? entry; // For editing

  const AddFuelEntryScreen({super.key, required this.vehicleId, this.entry});

  @override
  State<AddFuelEntryScreen> createState() => _AddFuelEntryScreenState();
}

class _AddFuelEntryScreenState extends State<AddFuelEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuelAmountController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _odometerController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _refuelDate;
  bool _isFullTank = true;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _fuelAmountController.text = widget.entry!.fuelAmount.toString();
      _fuelCostController.text = widget.entry!.fuelCost.toString();
      _odometerController.text = widget.entry!.odometerReading.toString();
      _noteController.text = widget.entry!.note ?? '';
      _refuelDate = widget.entry!.refuelDate;
      _isFullTank = widget.entry!.isFullTank;
    } else {
      _refuelDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _fuelAmountController.dispose();
    _fuelCostController.dispose();
    _odometerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VehicleDetailsController>(tag: 'vehicle_${widget.vehicleId}');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add Fuel Entry' : 'Edit Fuel Entry'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.orange.shade800],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      const Text(
                        'Fuel Refill Entry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Fuel amount
                TextFormField(
                  controller: _fuelAmountController,
                  decoration: InputDecoration(
                    labelText: 'Fuel Amount (Liters) *',
                    prefixIcon: const Icon(Icons.water_drop),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fuel amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    
                    // Check against tank capacity
                    final controller = Get.find<VehicleDetailsController>(tag: 'vehicle_${widget.vehicleId}');
                    final tankCapacity = controller.vehicle.value?.tankCapacity;
                    if (tankCapacity != null && amount > tankCapacity) {
                      return 'Fuel amount exceeds tank capacity (${tankCapacity.toStringAsFixed(1)}L)';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fuel cost
                TextFormField(
                  controller: _fuelCostController,
                  decoration: InputDecoration(
                    labelText: 'Total Cost (\$) *',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fuel cost';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost <= 0) {
                      return 'Please enter a valid cost';
                    }
                    return null;
                  },
                  onChanged: (value) => _calculatePricePerLiter(),
                ),
                const SizedBox(height: 16),

                // Price per liter display
                if (_fuelAmountController.text.isNotEmpty && _fuelCostController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Price per liter: \$${_getPricePerLiter()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Odometer reading
                TextFormField(
                  controller: _odometerController,
                  decoration: InputDecoration(
                    labelText: 'Odometer Reading (km) *',
                    prefixIcon: const Icon(Icons.speed),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter odometer reading';
                    }
                    final reading = double.tryParse(value);
                    if (reading == null || reading <= 0) {
                      return 'Please enter a valid reading';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full tank switch
                Card(
                  child: SwitchListTile(
                    title: const Text('Full Tank'),
                    subtitle: const Text('Was the tank filled completely?'),
                    value: _isFullTank,
                    onChanged: (value) => setState(() => _isFullTank = value),
                    secondary: Icon(
                      _isFullTank ? Icons.local_gas_station : Icons.local_gas_station_outlined,
                      color: _isFullTank ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _refuelDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _refuelDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Refuel Date *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _refuelDate == null
                          ? 'Select date'
                          : DateFormat('MMM dd, yyyy').format(_refuelDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _saveEntry(controller),
                    icon: const Icon(Icons.check),
                    label: Text(widget.entry == null ? 'ADD ENTRY' : 'UPDATE ENTRY'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPricePerLiter() {
    final amount = double.tryParse(_fuelAmountController.text);
    final cost = double.tryParse(_fuelCostController.text);
    if (amount != null && cost != null && amount > 0) {
      return (cost / amount).toStringAsFixed(2);
    }
    return '0.00';
  }

  void _calculatePricePerLiter() {
    setState(() {}); // Trigger rebuild to update price display
  }

  Future<void> _saveEntry(VehicleDetailsController controller) async {
    if (!_formKey.currentState!.validate() || _refuelDate == null) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    final entry = FuelEntry(
      id: widget.entry?.id,
      vehicleId: widget.vehicleId,
      fuelAmount: double.parse(_fuelAmountController.text),
      fuelCost: double.parse(_fuelCostController.text),
      odometerReading: double.parse(_odometerController.text),
      isFullTank: _isFullTank,
      refuelDate: _refuelDate!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    final success = await controller.addFuelEntry(entry);
    if (success) {
      Navigator.of(context).pop();
    }
  }
}
