import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../services/location_service.dart';
import 'dart:async';

class NearbyStationsScreen extends StatefulWidget {
  const NearbyStationsScreen({super.key});

  @override
  State<NearbyStationsScreen> createState() => _NearbyStationsScreenState();
}

class _NearbyStationsScreenState extends State<NearbyStationsScreen> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  
  // Default location (will be replaced by user's location)
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(23.8103, 90.4125), // Dhaka, Bangladesh
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    final position = await _locationService.getCurrentPosition();
    
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      
      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
      
      // Add marker for current location
      _addCurrentLocationMarker(position);
      
      // In a real app, you would call Google Places API here to get nearby gas stations
      // For now, we'll add some sample stations for demonstration
      _addSampleGasStations(position);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _addCurrentLocationMarker(Position position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    });
  }

  void _addSampleGasStations(Position userPosition) {
    // Sample gas stations around user's location
    // In production, use Google Places API to get real gas stations
    final List<Map<String, dynamic>> sampleStations = [
      {
        'name': 'Padma Oil Pump',
        'lat': userPosition.latitude + 0.005,
        'lng': userPosition.longitude + 0.005,
        'distance': '500m',
      },
      {
        'name': 'Meghna Petroleum',
        'lat': userPosition.latitude - 0.008,
        'lng': userPosition.longitude + 0.003,
        'distance': '800m',
      },
      {
        'name': 'Jamuna Filling Station',
        'lat': userPosition.latitude + 0.010,
        'lng': userPosition.longitude - 0.007,
        'distance': '1.2km',
      },
      {
        'name': 'Shell Petrol Pump',
        'lat': userPosition.latitude - 0.012,
        'lng': userPosition.longitude - 0.004,
        'distance': '1.5km',
      },
    ];

    for (var i = 0; i < sampleStations.length; i++) {
      final station = sampleStations[i];
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('station_$i'),
            position: LatLng(station['lat'], station['lng']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: station['name'],
              snippet: '📍 ${station['distance']} away',
            ),
            onTap: () => _showStationDetails(station),
          ),
        );
      });
    }
  }

  void _showStationDetails(Map<String, dynamic> station) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station, color: Colors.red, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    station['name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.navigation, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Distance: ${station['distance']}'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // In production, open Google Maps navigation
                  Get.snackbar(
                    'Navigation',
                    'Opening Google Maps for directions...',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.directions),
                label: const Text('GET DIRECTIONS'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Gas Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Recenter',
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 15.0,
                    ),
                  ),
                );
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Legend at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text('Your Location'),
                        const SizedBox(width: 24),
                        Icon(Icons.location_on, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        const Text('Gas Station'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'Refresh Location',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
