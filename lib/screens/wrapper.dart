import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'user_dashboard.dart';
import 'admin_dashboard.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const LoginScreen();
    } else {
      return FutureBuilder<UserModel?>(
        future: AuthService().getUserData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data!.role == 'Admin') {
              return const AdminDashboard();
            } else {
              return const UserDashboard();
            }
          }
          return const LoginScreen();
        },
      );
    }
  }
}
