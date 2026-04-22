import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/sos_request.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), shape: BoxShape.circle), child: const Icon(Icons.admin_panel_settings, color: Color(0xFFE53935), size: 18)),
          const SizedBox(width: 8),
          Text('Admin Panel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Color(0xFF757575)), onPressed: () => AuthService().signOut()),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53935),
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: const Color(0xFFE53935),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'Signal'),
            Tab(icon: Icon(Icons.sos, size: 18), text: 'SOS'),
            Tab(icon: Icon(Icons.campaign, size: 18), text: 'Alerts'),
            Tab(icon: Icon(Icons.home_work, size: 18), text: 'Shelters'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _signalTab(),
          _sosTab(),
          _alertsTab(),
          _shelterTab(),
        ],
      ),
    );
  }

  // ---- Signal Tab ----
  Widget _signalTab() {
    return StreamBuilder<int>(
      stream: DatabaseService().signalLevel,
      builder: (context, snapshot) {
        int signal = snapshot.data ?? 1;
        Color color = signal <= 3 ? const Color(0xFF2E7D32) : signal <= 6 ? const Color(0xFFF57F17) : const Color(0xFFE53935);
        String label = signal <= 3 ? 'Safe Zone' : signal <= 6 ? 'Caution' : signal <= 8 ? 'Danger' : 'EXTREME DANGER!';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                Text('Current Danger Level', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 8),
                Text('$signal', style: GoogleFonts.poppins(fontSize: 60, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
              ]),
            ),
            const SizedBox(height: 28),
            Text('Adjust Signal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF212121))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color, thumbColor: color, overlayColor: color.withOpacity(0.15),
                    inactiveTrackColor: Colors.grey.shade200, trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(value: signal.toDouble(), min: 1, max: 10, divisions: 9, label: '$signal',
                    onChanged: (v) => DatabaseService().updateSignalLevel(v.toInt())),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('1 (Safe)', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                  Text('10 (Max)', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            // Quick set buttons
            Row(children: [
              _signalBtn('Safe (1)', 1, const Color(0xFF2E7D32)),
              const SizedBox(width: 10),
              _signalBtn('Caution (5)', 5, const Color(0xFFF57F17)),
              const SizedBox(width: 10),
              _signalBtn('Danger (10)', 10, const Color(0xFFE53935)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _signalBtn(String label, int val, Color color) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => DatabaseService().updateSignalLevel(val),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _disasterBadge(String type) {
    Color color;
    IconData icon;
    switch (type) {
      case 'Flood': color = const Color(0xFF1565C0); icon = Icons.water; break;
      case 'Earthquake': color = const Color(0xFF6D4C41); icon = Icons.vibration; break;
      case 'Fire': color = const Color(0xFFBF360C); icon = Icons.local_fire_department; break;
      default: color = const Color(0xFFE53935); icon = Icons.sos;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Text(type, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ---- SOS Tab ----
  Widget _sosTab() {
    return StreamBuilder<List<SOSRequest>>(
      stream: DatabaseService().sosRequests,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 64),
            const SizedBox(height: 12),
            Text('All Clear!', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
            Text('No active SOS requests.', style: GoogleFonts.poppins(color: Colors.grey.shade500)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.length,
          itemBuilder: (ctx, i) {
            final req = snap.data![i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE53935).withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFEBEE), shape: BoxShape.circle), child: const Icon(Icons.person_pin_circle, color: Color(0xFFE53935), size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(req.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(DateFormat('hh:mm a · dd MMM').format(req.timestamp), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _disasterBadge(req.disasterType),
                    IconButton(icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 26), onPressed: () => DatabaseService().resolveSOS(req.id), tooltip: 'Mark Resolved'),
                  ]),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, color: Color(0xFFE53935), size: 16),
                  const SizedBox(width: 4),
                  Text('${req.latitude.toStringAsFixed(5)}, ${req.longitude.toStringAsFixed(5)}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.map_outlined, color: Color(0xFF1565C0), size: 16),
                    label: Text('View on Map', style: GoogleFonts.poppins(color: const Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.w500)),
                    onPressed: () => _openMap(req.latitude, req.longitude),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ---- Alerts Tab ----
  Widget _alertsTab() {
    final msgController = TextEditingController();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Broadcast Alert', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF212121))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: TextField(
            controller: msgController,
            maxLines: 3,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type your alert message here...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57F17),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              shadowColor: const Color(0xFFF57F17).withOpacity(0.3),
            ),
            icon: const Icon(Icons.campaign, size: 20),
            label: Text('Send Broadcast', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            onPressed: () async {
              if (msgController.text.trim().isNotEmpty) {
                await DatabaseService().sendBroadcast(msgController.text.trim());
                msgController.clear();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Broadcast sent!', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
          ),
        ),
        const SizedBox(height: 28),
        Text('Recent Broadcasts', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF212121))),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().broadcasts,
          builder: (ctx, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return Center(child: Text('No broadcasts yet.', style: GoogleFonts.poppins(color: Colors.grey.shade400)));
            }
            return ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: snap.data!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final item = snap.data![i];
                final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF57F17).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.campaign_outlined, color: Color(0xFFF57F17), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['message'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF212121))),
                      Text(DateFormat('hh:mm a · dd MMM').format(ts), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
                    ])),
                  ]),
                );
              },
            );
          },
        ),
      ]),
    );
  }

  // ──────────────────────────────────────
  // ---- Shelter Tab ----
  Widget _shelterTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().shelters,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(child: Text('No shelters found', style: GoogleFonts.poppins(color: Colors.grey.shade400)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.length,
          itemBuilder: (ctx, i) {
            final item = snap.data![i];
            final id = item['id'] ?? '';
            final name = item['name'] ?? 'Shelter';
            final currentStatus = item['status'] ?? 'available';
            return _shelterAdminCard(id, name, currentStatus);
          },
        );
      },
    );
  }

  Widget _shelterAdminCard(String id, String name, String currentStatus) {
    final statuses = [
      {'value': 'available',   'label': 'Available',    'color': const Color(0xFF2E7D32), 'icon': Icons.check_circle},
      {'value': 'crowded',     'label': 'Crowded',      'color': const Color(0xFFF57F17), 'icon': Icons.people},
      {'value': 'overCrowded', 'label': 'Over Crowded', 'color': const Color(0xFFE53935), 'icon': Icons.warning_rounded},
    ];

    final activeStatus = statuses.firstWhere((s) => s['value'] == currentStatus, orElse: () => statuses[0]);
    final activeColor = activeStatus['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: activeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.home_work, color: activeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14))),
          // Current status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: activeColor.withOpacity(0.3))),
            child: Text(activeStatus['label'] as String, style: GoogleFonts.poppins(fontSize: 10, color: activeColor, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        // Status Selector
        Row(children: statuses.map((s) {
          final isActive = s['value'] == currentStatus;
          final color = s['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => DatabaseService().updateShelterStatus(id, s['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? color : color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isActive ? color : color.withOpacity(0.25), width: isActive ? 2 : 1),
                ),
                child: Column(children: [
                  Icon(s['icon'] as IconData, color: isActive ? Colors.white : color, size: 18),
                  const SizedBox(height: 3),
                  Text(s['label'] as String, style: GoogleFonts.poppins(fontSize: 9, color: isActive ? Colors.white : color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ]),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }
}
