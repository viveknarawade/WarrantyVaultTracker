import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrantyvaulttracker/controllers/warranty_contoller.dart';
import 'package:warrantyvaulttracker/screens/login_screen.dart';
import 'package:warrantyvaulttracker/screens/register_screen.dart';
import 'package:warrantyvaulttracker/screens/splash_screen.dart';
import 'package:warrantyvaulttracker/services/auth_service.dart';
import 'package:warrantyvaulttracker/services/notifi_service.dart';

  import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
        apiKey: "AIzaSyCKHDksV5qkthHPMJFjJ_wXbkaGdiitoGI",
        appId: "1:1069059382730:android:e5603e53a65c9e7a17c333",
        messagingSenderId: "1069059382730",
        projectId: "warrantyvaulttracker"),
  );
  NotificationService().initNotification();
  tz.initializeTimeZones();
   runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WarrantyController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warranty Vault',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}
