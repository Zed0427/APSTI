import 'package:flutter/material.dart';
import 'package:albaypark/features/head_veterinarian/presentation/create_report_screen.dart';
import 'package:albaypark/features/auth/presentation/profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic> loggedInUser;

  const CustomAppBar({
    super.key,
    required this.loggedInUser,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0, // No shadow for a cleaner look
      backgroundColor: Colors.white, // Fixed white background color
      foregroundColor: Colors.black, // Set text/icon color explicitly
      automaticallyImplyLeading: false, // Prevent unwanted leading widgets
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: loggedInUser),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
          child: CircleAvatar(
            radius: 28, // Larger profile avatar
            backgroundColor: Colors.grey.shade800, // Adjust as needed
            child: const Icon(Icons.person,
                size: 30, color: Colors.white), // Adjusted icon size
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.coronavirus, // Dangerous virus icon
              size: 28,
              color: Colors.red, // You can change the color if needed
            ),
            onPressed: () {
              // Check if the user has the role of 'headvet' or 'assistvet'
              if (loggedInUser['role'] == 'HeadVet' ||
                  loggedInUser['role'] == 'AssistantVet') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreateReportScreen(), // Navigate to the CreateReportScreen
                  ),
                );
              } else {
                // Show a snackbar indicating that the user does not have permission
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'You do not have permission to access this feature.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
