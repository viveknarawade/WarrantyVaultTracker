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
        apiKey: "AIzaSyD--plqy-8gvKFfZ-JQEQ5YmYxcNphPDbQ",
        appId: "1:357856242430:android:3ce6c9da68412321dbd3af",
        messagingSenderId: "357856242430",
        projectId: "warranty-vault-tracker"),
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
