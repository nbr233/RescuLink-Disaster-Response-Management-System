import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/sos_request.dart';
import '../widgets/pulse_animation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _sendingSOS = false;

  Future<void> _handleSOS(BuildContext context) async {
    setState(() => _sendingSOS = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userData = await AuthService().getUserData(user.uid);
          SOSRequest request = SOSRequest(
            uid: user.uid,
            name: userData?.name ?? 'Anonymous',
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
          );
          await DatabaseService().sendSOS(request);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SOS Request Sent Successfully!')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _sendingSOS = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: DatabaseService().signalLevel,
      builder: (context, snapshot) {
        int signalLevel = snapshot.data ?? 1;
        bool isDangerous = signalLevel > 8;

        return Scaffold(
          backgroundColor: isDangerous ? Colors.red.shade50 : Colors.white,
          appBar: AppBar(
            title: const Text('RescuLink - User'),
            backgroundColor: isDangerous ? Colors.red : Colors.white,
            foregroundColor: isDangerous ? Colors.white : Colors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => AuthService().signOut(),
              ),
            ],
          ),
          body: PulseAnimation(
            active: isDangerous,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Signal Alert
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDangerous ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Danger Signal Level',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          '$signalLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // SOS Button
                  GestureDetector(
                    onTap: _sendingSOS ? null : () => _handleSOS(context),
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Center(
                        child: _sendingSOS
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Map & Shelters
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('View Nearby Shelters'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Emergency Contacts
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Emergency Contacts',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildContactTile('Fire Service', '999', Icons.fire_truck),
                  _buildContactTile('Ambulance', '102', Icons.medical_services),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTile(String title, String number, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title),
        subtitle: Text(number),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () async {
            final Uri url = Uri.parse('tel:$number');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        ),
      ),
    );
  }
}
