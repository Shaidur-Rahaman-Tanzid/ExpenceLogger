import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/odo_entry.dart';
import '../controllers/vehicle_details_controller.dart';

class AddOdoEntryScreen extends StatefulWidget {
  final int vehicleId;
  final OdoEntry? entry; // For editing

  const AddOdoEntryScreen({super.key, required this.vehicleId, this.entry});

  @override
  State<AddOdoEntryScreen> createState() => _AddOdoEntryScreenState();
}

class _AddOdoEntryScreenState extends State<AddOdoEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _recordedDate;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _odometerController.text = widget.entry!.odometerReading.toString();
      _noteController.text = widget.entry!.note ?? '';
      _recordedDate = widget.entry!.recordedAt;
    } else {
      _recordedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VehicleDetailsController>(tag: 'vehicle_${widget.vehicleId}');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add ODO Entry' : 'Edit ODO Entry'),
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
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      const Text(
                        'ODO Meter Reading',
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

                // Date picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _recordedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _recordedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _recordedDate == null
                          ? 'Select date'
                          : DateFormat('MMM dd, yyyy').format(_recordedDate!),
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

  Future<void> _saveEntry(VehicleDetailsController controller) async {
    if (!_formKey.currentState!.validate() || _recordedDate == null) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    final entry = OdoEntry(
      id: widget.entry?.id,
      vehicleId: widget.vehicleId,
      odometerReading: double.parse(_odometerController.text),
      recordedAt: _recordedDate!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    final success = await controller.addOdoEntry(entry);
    if (success) {
      Navigator.of(context).pop();
    }
  }
}
