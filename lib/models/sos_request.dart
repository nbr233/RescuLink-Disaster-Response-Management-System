class SOSRequest {
  final String id;
  final String uid;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool resolved;
  final String disasterType;

  SOSRequest({
    this.id = '',
    required this.uid,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.resolved = false,
    this.disasterType = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'resolved': resolved,
      'disasterType': disasterType,
    };
  }

  factory SOSRequest.fromMap(String id, Map<String, dynamic> data) {
    return SOSRequest(
      id: id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      resolved: data['resolved'] ?? false,
      disasterType: data['disasterType'] ?? 'General',
    );
  }
}
