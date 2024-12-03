import 'package:flutter/material.dart';
import '../features/animals/presentation/animals_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/appointment/presentation/appointments_screen.dart';

class AppRoutes {
  static const String animals = '/animals';
  static const String inventory = '/inventory';
  static const String appointments = '/appointments';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case animals:
        final role = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AnimalsScreen(role: role),
        );

      case inventory:
        return MaterialPageRoute(
          builder: (context) => const InventoryScreen(),
        );

      case appointments:
        final args = settings.arguments as Map<String, dynamic>?;

        // Validate arguments
        if (args == null ||
            !args.containsKey('userRole') ||
            !args.containsKey('currentUser') ||
            !args.containsKey('headVets')) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Invalid arguments for Appointments')),
            ),
          );
        }

        // Extract arguments
        final String userRole = args['userRole'] as String;
        final String currentUser = args['currentUser'] as String;
        final List<String> headVets = args['headVets'] as List<String>;

        return MaterialPageRoute(
          builder: (context) => AppointmentsScreen(
            userRole: userRole,
            currentUser: currentUser,
            headVets: headVets,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Unknown Route')),
          ),
        );
    }
  }
}
