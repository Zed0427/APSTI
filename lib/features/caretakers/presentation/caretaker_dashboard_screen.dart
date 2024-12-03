import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/animals/presentation/animals_screen.dart';
import 'caretaker_daily_tasks_screen.dart';
import '../../../shared/dashboard_content_screen.dart';

class CaretakerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const CaretakerDashboardScreen({super.key, required this.loggedInUser});

  @override
  State<CaretakerDashboardScreen> createState() =>
      _CaretakerDashboardScreenState();
}

class _CaretakerDashboardScreenState extends State<CaretakerDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Pass loggedInUser to DashboardContentScreen and CaretakerDailyTasksScreen
    _screens = [
      DashboardContentScreen(
        loggedInUser: widget.loggedInUser, // Provide loggedInUser here
      ),
      AnimalsScreen(
        role: widget.loggedInUser['role'],
      ),
      CaretakerDailyTasksScreen(
        caretakerRole: widget.loggedInUser['role'],
        email: widget.loggedInUser['email'], // Provide the email here
      ),
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
            icon: Icon(Icons.task),
            label: 'Daily Tasks',
          ),
        ],
      ),
    );
  }
}
