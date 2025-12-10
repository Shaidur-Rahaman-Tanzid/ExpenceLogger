import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle.dart';
import 'package:intl/intl.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleController _vehicleController = Get.find<VehicleController>();
  Vehicle? vehicle;

  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _registrationController;
  late TextEditingController _mileageController;
  late TextEditingController _tankCapacityController;

  DateTime? _purchaseDate;
  String? _selectedVehicleType;
  String? _selectedFuelType;

  final List<String> _vehicleTypes = ['Car', 'Motorcycle', 'Truck', 'SUV', 'Van', 'Bus', 'Other'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG', 'LPG'];

  @override
  void initState() {
    super.initState();
    vehicle = Get.arguments as Vehicle?;
    
    _makeController = TextEditingController(text: vehicle?.make ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _yearController = TextEditingController(text: vehicle?.year.toString() ?? '');
    _registrationController = TextEditingController(text: vehicle?.registrationNumber ?? '');
    _mileageController = TextEditingController(text: vehicle?.currentMileage?.toString() ?? '');
    _tankCapacityController = TextEditingController(text: vehicle?.tankCapacity?.toString() ?? '');
    
    _purchaseDate = vehicle?.purchaseDate;
    _selectedVehicleType = vehicle?.vehicleType;
    _selectedFuelType = vehicle?.fuelType;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _mileageController.dispose();
    _tankCapacityController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  IconData _getFuelIcon(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'electric': return Icons.electric_bolt;
      case 'hybrid': return Icons.power;
      default: return Icons.local_gas_station;
    }
  }

  Color _getFuelColor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'electric': return Colors.green;
      case 'hybrid': return Colors.blue;
      case 'diesel': return Colors.orange;
      default: return Colors.red;
    }
  }

  Future<void> _saveVehicle() async {
    print('🔵 Save vehicle called');
    
    // Prevent double-tap
    if (_vehicleController.isLoading.value) {
      print('⚠️ Already saving, ignoring duplicate call');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    if (_selectedFuelType == null) {
      print('❌ Fuel type not selected');
      Get.snackbar('Error', 'Please select fuel type', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_purchaseDate == null) {
      print('❌ Purchase date not selected');
      Get.snackbar('Error', 'Please select purchase date', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      print('🔵 Creating vehicle object...');
      final vehicleToSave = Vehicle(
        id: vehicle?.id,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        registrationNumber: _registrationController.text.trim(),
        color: null,
        purchasePrice: null,
        purchaseDate: _purchaseDate!,
        currentMileage: double.parse(_mileageController.text),
        fuelType: _selectedFuelType,
        vehicleType: _selectedVehicleType,
        tankCapacity: _tankCapacityController.text.isEmpty 
            ? null 
            : double.parse(_tankCapacityController.text),
        imagePath: vehicle?.imagePath,
        note: null,
        createdAt: vehicle?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      print('✅ Vehicle object created');

      bool success;
      if (vehicle == null) {
        print('🔵 Adding new vehicle...');
        success = await _vehicleController.addVehicle(vehicleToSave);
      } else {
        print('🔵 Updating existing vehicle...');
        success = await _vehicleController.updateVehicle(vehicleToSave);
      }

      print('🔵 Operation result: $success');
      if (success) {
        print('✅ Going back...');
        Navigator.of(context).pop(true); // Return true to indicate success
        print('✅ Navigator.pop() called');
      } else {
        print('❌ Operation failed');
        Get.snackbar(
          'Error',
          'Failed to save vehicle. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ Exception in _saveVehicle: $e');
      String errorMessage = 'An error occurred: $e';
      
      // Check if it's a duplicate registration error
      if (e.toString().contains('registration number')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = vehicle != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Vehicle' : 'Add Vehicle'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditMode ? 'Update Vehicle' : 'Add New Vehicle',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, Icons.info_outline, 'BASIC INFO'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(
                          controller: _makeController, label: 'Make *', hint: 'Toyota', icon: Icons.business,
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(
                          controller: _modelController, label: 'Model *', hint: 'Camry', icon: Icons.directions_car,
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(
                          controller: _yearController, label: 'Year *', hint: '2020', icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            final year = int.tryParse(v!);
                            if (year == null || year < 1900 || year > DateTime.now().year + 1) return 'Invalid';
                            return null;
                          },
                        )),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildTextField(
                          controller: _registrationController, label: 'Registration *', hint: 'ABC-1234', icon: Icons.confirmation_number,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, Icons.settings, 'DETAILS'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: _inputDecoration('Vehicle Type', Icons.category),
                      items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedVehicleType = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      decoration: _inputDecoration('Fuel Type *', Icons.local_gas_station),
                      items: _fuelTypes.map((f) => DropdownMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            Icon(_getFuelIcon(f), size: 18, color: _getFuelColor(f)),
                            const SizedBox(width: 8),
                            Text(f),
                          ],
                        ),
                      )).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) => setState(() => _selectedFuelType = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildTextField(
                          controller: _mileageController, label: 'Mileage *', hint: '0', icon: Icons.speed,
                          suffixText: 'km', keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            if (double.tryParse(v!) == null) return 'Invalid';
                            return null;
                          },
                        )),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildTextField(
                          controller: _tankCapacityController, label: 'Tank Capacity', hint: '0', icon: Icons.local_gas_station,
                          suffixText: 'L', keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null; // Optional field
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectPurchaseDate,
                      child: InputDecorator(
                        decoration: _inputDecoration('Purchase Date *', Icons.event),
                        child: Text(
                          _purchaseDate == null ? 'Select date' : DateFormat('MMM dd, yyyy').format(_purchaseDate!),
                          style: TextStyle(color: _purchaseDate == null ? Theme.of(context).hintColor : null),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _vehicleController.isLoading.value ? null : _saveVehicle,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _vehicleController.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle),
                                const SizedBox(width: 8),
                                Text(isEditMode ? 'UPDATE VEHICLE' : 'ADD VEHICLE',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ],
                            ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, size: 20),
        suffixText: suffixText,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
