import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/sos_request.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RescuLink - Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Signal Management
            const Text('Manage Danger Signal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<int>(
              stream: DatabaseService().signalLevel,
              builder: (context, snapshot) {
                int currentSignal = snapshot.data ?? 1;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Current Danger Level: $currentSignal', 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: currentSignal > 8 ? Colors.red : Colors.orange)),
                        Slider(
                          value: currentSignal.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: currentSignal > 8 ? Colors.red : Colors.blue,
                          label: currentSignal.toString(),
                          onChanged: (val) {
                            DatabaseService().updateSignalLevel(val.toInt());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // SOS Requests
            const Text('Active SOS Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<SOSRequest>>(
              stream: DatabaseService().sosRequests,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No active requests.'),
                  ));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final request = snapshot.data![index];
                    return Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.warning, color: Colors.white)),
                        title: Text(request.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Lat: ${request.latitude.toStringAsFixed(4)}, Lng: ${request.longitude.toStringAsFixed(4)}\nTime: ${DateFormat('hh:mm a').format(request.timestamp)}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          onPressed: () => DatabaseService().resolveSOS(request.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
