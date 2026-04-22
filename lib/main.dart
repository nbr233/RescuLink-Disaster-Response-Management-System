import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/wrapper.dart';

// Global database reference - uses correct Asia region URL
late final FirebaseDatabase rtdb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA595VzUvTAB2pp9SMKfLB_dbB4k6LSxzE",
        appId: "1:998470502290:android:6cd6da631fd3f11a3ea34b",
        messagingSenderId: "998470502290",
        projectId: "resculink-67755",
        storageBucket: "resculink-67755.firebasestorage.app",
        databaseURL: "https://resculink-67755-default-rtdb.asia-southeast1.firebasedatabase.app",
      ),
    );
  } catch (e) {
    debugPrint("Firebase already initialized: $e");
  }

  // Initialize the global DB reference with the correct Asia region URL
  rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://resculink-67755-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'RescuLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF333333)),
            titleTextStyle: GoogleFonts.poppins(
              color: const Color(0xFF333333),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: const Wrapper(),
      ),
    );
  }
}
