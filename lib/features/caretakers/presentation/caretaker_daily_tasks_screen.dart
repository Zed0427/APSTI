// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../themes.dart';
import 'task_details_screen.dart';

class CaretakerDailyTasksScreen extends StatefulWidget {
  final String caretakerRole;
  final String email;
  final String? userRole;
  final String?
      caretakerUserId; // Change from caretakerEmail to caretakerUserId

  const CaretakerDailyTasksScreen({
    super.key,
    required this.caretakerRole,
    required this.email,
    this.userRole,
    this.caretakerUserId, // Update parameter name
  });

  @override
  State<CaretakerDailyTasksScreen> createState() =>
      _CaretakerDailyTasksScreenState();
}

class _CaretakerDailyTasksScreenState extends State<CaretakerDailyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> completedTasks = []; // Add this
  Map<String, dynamic> animals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTasksAndAnimals();
    initializeTaskReset();
    _fetchCompletedTasks(); // Add this
  }

  Future<void> _fetchCompletedTasks() async {
    try {
      // First get the userId like we did in _fetchTasksAndAnimals
      String? userIdToFilter = widget.caretakerUserId;

      // If no caretakerUserId (direct caretaker login), get userId from email
      if (userIdToFilter == null) {
        final usersSnapshot = await _database.child('users').get();
        if (usersSnapshot.exists) {
          final usersData =
              Map<String, dynamic>.from(usersSnapshot.value as Map);
          usersData.forEach((key, value) {
            if (value['email'] == widget.email) {
              userIdToFilter = key;
            }
          });
        }
      }

      debugPrint('Fetching completed tasks for userId: $userIdToFilter');

      final completedSnapshot =
          await _database.child('completedDailyTasks').get();
      if (completedSnapshot.exists && userIdToFilter != null) {
        final data = Map<String, dynamic>.from(completedSnapshot.value as Map);

        final fetchedCompletedTasks = data.entries
            .map((entry) => {
                  'id': entry.key,
                  ...Map<String, dynamic>.from(entry.value),
                })
            .where((task) => task['completedBy'] == userIdToFilter)
            .toList();

        debugPrint('Found ${fetchedCompletedTasks.length} completed tasks');

        setState(() {
          completedTasks = fetchedCompletedTasks;
        });
      }
    } catch (e) {
      debugPrint('Error fetching completed tasks: $e');
    }
  }

  void initializeTaskReset() {
    // Get current time
    final now = DateTime.now();

    // Calculate time until next 1:00 AM
    final nextReset = DateTime(
      now.year,
      now.month,
      now.hour >= 1 ? now.day + 1 : now.day,
      1, // 1 AM
      0, // 0 minutes
    );

    // Calculate duration until next reset
    final duration = nextReset.difference(now);

    // Schedule the reset
    Future.delayed(duration, () {
      resetDailyTasks();
      // Schedule next day's reset
      initializeTaskReset();
    });
  }

  Future<void> resetDailyTasks() async {
    try {
      final tasksSnapshot = await _database.child('dailyTasks').get();
      if (tasksSnapshot.exists) {
        final tasksData = Map<String, dynamic>.from(tasksSnapshot.value as Map);

        // Update each task to "In Progress"
        final batch = tasksData.entries.map((entry) {
          return _database
              .child('dailyTasks')
              .child(entry.key)
              .update({'status': 'In Progress'});
        });

        await Future.wait(batch);
        _fetchTasksAndAnimals(); // Refresh the UI
      }
    } catch (e) {
      debugPrint('Error resetting tasks: $e');
    }
  }

  Future<void> _fetchTasksAndAnimals() async {
    try {
      // If caretakerUserId is provided (from HeadVet view), use it directly
      String? userIdToFilter = widget.caretakerUserId;

      // If no caretakerUserId (direct caretaker login), get userId from email
      if (userIdToFilter == null) {
        final usersSnapshot = await _database.child('users').get();
        if (usersSnapshot.exists) {
          final usersData =
              Map<String, dynamic>.from(usersSnapshot.value as Map);
          usersData.forEach((key, value) {
            if (value['email'] == widget.email) {
              userIdToFilter = key;
            }
          });
        }
      }

      debugPrint('Filtering tasks for userId: $userIdToFilter');

      // Fetch tasks
      final tasksSnapshot = await _database.child('dailyTasks').get();
      if (tasksSnapshot.exists && userIdToFilter != null) {
        final tasksData = Map<String, dynamic>.from(tasksSnapshot.value as Map);

        debugPrint('All tasks: ${tasksData.toString()}'); // Debug print

        final filteredTasks = tasksData.entries
            .map((entry) {
              final taskData = Map<String, dynamic>.from(entry.value);
              final assignedTo = taskData['assignedTo']?.toString();

              debugPrint(
                  'Comparing task assignedTo: $assignedTo with userIdToFilter: $userIdToFilter');

              if (assignedTo == userIdToFilter) {
                return {
                  ...taskData,
                  'id': entry.key,
                };
              }
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        debugPrint('Filtered tasks count: ${filteredTasks.length}');

        setState(() {
          tasks = filteredTasks;
          isLoading = false;
        });
      } else {
        setState(() {
          tasks = [];
          isLoading = false;
        });
      }

      // Fetch animals for reference
      final animalsSnapshot = await _database.child('animals').get();
      if (animalsSnapshot.exists) {
        final animalsData =
            Map<String, dynamic>.from(animalsSnapshot.value as Map);
        setState(() {
          animals = animalsData;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tasks or animals: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _refreshTasks() {
    _fetchTasksAndAnimals();
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks =
        tasks.where((task) => task['status'] == 'Completed').length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.cardBg,
          title: Text(
            'Daily Tasks',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          centerTitle: true,
          actions: widget.userRole == 'HeadVet'
              ? [
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.accent),
                    onPressed: () => _showAddTaskDialog(
                      context,
                      _refreshTasks,
                      widget.email,
                      animals,
                      widget.caretakerRole,
                    ),
                  ),
                ]
              : null,
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // In Progress Tasks Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProgressIndicator(
                            progress, completedTasks, totalTasks),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildTaskList(false),
                        ),
                      ],
                    ),
                  ),
                  // Completed Tasks Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTaskList(true),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTaskList(bool showCompleted) {
    debugPrint('Current tasks: ${tasks.toString()}');

    final displayTasks = showCompleted
        ? completedTasks
        : tasks
            .where((task) =>
                task['status'] != 'Completed' && task['status'] != 'completed')
            .toList();

    debugPrint(
        'Display tasks (${showCompleted ? 'completed' : 'in progress'}): ${displayTasks.length}');

    if (displayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              showCompleted ? 'No completed tasks' : 'No tasks in progress',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayTasks.length,
      itemBuilder: (context, index) {
        final task = displayTasks[index];
        return showCompleted
            ? _buildCompletedTaskCard(task, index)
            : _buildTaskCard(context, task, index);
      },
    );
  }

  Widget _buildCompletedTaskCard(Map<String, dynamic> task, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task header with completion time
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task['taskTitle'] ?? 'Unknown Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            subtitle: Text(
              'Completed: ${DateTime.parse(task['completedAt']).toString().split('.')[0]}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            leading: const CircleAvatar(
              backgroundColor: AppColors.success,
              child: Icon(Icons.check, color: Colors.white),
            ),
          ),

          // Task image
          if (task['imageUrl'] != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(task['imageUrl']),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Task remarks
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remarks:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task['remarks'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: -0.2, duration: 400.ms, delay: (index * 100).ms);
  }

  void _showAddTaskDialog(
    BuildContext context,
    VoidCallback refreshTasks,
    String email,
    Map<String, dynamic> animals,
    String caretakerRole, // Add this parameter
  ) {
    // Filter animals based on caretaker role
    final filteredAnimals = animals.entries.where((entry) {
      final category = entry.value['category'] as String;
      switch (caretakerRole) {
        case 'CaretakerA':
          return category == 'Avian';
        case 'CaretakerB':
          return category == 'Mammal';
        case 'CaretakerC':
          return category == 'Reptile';
        default:
          return false;
      }
    }).toList();

    final TextEditingController taskController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final TextEditingController dueTimeController = TextEditingController();
    String? priorityLevel;
    String? selectedAnimal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Task',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task Title
                    TextField(
                      controller: taskController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task Details
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Task Details',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select Animal
                    Text(
                      'Select an Animal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (filteredAnimals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No animals available for this category',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: filteredAnimals.map((entry) {
                          return RadioListTile<String>(
                            title: Text(
                              entry.value['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                            ),
                            subtitle: Text(
                              'Category: ${entry.value['category']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                            value: entry.key,
                            groupValue: selectedAnimal,
                            onChanged: (value) {
                              setState(() {
                                selectedAnimal = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),

                    // Due Time
                    TextField(
                      controller: dueTimeController,
                      readOnly: true,
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            dueTimeController.text = pickedTime.format(context);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Due Time',
                        suffixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority Level Dropdown
                    Text(
                      'Priority Level',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: priorityLevel,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      hint: const Text('Select Priority'),
                      items: ['High', 'Medium', 'Low'].map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          priorityLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (taskController.text.isNotEmpty &&
                                detailsController.text.isNotEmpty &&
                                dueTimeController.text.isNotEmpty &&
                                priorityLevel != null &&
                                selectedAnimal != null) {
                              final newTask = {
                                'task': taskController.text,
                                'status': 'Pending',
                                'priority': priorityLevel,
                                'assignedTo': email,
                                'expectedCompletion': dueTimeController.text,
                                'details': detailsController.text,
                                'animals': [selectedAnimal], // Wrap as a list
                              };

                              // Add task to Firebase
                              await FirebaseDatabase.instance
                                  .ref('dailyTasks')
                                  .push()
                                  .set(newTask);

                              refreshTasks();
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task added successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please complete all fields.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save Task'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(double progress, int completed, int total) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: AppColors.accent.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            Column(
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '$completed / $total tasks',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          progress == 1.0
              ? 'Great job! All tasks completed! 🎉'
              : 'Keep going! Almost there!',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
      BuildContext context, Map<String, dynamic> task, int index) {
    final isCompleted = task['status'] == 'Completed';
    final priorityColor = _getPriorityColor(task['priority'] ?? 'Low');

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
          backgroundColor: priorityColor.withOpacity(0.2),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.pending_actions,
            color: isCompleted ? AppColors.success : AppColors.warning,
          ),
        ),
        title: Text(
          task['task'] ?? 'Unknown Task',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildPriorityBadge(task['priority'] ?? 'Low'),
                const SizedBox(width: 8),
                Text(
                  'Due: ${task['expectedCompletion']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textLight.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            Text(
              'Status: ${task['status']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isCompleted ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailsScreen(
                  task: task['task'] ?? 'Unknown Task',
                  details: task['details'] ?? 'No details available',
                  animals: List<String>.from(task['animals'] ?? []),
                  taskId: task['id'],
                  assignedTo: task['assignedTo'], // Add this line
                ),
              ),
            ).then((completed) {
              if (completed == true) {
                _refreshTasks();
              }
            });
          },
          child: Text(
            'View',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
      default:
        return AppColors.success;
    }
  }
}
