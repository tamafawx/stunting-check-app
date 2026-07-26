import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'notifikasi_service.dart';

// Import Login Page
import 'login.dart';
import 'main_admin.dart';
import 'main_kader.dart';
import 'main_bidan.dart';
import 'main_orang_tua.dart';

// Run Application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotification();
  await initializeDateFormatting('id-ID', null);

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String role = prefs.getString('role') ?? '';
  final String userId = prefs.getString('userId') ?? '';
  final String fullName = prefs.getString('fullName') ?? '';

  Widget initialScreen = const Login();

  if (isLoggedIn) {
    if (role == 'admin') {
      initialScreen = MainAdmin(userId: userId, fullName: fullName);
    } else if (role == 'kader') {
      initialScreen = MainKader(userId: userId, fullName: fullName);
    } else if (role == 'bidan') {
      initialScreen = MainBidan(userId: userId, fullName: fullName);
    } else if (role == 'orang-tua') {
      initialScreen = MainOrangTua(userId: userId, fullName: fullName);
    }
  }

  runApp(PosyanduApp(initialScreen: initialScreen));
}

class PosyanduApp extends StatelessWidget {
  final Widget initialScreen;
  const PosyanduApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Stunting Checker (Posyandu)",
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),

      home: initialScreen,
    );
  }
}
