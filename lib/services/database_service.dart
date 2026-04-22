import '../main.dart';
import '../models/sos_request.dart';

class DatabaseService {
  // Uses global rtdb with correct Asia region URL

  // --- SOS Requests ---
  Future<void> sendSOS(SOSRequest request) async {
    await rtdb.ref('sos_requests').push().set(request.toMap());
  }

  Stream<List<SOSRequest>> get sosRequests {
    return rtdb.ref('sos_requests').onValue.map((event) {
      if (event.snapshot.value == null) return <SOSRequest>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<SOSRequest> requests = [];
      data.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        if (map['resolved'] != true) {
          requests.add(SOSRequest.fromMap(key, map));
        }
      });
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return requests;
    }).asBroadcastStream();
  }

  Future<void> resolveSOS(String id) async {
    await rtdb.ref('sos_requests/$id').update({'resolved': true});
  }

  // --- Signal Level ---
  Stream<int> get signalLevel {
    return rtdb.ref('system_config/danger_signal/level').onValue.map((event) {
      if (event.snapshot.value == null) return 1;
      return (event.snapshot.value as num).toInt();
    }).asBroadcastStream();
  }

  Future<void> updateSignalLevel(int level) async {
    await rtdb.ref('system_config/danger_signal').set({'level': level});
  }

  // --- Broadcast Alerts ---
  Future<void> sendBroadcast(String message) async {
    await rtdb.ref('broadcasts').push().set({
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<Map<String, dynamic>>> get broadcasts {
    return rtdb.ref('broadcasts').limitToLast(10).onValue.map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<Map<String, dynamic>> items = [];
      data.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        map['id'] = key;
        items.add(map);
      });
      items.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return items;
    }).asBroadcastStream();
  }

  // --- Shelters ---
  Future<void> addShelter(Map<String, dynamic> shelter) async {
    await rtdb.ref('shelters').push().set(shelter);
  }

  Future<List<Map<String, dynamic>>> getSheltersOnce() async {
    final snap = await rtdb.ref('shelters').get();
    if (snap.value == null) return [];
    final data = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> items = [];
    data.forEach((key, value) {
      final map = Map<String, dynamic>.from(value as Map);
      map['id'] = key;
      items.add(map);
    });
    return items;
  }

  Future<void> deleteShelter(String id) async {
    await rtdb.ref('shelters/$id').remove();
  }

  Future<void> updateShelterStatus(String id, String status) async {
    await rtdb.ref('shelters/$id').update({'status': status});
  }

  Stream<List<Map<String, dynamic>>> get shelters {
    return rtdb.ref('shelters').onValue.map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<Map<String, dynamic>> items = [];
      data.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        map['id'] = key;
        items.add(map);
      });
      return items;
    }).asBroadcastStream();
  }
}
