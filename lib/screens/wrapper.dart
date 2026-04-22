import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'user_dashboard.dart';
import 'admin_dashboard.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  String? _cachedRole;
  String? _cachedUid;
  bool _loadingRole = false;

  Future<void> _fetchRole(String uid) async {
    if (_loadingRole) return;
    setState(() => _loadingRole = true);
    try {
      final userData = await AuthService()
          .getUserData(uid)
          .timeout(const Duration(seconds: 6));
      if (mounted) {
        setState(() {
          _cachedRole = userData?.role ?? 'User';
          _cachedUid = uid;
          _loadingRole = false;
        });
      }
    } catch (_) {
      // Timeout or error — default to User dashboard immediately
      if (mounted) {
        setState(() {
          _cachedRole = 'User';
          _cachedUid = uid;
          _loadingRole = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Not logged in → Login screen
    if (user == null) {
      _cachedRole = null;
      _cachedUid = null;
      return const LoginScreen();
    }

    // Role already fetched for this user
    if (_cachedUid == user.uid && _cachedRole != null) {
      return _cachedRole == 'Admin' ? const AdminDashboard() : const UserDashboard();
    }

    // Need to fetch role
    if (_cachedUid != user.uid) {
      _cachedRole = null;
      _fetchRole(user.uid);
    }

    // Loading state
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.emergency_share, color: Color(0xFFE53935), size: 32),
          ),
          const SizedBox(height: 20),
          Text('RescuLink', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
          const SizedBox(height: 8),
          Text('Loading your dashboard...', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Color(0xFFE53935), strokeWidth: 2.5)),
        ]),
      ),
    );
  }
}
