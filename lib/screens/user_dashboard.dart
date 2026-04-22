import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../widgets/animations.dart';
import '../models/sos_request.dart';
import '../widgets/pulse_animation.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with TickerProviderStateMixin {
  bool _sendingSOS = false;
  bool _sosSent = false;
  String _disasterType = 'General'; // Flood / Earthquake / Fire / General
  WeatherData? _weather;
  bool _loadingWeather = true;
  Position? _currentPosition;

  final List<Map<String, dynamic>> _disasterTypes = [
    {'type': 'General',    'icon': Icons.sos,              'color': Color(0xFFE53935)},
    {'type': 'Flood',      'icon': Icons.water,             'color': Color(0xFF1565C0)},
    {'type': 'Earthquake', 'icon': Icons.vibration,         'color': Color(0xFF6D4C41)},
    {'type': 'Fire',       'icon': Icons.local_fire_department, 'color': Color(0xFFBF360C)},
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = pos);
        final weather = await WeatherService().getWeather(pos.latitude, pos.longitude);
        setState(() { _weather = weather; _loadingWeather = false; });
      } else {
        // Default to Dhaka if no permission
        final weather = await WeatherService().getWeather(23.8103, 90.4125);
        setState(() { _weather = weather; _loadingWeather = false; });
      }
    } catch (e) {
      setState(() => _loadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: DatabaseService().signalLevel,
      builder: (context, snapshot) {
        final signal = snapshot.data ?? 1;
        final isDanger = signal > 7;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle), child: const Icon(Icons.emergency_share, color: Color(0xFFE53935), size: 18)),
              const SizedBox(width: 8),
              Text('RescuLink', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Color(0xFF212121)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF212121)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) async {
                  if (val == 'signout') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: Text('Sign Out?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to sign out?', style: GoogleFonts.poppins(fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await AuthService().signOut();
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'signout',
                    child: Row(children: [
                      const Icon(Icons.logout, color: Color(0xFFE53935), size: 18),
                      const SizedBox(width: 10),
                      Text('Sign Out', style: GoogleFonts.poppins(color: const Color(0xFFE53935), fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ],
              ),
            ],

          ),
          body: PulseAnimation(
            active: isDanger,
            child: RefreshIndicator(
              color: const Color(0xFFE53935),
              onRefresh: _initLocation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Weather Card
                  FadeSlideIn(child: _buildWeatherCard()),
                  const SizedBox(height: 14),

                  // Signal Card
                  FadeSlideIn(delay: const Duration(milliseconds: 100), child: _buildSignalCard(signal, isDanger)),
                  const SizedBox(height: 14),

                  // Alert Banner
                  FadeSlideIn(delay: const Duration(milliseconds: 200), child: _buildAlertsBanner()),
                  const SizedBox(height: 14),


                  // News Feed
                  _buildNewsSection(),
                  const SizedBox(height: 20),

                  // Disaster Type Selector
                  _buildSectionTitle('Select Disaster Type', Icons.warning_amber_rounded),
                  const SizedBox(height: 10),
                  _buildDisasterSelector(),
                  const SizedBox(height: 20),

                  // SOS Button
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Center(child: ScalePulse(child: _buildSOSButton())),
                  ),
                  const SizedBox(height: 6),
                  Center(child: Text('Tap to send your location & disaster type', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400))),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildSectionTitle('Quick Actions', Icons.flash_on),
                  const SizedBox(height: 10),
                  Row(children: [
                    _quickAction(Icons.map_outlined, 'Shelters\n& Map', const Color(0xFF1565C0), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()))),
                    const SizedBox(width: 10),
                    _quickAction(Icons.local_fire_department, 'Fire\nService', const Color(0xFFBF360C), () => _call('999')),
                    const SizedBox(width: 10),
                    _quickAction(Icons.medical_services_outlined, 'Ambulance', const Color(0xFF2E7D32), () => _call('199')),
                    const SizedBox(width: 10),
                    _quickAction(Icons.local_police_outlined, 'Police', const Color(0xFF1A237E), () => _call('999')),
                  ]),
                  const SizedBox(height: 20),

                  // Emergency Contacts
                  _buildSectionTitle('Emergency Contacts', Icons.phone_in_talk),
                  const SizedBox(height: 10),
                  _contactCard('Fire Service', '999', Icons.local_fire_department, const Color(0xFFBF360C)),
                  _contactCard('Ambulance', '199', Icons.medical_services, const Color(0xFF2E7D32)),
                  _contactCard('Police', '999', Icons.local_police, const Color(0xFF1A237E)),
                  _contactCard('DGDR Hotline', '1090', Icons.support_agent, const Color(0xFF6A1B9A)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════ WEATHER CARD ══════════════════════
  Widget _buildWeatherCard() {
    if (_loadingWeather) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      );
    }
    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [const Icon(Icons.cloud_off, color: Colors.grey), const SizedBox(width: 10), Text('Weather unavailable', style: GoogleFonts.poppins(color: Colors.grey))]),
      );
    }
    final w = _weather!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(
          alignment: Alignment.topRight,
          child: Text('Weather Report', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
        ),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(w.icon, style: const TextStyle(fontSize: 52)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${w.temperature.toStringAsFixed(1)}°C', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text(w.description, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
        ]),
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _weatherStat(Icons.air, '${w.windspeed.toStringAsFixed(0)} km/h', 'Wind'),
          _weatherStat(Icons.water_drop_outlined, '${w.humidity.toStringAsFixed(0)}%', 'Humidity'),
          _weatherStat(Icons.thermostat, '${w.temperature.toStringAsFixed(0)}°', 'Feels Like'),
        ]),
      ]),
    );
  }

  Widget _weatherStat(IconData icon, String val, String label) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(val, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
    ]);
  }

  // ══════════════════════ SIGNAL CARD ══════════════════════
  Widget _buildSignalCard(int signal, bool isDanger) {
    final Color color = signal <= 3 ? const Color(0xFF2E7D32) : signal <= 6 ? const Color(0xFFF57F17) : const Color(0xFFE53935);
    final String label = signal <= 3 ? 'Safe Zone' : signal <= 6 ? 'Caution' : signal <= 8 ? 'Danger' : '⚠ Extreme Danger!';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Danger Signal', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text('Live from Admin', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400)),
        ])),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1), border: Border.all(color: color, width: 2)),
          child: Center(child: Text('$signal', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color))),
        ),
      ]),
    );
  }

  // ══════════════════════ ALERT BANNER ══════════════════════
  Widget _buildAlertsBanner() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().broadcasts,
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox();
        final latest = snap.data!.first;
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF57F17).withOpacity(0.4))),
          child: Row(children: [
            const Icon(Icons.campaign_outlined, color: Color(0xFFF57F17), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(latest['message'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF212121)))),
          ]),
        );
      },
    );
  }

  // ══════════════════════ NEWS SECTION ══════════════════════
  Widget _buildNewsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('News & Alerts', Icons.newspaper),
      const SizedBox(height: 10),
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().broadcasts,
        builder: (ctx, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text('No news at this time.', style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13)),
              ]),
            );
          }
          return Column(children: snap.data!.map((item) => _newsCard(item)).toList());
        },
      ),
    ]);
  }

  Widget _newsCard(Map<String, dynamic> item) {
    final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0);
    final now = DateTime.now();
    final diff = now.difference(ts);
    String timeAgo = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24 ? '${diff.inHours}h ago' : '${diff.inDays}d ago';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF8E1), shape: BoxShape.circle), child: const Icon(Icons.campaign, color: Color(0xFFF57F17), size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['message'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF212121))),
          const SizedBox(height: 4),
          Text(timeAgo, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400)),
        ])),
      ]),
    );
  }

  // ══════════════════════ DISASTER TYPE SELECTOR ══════════════════════
  Widget _buildDisasterSelector() {
    return Row(
      children: _disasterTypes.map((d) {
        final selected = _disasterType == d['type'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _disasterType = d['type']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? (d['color'] as Color).withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? d['color'] : Colors.grey.shade200, width: selected ? 2 : 1),
                boxShadow: selected ? [BoxShadow(color: (d['color'] as Color).withOpacity(0.2), blurRadius: 8)] : [],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(d['icon'], color: selected ? d['color'] : Colors.grey.shade400, size: 24),
                const SizedBox(height: 4),
                Text(d['type'], style: GoogleFonts.poppins(fontSize: 9, color: selected ? d['color'] : Colors.grey.shade500, fontWeight: selected ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════ SOS BUTTON ══════════════════════
  Widget _buildSOSButton() {
    final selectedDisaster = _disasterTypes.firstWhere((d) => d['type'] == _disasterType);
    final Color btnColor = _sosSent ? const Color(0xFF2E7D32) : (selectedDisaster['color'] as Color);
    return GestureDetector(
      onTap: _sendingSOS ? null : _handleSOS,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 155, height: 155,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: btnColor,
          boxShadow: [BoxShadow(color: btnColor.withOpacity(0.4), blurRadius: 28, spreadRadius: 6)],
        ),
        child: Center(
          child: _sendingSOS
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_sosSent ? Icons.check_circle : Icons.sos, color: Colors.white, size: 42),
                  Text(_sosSent ? 'SENT!' : 'SOS', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  Text(_disasterType, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 9)),
                ]),
        ),
      ),
    );
  }

  // ══════════════════════ HELPERS ══════════════════════
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFFE53935), size: 18),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
    ]);
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 9, color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _contactCard(String name, String number, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(number, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
        ])),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.08), shape: BoxShape.circle),
          child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.call, color: Color(0xFF1565C0), size: 18), onPressed: () => _call(number)),
        ),
      ]),
    );
  }

  Future<void> _handleSOS() async {
    setState(() => _sendingSOS = true);
    try {
      Position? pos = _currentPosition;
      if (pos == null) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          pos = await Geolocator.getCurrentPosition();
          setState(() => _currentPosition = pos);
        }
      }
      if (pos != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userData = await AuthService().getUserData(user.uid);
          await DatabaseService().sendSOS(SOSRequest(
            uid: user.uid,
            name: userData?.name ?? 'Unknown',
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: DateTime.now(),
            disasterType: _disasterType,
          ));
          setState(() => _sosSent = true);
          Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _sosSent = false); });
          if (mounted) _showSnack('✅ $_disasterType SOS Sent! Help is on the way!', const Color(0xFF2E7D32));
        }
      } else {
        _showSnack('Could not get location', const Color(0xFFE53935));
      }
    } catch (e) {
      _showSnack('Error: $e', const Color(0xFFE53935));
    }
    setState(() => _sendingSOS = false);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _call(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
