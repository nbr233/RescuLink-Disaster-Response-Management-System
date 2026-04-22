import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import 'dart:math';

// ─── Shelter Status ─────────────────────────────────────────────
enum ShelterStatus { available, crowded, overCrowded }

extension ShelterStatusExt on ShelterStatus {
  Color get color {
    switch (this) {
      case ShelterStatus.available:   return const Color(0xFF2E7D32);
      case ShelterStatus.crowded:     return const Color(0xFFF57F17);
      case ShelterStatus.overCrowded: return const Color(0xFFE53935);
    }
  }
  String get label {
    switch (this) {
      case ShelterStatus.available:   return 'Available';
      case ShelterStatus.crowded:     return 'Crowded';
      case ShelterStatus.overCrowded: return 'Over Crowded';
    }
  }
  IconData get icon {
    switch (this) {
      case ShelterStatus.available:   return Icons.check_circle;
      case ShelterStatus.crowded:     return Icons.people;
      case ShelterStatus.overCrowded: return Icons.warning_rounded;
    }
  }
  String get dbValue {
    switch (this) {
      case ShelterStatus.available:   return 'available';
      case ShelterStatus.crowded:     return 'crowded';
      case ShelterStatus.overCrowded: return 'overCrowded';
    }
  }

  static ShelterStatus fromString(String? s) {
    switch (s) {
      case 'crowded':     return ShelterStatus.crowded;
      case 'overCrowded': return ShelterStatus.overCrowded;
      default:            return ShelterStatus.available;
    }
  }
}

// ─── Shelter Model ───────────────────────────────────────────────
class Shelter {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final ShelterStatus status;
  double? distanceKm;

  Shelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.distanceKm,
  });

  factory Shelter.fromMap(String id, Map<String, dynamic> d) {
    return Shelter(
      id: id,
      name: d['name'] ?? 'Shelter',
      latitude: (d['latitude'] ?? 0).toDouble(),
      longitude: (d['longitude'] ?? 0).toDouble(),
      status: ShelterStatusExt.fromString(d['status']),
    );
  }
}

// ─── Dummy Shelters ───────────────────────────────────────────────
final List<Map<String, dynamic>> kDummyShelters = [
  {'name': "Cox's Bazar Cyclone Shelter", 'latitude': 21.4272, 'longitude': 92.0058, 'status': 'available'},
  {'name': 'Chittagong City Shelter',      'latitude': 22.3475, 'longitude': 91.8123, 'status': 'crowded'},
  {'name': 'Dhaka Emergency Center',       'latitude': 23.8103, 'longitude': 90.4125, 'status': 'available'},
  {'name': 'Khulna Cyclone Shelter',       'latitude': 22.8456, 'longitude': 89.5403, 'status': 'overCrowded'},
  {'name': 'Barisal Shelter Center',       'latitude': 22.7010, 'longitude': 90.3535, 'status': 'overCrowded'},
  {'name': 'Sylhet Flood Shelter',         'latitude': 24.8998, 'longitude': 91.8687, 'status': 'available'},
  {'name': 'Rajshahi Safe Zone',           'latitude': 24.3745, 'longitude': 88.6042, 'status': 'crowded'},
  {'name': 'Noakhali Cyclone Shelter',     'latitude': 22.8696, 'longitude': 91.1013, 'status': 'crowded'},
];

// ─── Map Screen ─────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<Shelter> _shelters = [];
  bool _loading = true;
  Shelter? _selectedShelter;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _seedSheltersIfNeeded();
    await _getCurrentLocation();
    _loadShelters();
  }

  Future<void> _seedSheltersIfNeeded() async {
    try {
      final existing = await DatabaseService().getSheltersOnce();
      if (existing.isEmpty) {
        for (final s in kDummyShelters) {
          await DatabaseService().addShelter(s);
        }
      }
    } catch (_) {}
  }

  void _loadShelters() {
    DatabaseService().shelters.listen((list) {
      if (!mounted) return;
      List<Shelter> shelters = list.map((m) => Shelter.fromMap(m['id'] ?? '', m)).toList();
      if (_currentPosition != null) {
        for (var s in shelters) {
          s.distanceKm = _calcDistance(_currentPosition!.latitude, _currentPosition!.longitude, s.latitude, s.longitude);
        }
        shelters.sort((a, b) => (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
      }
      setState(() { _shelters = shelters; _loading = false; });
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentPosition = pos);
          try { _mapController.move(LatLng(pos.latitude, pos.longitude), 7); } catch (_) {}
        }
      }
    } catch (_) {}
  }

  double _calcDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double d) => d * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Cyclone Shelters', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _legendItem(const Color(0xFF2E7D32), 'Avail.'),
              const SizedBox(width: 8),
              _legendItem(const Color(0xFFF57F17), 'Crowd'),
              const SizedBox(width: 8),
              _legendItem(const Color(0xFFE53935), 'Full'),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // ── Map ──────────────────────────────────
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.40,
          child: FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(23.8103, 90.4125),
              initialZoom: 6.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.resculink',
              ),
              if (_currentPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 38, height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.4), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              MarkerLayer(
                markers: _shelters.map((s) {
                  final col = s.status.color;
                  return Marker(
                    point: LatLng(s.latitude, s.longitude),
                    width: 36, height: 36,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedShelter = s);
                        _mapController.move(LatLng(s.latitude, s.longitude), 10);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: col.withOpacity(0.5), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.home_work, color: Colors.white, size: 18),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // ── Selected shelter popup ─────────────
        if (_selectedShelter != null)
          _buildPopup(_selectedShelter!),

        // ── List Header ───────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -1))]),
          child: Row(children: [
            const Icon(Icons.sort, color: Color(0xFFE53935), size: 16),
            const SizedBox(width: 6),
            Text('Sorted by distance from you', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
            const Spacer(),
            Text('${_shelters.length} shelters', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFE53935))),
          ]),
        ),

        // ── Shelter List ──────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  itemCount: _shelters.length,
                  itemBuilder: (_, i) => _shelterCard(_shelters[i], i),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: () async {
          await _getCurrentLocation();
        },
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade600)),
    ]);
  }

  Widget _buildPopup(Shelter s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: s.status.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.status.color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(s.status.icon, color: s.status.color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
          Text(s.status.label, style: GoogleFonts.poppins(fontSize: 11, color: s.status.color, fontWeight: FontWeight.w500)),
        ])),
        GestureDetector(
          onTap: () => setState(() => _selectedShelter = null),
          child: const Icon(Icons.close, size: 16, color: Colors.grey),
        ),
      ]),
    );
  }

  Widget _shelterCard(Shelter shelter, int index) {
    final status = shelter.status;
    final isNearest = index == 0 && _currentPosition != null;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedShelter = shelter);
        _mapController.move(LatLng(shelter.latitude, shelter.longitude), 11);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isNearest ? const Color(0xFFE53935).withOpacity(0.5) : Colors.grey.shade200, width: isNearest ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Icon with nearest badge
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: status.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.home_work, color: status.color, size: 24),
            ),
            if (isNearest)
              Positioned(
                top: -7, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(8)),
                  child: Text('NEAR', style: GoogleFonts.poppins(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          // Name + distance
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shelter.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
            const SizedBox(height: 3),
            if (shelter.distanceKm != null)
              Row(children: [
                const Icon(Icons.near_me, size: 12, color: Color(0xFF1565C0)),
                const SizedBox(width: 3),
                Text(
                  shelter.distanceKm! < 1
                      ? '${(shelter.distanceKm! * 1000).toStringAsFixed(0)} m away'
                      : '${shelter.distanceKm!.toStringAsFixed(1)} km away',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF1565C0), fontWeight: FontWeight.w500),
                ),
              ]),
          ])),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: status.color.withOpacity(0.35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(status.icon, color: status.color, size: 13),
              const SizedBox(width: 4),
              Text(status.label, style: GoogleFonts.poppins(fontSize: 11, color: status.color, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}
