import 'package:albaypark/core/widgets/auth_wrapper.dart';
import 'package:albaypark/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.initialize();
  // Configure Firebase Storage (no need for await here)
  FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 3));

  runApp(const AnimalHealthCareApp());
}

class AnimalHealthCareApp extends StatelessWidget {
  const AnimalHealthCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Health Care',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const AuthWrapper(), // Check authentication state on startup
    );
  }
}
