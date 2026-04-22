import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sos_request.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send SOS
  Future<void> sendSOS(SOSRequest request) async {
    await _db.collection('sos_requests').add(request.toMap());
  }

  // Get SOS requests (for admin)
  Stream<List<SOSRequest>> get sosRequests {
    return _db
        .collection('sos_requests')
        .where('resolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SOSRequest.fromFirestore(doc)).toList());
  }

  // Get Signal Level
  Stream<int> get signalLevel {
    return _db
        .collection('system_config')
        .doc('danger_signal')
        .snapshots()
        .map((doc) => doc.exists ? (doc.data() as Map)['level'] ?? 1 : 1);
  }

  // Update Signal Level (for admin)
  Future<void> updateSignalLevel(int level) async {
    await _db.collection('system_config').doc('danger_signal').set({'level': level});
  }

  // Mark SOS as resolved
  Future<void> resolveSOS(String id) async {
    await _db.collection('sos_requests').doc(id).update({'resolved': true});
  }
}
