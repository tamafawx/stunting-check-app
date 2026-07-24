import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'notifikasi_service.dart';

// Import Login Page
import 'login.dart';

// Run Application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotification();
  await initializeDateFormatting('id-ID', null);
  runApp(const PosyanduApp());
}

class PosyanduApp extends StatelessWidget {
  const PosyanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Stunting Checker (Posyandu)",
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),

      home: const Login(),
    );
  }
}
