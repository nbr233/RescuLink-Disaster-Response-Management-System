import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.emergency_share, color: Color(0xFFE53935), size: 42),
                    ),
                    const SizedBox(height: 16),
                    Text('RescuLink', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
                    Text('Disaster Response System', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text('Welcome Back', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF212121))),
              Text('Login to your account', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 28),

              _buildField(_emailController, 'Email Address', Icons.email_outlined, false),
              const SizedBox(height: 16),
              _buildField(_passwordController, 'Password', Icons.lock_outline, _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFFE53935).withOpacity(0.4),
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Login', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                      children: [TextSpan(text: 'Sign Up', style: GoogleFonts.poppins(color: const Color(0xFFE53935), fontWeight: FontWeight.w600))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool obscure, {Widget? suffix, TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF212121)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFFE53935), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    final error = await AuthService().signIn(email: _emailController.text.trim(), password: _passwordController.text.trim());
    setState(() => _loading = false);
    if (error != null && mounted) _showSnack(error);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
