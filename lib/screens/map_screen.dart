import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Position? _currentPosition;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(23.8103, 90.4125), // Dhaka
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shelters & Location')),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _controller = controller,
        myLocationEnabled: true,
        markers: {
          const Marker(
            markerId: MarkerId('shelter1'),
            position: LatLng(23.8203, 90.4225),
            infoWindow: InfoWindow(title: 'Shelter A', snippet: 'Capacity: 500'),
          ),
          const Marker(
            markerId: MarkerId('shelter2'),
            position: LatLng(23.7503, 90.3925),
            infoWindow: InfoWindow(title: 'Shelter B', snippet: 'Capacity: 300'),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
