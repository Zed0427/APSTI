import 'package:albaypark/features/assistant_veterinarian/presentation/assistantvet_dashboard_screen.dart';
import 'package:albaypark/features/caretakers/presentation/caretaker_dashboard_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/head_veterinarian/presentation/headvet_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is logged in, navigate to the appropriate dashboard
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserData(user.uid), // Fetch user role and data
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData) {
                final userData = roleSnapshot.data!;
                final role = userData['role'] ?? 'Unknown';

                // Navigate to the appropriate dashboard based on role
                if (role == 'HeadVet') {
                  return HeadVetDashboardScreen(loggedInUser: userData);
                } else if (role == 'AssistantVet') {
                  return AssistantVetDashboardScreen(loggedInUser: userData);
                } else if (role.startsWith('Caretaker')) {
                  return CaretakerDashboardScreen(loggedInUser: userData);
                }
              }

              // If user role is not found, show an error
              return const Scaffold(
                body: Center(child: Text('User role not recognized')),
              );
            },
          );
        }

        // If the user is not logged in, show the login screen
        return const LoginScreen();
      },
    );
  }

  // Helper function to fetch user data from the database
  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    final ref = FirebaseDatabase.instance.ref('users/$uid');
    final event = await ref.once();
    final snapshot = event.snapshot;

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    throw Exception("User data not found");
  }
}
