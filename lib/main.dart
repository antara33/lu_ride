
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lu_ride/screens/splash_screen.dart';
import 'package:lu_ride/screens/admin/admin_dashboard.dart';
// import 'package:lu_ride/Auth/splash_screen.dart';
import 'firebase_options.dart';

// screens
// import 'package:lu_ride/Admin/admin_dashboard.dart';
// import 'Admin/manage_routes_screen.dart';
// import 'Admin/analytics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LU Ride',

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      /// 🔥 START FROM ADMIN DASHBOARD
      home: const SplashScreen(),
    );
  }
}