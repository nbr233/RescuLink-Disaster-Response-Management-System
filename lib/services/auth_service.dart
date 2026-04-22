import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of user changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign up
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await rtdb.ref('users/${user.uid}').set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': role,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return e.message ?? 'Sign up failed.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Sign in
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        default:
          return e.message ?? 'Login failed.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async => await _auth.signOut();

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final snapshot = await rtdb.ref('users/$uid').get()
          .timeout(const Duration(seconds: 5));
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(data);
      }
    } catch (e) {
      // Timeout or DB error — return null so Wrapper defaults to UserDashboard
      return null;
    }
    return null;
  }
}
