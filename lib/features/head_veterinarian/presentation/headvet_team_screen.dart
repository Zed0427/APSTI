import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../themes.dart';
import '../../caretakers/presentation/caretaker_daily_tasks_screen.dart';

class HeadVetTeamScreen extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const HeadVetTeamScreen({
    super.key,
    required this.loggedInUser,
  });

  @override
  State<HeadVetTeamScreen> createState() => _HeadVetTeamScreenState();
}

class _HeadVetTeamScreenState extends State<HeadVetTeamScreen> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> caretakers = [];
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> assistantVets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch all users
      final usersSnapshot = await _database.child('users').get();
      if (usersSnapshot.exists) {
        final usersData = Map<String, dynamic>.from(usersSnapshot.value as Map);

        final caretakerList = <Map<String, dynamic>>[];
        final assistantVetList = <Map<String, dynamic>>[];

        usersData.forEach((key, value) {
          final userData = Map<String, dynamic>.from(value);
          if (userData['role']?.toString().startsWith('Caretaker') ?? false) {
            caretakerList.add({
              ...userData,
              'email': key,
            });
          } else if (userData['role'] == 'AssistantVet') {
            assistantVetList.add({
              ...userData,
              'email': key,
            });
          }
        });

        setState(() {
          caretakers = caretakerList;
          assistantVets = assistantVetList;
        });
      }

      // Fetch tasks
      final tasksSnapshot = await _database.child('dailyTasks').get();
      if (tasksSnapshot.exists) {
        final tasksData = Map<String, dynamic>.from(tasksSnapshot.value as Map);
        final tasksList = tasksData.entries
            .map((entry) => {
                  ...Map<String, dynamic>.from(entry.value),
                  'id': entry.key,
                })
            .toList();

        setState(() {
          tasks = tasksList;
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _calculateCaretakerProgress() {
    // Group tasks by caretaker
    final Map<String, List<Map<String, dynamic>>> tasksByCaretaker = {};

    for (final task in tasks) {
      final caretakerEmail = task['assignedTo'];
      tasksByCaretaker.putIfAbsent(caretakerEmail, () => []).add(task);
    }

    // Map roles to animal categories
    final roleToCategory = {
      'CaretakerA': 'Avian',
      'CaretakerB': 'Mammal',
      'CaretakerC': 'Reptile',
    };

    // Calculate progress for each caretaker
    return caretakers.map((caretaker) {
      final caretakerTasks = tasksByCaretaker[caretaker['email']] ?? [];
      final completedTasks =
          caretakerTasks.where((task) => task['status'] == 'Completed').length;
      final progress = caretakerTasks.isNotEmpty
          ? completedTasks / caretakerTasks.length
          : 0.0;

      return {
        ...caretaker,
        'progress': progress,
        'completedTasks': completedTasks,
        'totalTasks': caretakerTasks.length,
        'category': roleToCategory[caretaker['role']] ?? 'Unknown',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final caretakerProgress = _calculateCaretakerProgress();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBg,
        title: Text(
          'Team View',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caretakers',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: caretakerProgress.length,
                      itemBuilder: (context, index) {
                        final caretaker = caretakerProgress[index];
                        return _buildCaretakerCard(
                          context,
                          caretaker,
                          index,
                          widget.loggedInUser['role'],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available Assistant Vets',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  Expanded(
                    child: assistantVets.isEmpty
                        ? Center(
                            child: Text(
                              'No assistant vets available.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColors.textLight,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: assistantVets.length,
                            itemBuilder: (context, index) {
                              final vet = assistantVets[index];
                              return _buildAssistantVetCard(
                                  context, vet, index);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCaretakerCard(
    BuildContext context,
    Map<String, dynamic> caretaker,
    int index,
    String userRole,
  ) {
    final progress = caretaker['progress'];
    final completed = caretaker['completedTasks'];
    final total = caretaker['totalTasks'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.accent.withOpacity(0.2),
          child: Text(
            caretaker['role'].toString().substring(9, 10),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ),
        title: Text(
          caretaker['name'] ?? 'Unknown',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caretaker['category'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textLight.withOpacity(0.8),
              ),
            ),
            Text(
              'Progress: ${(progress * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            Text(
              '$completed / $total tasks completed',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textLight.withOpacity(0.8),
              ),
            ),
          ],
        ),
        trailing: Icon(
          progress == 1.0 ? Icons.check_circle : Icons.pending_actions,
          color: progress == 1.0 ? AppColors.success : AppColors.warning,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaretakerDailyTasksScreen(
                caretakerRole: caretaker['role'],
                email: widget.loggedInUser['email'],
                userRole: userRole,
                caretakerUserId: caretaker[
                    'email'], // Change this - we're passing the userId
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms);
  }

  Widget _buildAssistantVetCard(
      BuildContext context, Map<String, dynamic> vet, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.accent.withOpacity(0.2),
          child: const Icon(
            Icons.person,
            color: AppColors.accent,
          ),
        ),
        title: Text(
          vet['name'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
    ).animate().slideY(duration: 300.ms, delay: (index * 100).ms);
  }
}
