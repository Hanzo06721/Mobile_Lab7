import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _loading = false;
  String? _message;

  static const LatLng _defaultLocation = LatLng(10.8231, 106.6297);

  Future<void> _findMyLocation() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Hãy bật dịch vụ vị trí trên Android Emulator.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Ứng dụng chưa được cấp quyền vị trí.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị chặn. Hãy bật trong Settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() => _currentLocation = point);
      _mapController.move(point, 16);
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (_currentLocation != null)
        Marker(
          point: _currentLocation!,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 44,
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài tập 1 - Bản đồ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 12,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                // OpenStreetMap không cần Google Maps API key.
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bai_tap_1_android_map',
              ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              tooltip: 'Vị trí hiện tại',
              onPressed: _loading ? null : _findMyLocation,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          if (_message != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_message!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
