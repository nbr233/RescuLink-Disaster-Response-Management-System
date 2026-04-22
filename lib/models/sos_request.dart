import 'package:cloud_firestore/cloud_firestore.dart';

class SOSRequest {
  final String id;
  final String uid;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool resolved;

  SOSRequest({
    this.id = '',
    required this.uid,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.resolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'resolved': resolved,
    };
  }

  factory SOSRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return SOSRequest(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      resolved: data['resolved'] ?? false,
    );
  }
}
