import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/animals/presentation/animals_screen.dart'; // Correct import
import '../../../features/inventory/presentation/inventory_screen.dart';
import '../../../features/appointment/presentation/appointments_screen.dart';
import '../../../shared/dashboard_content_screen.dart'; // Import dashboard content
import '../../../data/mock/mock_data.dart';

class AssistantVetDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const AssistantVetDashboardScreen({super.key, required this.loggedInUser});

  @override
  State<AssistantVetDashboardScreen> createState() =>
      _AssistantVetDashboardScreenState();
}

class _AssistantVetDashboardScreenState
    extends State<AssistantVetDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with required arguments
    _screens = [
      DashboardContentScreen(
        loggedInUser: widget.loggedInUser, // Pass the loggedInUser parameter
      ),
      const AnimalsScreen(role: 'AssistantVet'),
      AppointmentsScreen(
        userRole: 'assistvet',
        currentUser: widget.loggedInUser['email'],
        headVets: mockUsers
            .where((user) => user['role'] == 'HeadVet')
            .map((user) => user['email'] as String)
            .toList(),
      ),
      const InventoryScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        loggedInUser: widget.loggedInUser,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Animals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
        ],
      ),
    );
  }
}
