import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// import '../../Auth/registration.dart';

import 'Auth/login.dart';
import 'admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () async {

      User? user = FirebaseAuth.instance.currentUser;

      // 🔥 already logged in
      if (user != null) {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );

      }

      // 🔥 not logged in
      else {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );

      }

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Logo
            Image.asset(
              "assets/images/busslogo.png",
              width: 240,
              height: 240,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(
              color: Color(0xFFFFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}