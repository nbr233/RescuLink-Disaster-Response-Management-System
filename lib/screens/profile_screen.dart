import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<UserModel?>(
              future: AuthService().getUserData(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
                }
                final userData = snapshot.data;
                final isAdmin = userData?.role == 'Admin';
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFEBEE),
                          border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3), width: 3),
                          boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.15), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: Center(
                          child: Text(
                            (userData?.name ?? 'U').substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFFE53935)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(userData?.name ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isAdmin ? const Color(0xFFE53935) : const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAdmin ? '🛡 Admin' : '👤 User',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 36),
                      _infoCard(Icons.email_outlined, 'Email', userData?.email ?? user.email ?? 'N/A'),
                      const SizedBox(height: 12),
                      _infoCard(Icons.badge_outlined, 'User ID', user.uid.substring(0, 16) + '...'),
                      const SizedBox(height: 12),
                      _infoCard(Icons.admin_panel_settings_outlined, 'Role', userData?.role ?? 'User'),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.logout, color: Color(0xFFE53935)),
                          label: Text('Sign Out', style: GoogleFonts.poppins(color: const Color(0xFFE53935), fontWeight: FontWeight.w600)),
                          onPressed: () async {
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
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await AuthService().signOut();
                              if (context.mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFFEBEE), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFFE53935), size: 20)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
        ]),
      ]),
    );
  }
}
