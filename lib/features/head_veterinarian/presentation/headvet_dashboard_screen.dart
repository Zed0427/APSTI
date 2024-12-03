import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/mock/mock_data.dart';
import '../../../features/animals/presentation/animals_screen.dart';
import '../../../features/inventory/presentation/inventory_screen.dart';
import '../../../features/appointment/presentation/appointments_screen.dart';
import '../../../features/head_veterinarian/presentation/headvet_team_screen.dart';
import '../../../shared/dashboard_content_screen.dart';

class HeadVetDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const HeadVetDashboardScreen({super.key, required this.loggedInUser});

  @override
  State<HeadVetDashboardScreen> createState() => _HeadVetDashboardScreenState();
}

class _HeadVetDashboardScreenState extends State<HeadVetDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens with required parameters
    _screens = [
      DashboardContentScreen(
        loggedInUser: widget.loggedInUser,
      ), // Pass user data
      const AnimalsScreen(role: 'HeadVet'),
      AppointmentsScreen(
        userRole: 'headvet',
        currentUser: widget.loggedInUser['email'],
        headVets: mockUsers
            .where((user) => user['role'] == 'HeadVet')
            .map((user) => user['email'] as String)
            .toList(),
      ),
      const InventoryScreen(),
      HeadVetTeamScreen(
        loggedInUser: widget.loggedInUser,
      ), // Pass user data
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
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Team',
          ),
        ],
      ),
    );
  }
}
