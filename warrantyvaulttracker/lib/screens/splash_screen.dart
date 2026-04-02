import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:warrantyvaulttracker/screens/dashboard_screen.dart';
import 'package:warrantyvaulttracker/screens/login_screen.dart';
import 'package:warrantyvaulttracker/services/user_session_data.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigation();
  }

    Future<void> navigation() async {
    await Future.delayed(const Duration(seconds: 3));

    await UserSessionData.getSessionData();

    if (!mounted) return;

    if (UserSessionData.isLogin == true) {
      log("dashboard navigation");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } else {
      log("login navigation");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1565C0), // Deep Blue
            Color(0xFF42A5F5), // Light Blue
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// APP LOGO
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Color(0xFF1565C0),
                ),
              ),

              const SizedBox(height: 30),

              /// APP NAME
              const Text(
                "Warranty Vault Tracker",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              /// TAGLINE
              const Text(
                "Secure • Track • Never Miss Expiry",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              /// LOADING INDICATOR
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


}
