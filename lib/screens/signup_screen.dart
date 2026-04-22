import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'User';
  bool _loading = false;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
              Text('Join RescuLink to stay safe', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 32),

              _buildField(_nameController, 'Full Name', Icons.person_outline, false),
              const SizedBox(height: 14),
              _buildField(_emailController, 'Email Address', Icons.email_outlined, false, type: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildField(_passwordController, 'Password (min. 6 chars)', Icons.lock_outline, _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 22),

              Text('Select Role', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF212121))),
              const SizedBox(height: 10),
              Row(
                children: [
                  _roleCard('User', Icons.person, 'I need help during disasters'),
                  const SizedBox(width: 12),
                  _roleCard('Admin', Icons.admin_panel_settings, 'I manage rescue operations'),
                ],
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
                    shadowColor: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Create Account', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                      children: [TextSpan(text: 'Login', style: GoogleFonts.poppins(color: const Color(0xFFE53935), fontWeight: FontWeight.w600))],
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

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, bool obscure, {Widget? suffix, TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 14),
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

  Widget _roleCard(String role, IconData icon, String subtitle) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEBEE) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFFE53935) : Colors.grey.shade200, width: selected ? 2 : 1),
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.15), blurRadius: 10, spreadRadius: 1)]
                : [BoxShadow(color: Colors.grey.shade100, blurRadius: 5)],
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFFE53935) : Colors.grey.shade400, size: 30),
              const SizedBox(height: 6),
              Text(role, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: selected ? const Color(0xFFE53935) : Colors.grey.shade700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade500), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _snack('Please fill all fields'); return;
    }
    if (_passwordController.text.length < 6) {
      _snack('Password must be at least 6 characters'); return;
    }
    setState(() => _loading = true);
    final error = await AuthService().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      role: _role,
    );
    setState(() => _loading = false);
    if (error != null && mounted) { _snack(error); } else if (mounted) { Navigator.pop(context); }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
