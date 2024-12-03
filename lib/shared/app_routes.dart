import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/head_veterinarian/presentation/headvet_dashboard_screen.dart';
import '../features/assistant_veterinarian/presentation/assistantvet_dashboard_screen.dart';
import '../features/caretakers/presentation/caretaker_dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String headVetDashboard = '/headVetDashboard';
  static const String assistantVetDashboard = '/assistantVetDashboard';
  static const String caretakerDashboard = '/caretakerDashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );

      case profile:
        final user = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(user: user),
        );

      case headVetDashboard:
        final user = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => HeadVetDashboardScreen(loggedInUser: user),
        );

      case assistantVetDashboard:
        final user = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => AssistantVetDashboardScreen(loggedInUser: user),
        );

      case caretakerDashboard:
        final user = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => CaretakerDashboardScreen(loggedInUser: user),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
    }
  }
}
