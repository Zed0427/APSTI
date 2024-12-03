import 'package:albaypark/features/appointment/presentation/appointments_done.dart';
import 'package:albaypark/features/head_veterinarian/presentation/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../themes.dart';

class DashboardContentScreen extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const DashboardContentScreen({
    super.key,
    required this.loggedInUser,
  });

  @override
  State<DashboardContentScreen> createState() => _DashboardContentScreenState();
}

class _DashboardContentScreenState extends State<DashboardContentScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> tasks = [];
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _animals = {};
  // State variables
  int approvedAppointments = 0;
  int totalAnimals = 0;
  int urgentCases = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> urgentCasesList = [];
  List<Map<String, dynamic>> pendingAppointmentsList = [];
  List<Map<String, dynamic>> assignedAnimalsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load overview data
      await _loadOverviewData();

      // Load role-specific data
      if (widget.loggedInUser['role'] == 'HeadVet') {
        await _loadHeadVetData();
      } else if (widget.loggedInUser['role'] == 'AssistantVet') {
        await _loadAssistantVetData();
      } else {
        await _loadCaretakerData();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadOverviewData() async {
    final appointmentsSnapshot = await _database.child('appointments').get();
    final animalsSnapshot = await _database.child('animals').get();

    if (appointmentsSnapshot.exists) {
      final appointmentsData =
          Map<String, dynamic>.from(appointmentsSnapshot.value as Map);
      approvedAppointments = appointmentsData.values
          .where((appointment) => appointment['status'] == 'approved')
          .length;
    }

    if (animalsSnapshot.exists) {
      final animalsData =
          Map<String, dynamic>.from(animalsSnapshot.value as Map);
      totalAnimals = animalsData.values
          .fold(0, (sum, animal) => sum + (animal['count'] as int? ?? 0));

      urgentCases = animalsData.values
          .where((animal) => animal['isUrgent'] == true)
          .length;
    }
  }

  Future<void> _loadHeadVetData() async {
    try {
      // Load animals marked as urgent (this part works fine)
      final urgentSnapshot = await _database
          .child('animals')
          .orderByChild('isUrgent')
          .equalTo(true)
          .get();

      if (urgentSnapshot.exists && urgentSnapshot.value != null) {
        final Map<dynamic, dynamic> data =
            urgentSnapshot.value as Map<dynamic, dynamic>;
        urgentCasesList = data.entries.map((entry) {
          return {
            'id': entry.key,
            'animalData': Map<String, dynamic>.from(entry.value as Map),
          };
        }).toList();
      }

      // Load pending appointments - let's fix this part
      try {
        final appointmentsSnapshot = await _database
            .child('appointments')
            .get(); // First get all appointments

        if (appointmentsSnapshot.exists && appointmentsSnapshot.value != null) {
          final Map<dynamic, dynamic> data =
              appointmentsSnapshot.value as Map<dynamic, dynamic>;

          // Filter pending appointments and map them
          final pendingAppointments = data.entries.where((entry) {
            final appointmentData = entry.value as Map<dynamic, dynamic>;
            return appointmentData['status'] == 'pending';
          });

          pendingAppointmentsList = await Future.wait(
            pendingAppointments.map((entry) async {
              final appointmentData =
                  Map<String, dynamic>.from(entry.value as Map);

              // Fetch assigned person details
              String? assignedPersonId =
                  appointmentData['assignedPerson']?.toString();
              Map<String, dynamic> assignedPerson = {
                'name': 'Unknown',
                'role': 'Unknown'
              };

              if (assignedPersonId != null) {
                final personSnapshot =
                    await _database.child('users/$assignedPersonId').get();

                if (personSnapshot.exists && personSnapshot.value != null) {
                  assignedPerson =
                      Map<String, dynamic>.from(personSnapshot.value as Map);
                }
              }

              // Fetch animals details
              List<Map<String, dynamic>> animals = [];
              if (appointmentData['animals'] != null) {
                final animalIds =
                    List<dynamic>.from(appointmentData['animals']);
                animals = await Future.wait(
                  animalIds.map((animalId) async {
                    final animalSnapshot =
                        await _database.child('animals/$animalId').get();

                    if (animalSnapshot.exists && animalSnapshot.value != null) {
                      return Map<String, dynamic>.from(
                          animalSnapshot.value as Map);
                    }
                    return {'name': 'Unknown Animal'};
                  }),
                );
              }

              return {
                'id': entry.key,
                ...appointmentData,
                'assignedPerson': assignedPerson,
                'animals': animals,
              };
            }),
          );

          print(
              'Loaded ${pendingAppointmentsList.length} pending appointments'); // Debug print
        }
      } catch (e) {
        print('Error loading appointments: $e');
      }

      setState(() {}); // Refresh UI
    } catch (e) {
      print('Error in _loadHeadVetData: $e');
    }
  }

  Future<void> _loadAssistantVetData() async {
    // Similar to _loadHeadVetData but with today's appointments
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Load urgent cases (same as head vet)
    await _loadHeadVetData();

    // Load today's appointments
    final appointmentsSnapshot = await _database
        .child('appointments')
        .orderByChild('date')
        .equalTo(today)
        .get();

    if (appointmentsSnapshot.exists) {
      final data = Map<String, dynamic>.from(appointmentsSnapshot.value as Map);
      pendingAppointmentsList = data.entries
          .map((e) => {'id': e.key, ...e.value as Map<String, dynamic>})
          .toList();
    }
  }

  Future<void> _loadCaretakerData() async {
    try {
      // Load assigned animals
      final category = _getCategoryByRole(widget.loggedInUser['role']);
      final animalsSnapshot = await _database
          .child('animals')
          .orderByChild('category')
          .equalTo(category)
          .get();

      if (animalsSnapshot.exists && animalsSnapshot.value != null) {
        final Map<dynamic, dynamic> data =
            animalsSnapshot.value as Map<dynamic, dynamic>;
        assignedAnimalsList = data.entries
            .map((e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value as Map),
                })
            .toList();
      }

      // Fetch the Firebase UID for the caretaker
      String? userIdToFilter;
      final usersSnapshot = await _database.child('users').get();
      if (usersSnapshot.exists) {
        final usersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
        usersData.forEach((key, value) {
          if (value['email'] == widget.loggedInUser['email']) {
            userIdToFilter = key;
          }
        });
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
      setState(() {});
    } catch (e) {
      print('Error loading caretaker data: $e');
    }
  }

  List<Map<String, dynamic>> dailyTasks = [];

  // Your existing helper methods remain the same
  String _getCategoryByRole(String? role) {
    // Existing implementation
    return role == 'CaretakerA'
        ? 'Avian'
        : role == 'CaretakerB'
            ? 'Mammal'
            : role == 'CaretakerC'
                ? 'Reptile'
                : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Your existing profile section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  widget.loggedInUser['name'] ?? 'User',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats Overview (if not caretaker)
                  if (!['CaretakerA', 'CaretakerB', 'CaretakerC']
                      .contains(widget.loggedInUser['role']))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  final cards = [
                                    {
                                      'icon': Icons.calendar_today,
                                      'title': 'Approved',
                                      'value': approvedAppointments.toString(),
                                      'color': AppColors.accent,
                                    },
                                    {
                                      'icon': Icons.pets,
                                      'title': 'Animals',
                                      'value': totalAnimals.toString(),
                                      'color': AppColors.success,
                                    },
                                    {
                                      'icon': Icons.warning_outlined,
                                      'title': 'Urgent',
                                      'value': urgentCases.toString(),
                                      'color': AppColors.error,
                                    },
                                  ];

                                  final card = cards[index];
                                  return _buildOverviewCard(
                                    icon: card['icon'] as IconData,
                                    title: card['title'] as String,
                                    value: card['value'] as String,
                                    color: card['color'] as Color,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Role-specific content
                  if (widget.loggedInUser['role'] == 'HeadVet')
                    _buildHeadVetContent()
                  else if (widget.loggedInUser['role'] == 'AssistantVet')
                    _buildAssistantVetContent()
                  else
                    _buildCaretakerContent(widget.loggedInUser['role']),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeadVetContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionTitle('Urgent Cases')
                .animate()
                .fadeIn(delay: 700.ms)
                .slideX(),
            const SizedBox(height: 16),
            urgentCasesList.isNotEmpty
                ? Flexible(child: _buildUrgentCases(urgentCasesList))
                : _buildEmptyMessage('No urgent cases to display.'),
            const SizedBox(height: 24),
            _buildSectionTitle('Pending Appointments')
                .animate()
                .fadeIn(delay: 800.ms)
                .slideX(),
            const SizedBox(height: 16),
            pendingAppointmentsList.isNotEmpty
                ? Flexible(child: _buildAppointments(pendingAppointmentsList))
                : _buildEmptyMessage('No pending appointments.'),
            const SizedBox(height: 24),
            _buildQuickActions([
              {
                'title': 'Reports',
                'icon': Icons.summarize,
                'color': AppColors.warning
              },
              {
                'title': 'Appointments Done',
                'icon': Icons.check_circle,
                'color': AppColors.success,
              },
            ]),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAssistantVetContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionTitle('Urgent Cases')
                .animate()
                .fadeIn(delay: 700.ms)
                .slideX(),
            const SizedBox(height: 16),
            urgentCasesList.isNotEmpty
                ? Flexible(child: _buildUrgentCases(urgentCasesList))
                : _buildEmptyMessage('No urgent cases to display.'),
            const SizedBox(height: 24),
            _buildSectionTitle('Today\'s Appointments')
                .animate()
                .fadeIn(delay: 700.ms)
                .slideX(),
            const SizedBox(height: 16),
            pendingAppointmentsList.isNotEmpty
                ? Flexible(child: _buildAppointments(pendingAppointmentsList))
                : _buildEmptyMessage('No appointments for today.'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCaretakerContent(String role) {
    final completedTasks =
        tasks.where((task) => task['status'] == 'Completed').length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Assigned Animals')
                .animate()
                .fadeIn(delay: 700.ms)
                .slideX(),
            const SizedBox(height: 16),
            assignedAnimalsList.isNotEmpty
                ? _buildAssignedAnimals(assignedAnimalsList)
                : _buildEmptyMessage('No animals assigned to you.'),
            const SizedBox(height: 24),
            _buildSectionTitle('Daily Tasks')
                .animate()
                .fadeIn(delay: 800.ms)
                .slideX(),
            const SizedBox(height: 16),
            _buildTaskProgress(
                progress, completedTasks, totalTasks), // Pass daily tasks here
            const SizedBox(height: 24),
            _buildQuickActions([
              {
                'title': 'Submit Request',
                'icon': Icons.add_circle_outline,
                'color': AppColors.accent
              },
            ]),
          ],
        ),
      ),
    );
  }

  void _showRequestForm() async {
    final titleController = TextEditingController();
    String? selectedAnimal;
    String? selectedHeadVet;

    // Fetch animals based on the caretaker's role
    final caretakerRole = widget.loggedInUser['role'];
    String category = '';

    switch (caretakerRole) {
      case 'CaretakerA':
        category = 'Avian';
        break;
      case 'CaretakerB':
        category = 'Mammal';
        break;
      case 'CaretakerC':
        category = 'Reptile';
        break;
      default:
        category = '';
    }

    final animalsSnapshot = await _database
        .child('animals')
        .orderByChild('category')
        .equalTo(category)
        .get();

    final headVetsSnapshot = await _database
        .child('users')
        .orderByChild('role')
        .equalTo('HeadVet')
        .get();

    List<Map<String, dynamic>> animals = [];
    List<Map<String, dynamic>> headVets = [];

    if (animalsSnapshot.exists) {
      final animalsData =
          Map<String, dynamic>.from(animalsSnapshot.value as Map);
      animals = animalsData.entries
          .map((e) => {
                'id': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              })
          .toList();
    }

    if (headVetsSnapshot.exists) {
      final headVetsData =
          Map<String, dynamic>.from(headVetsSnapshot.value as Map);
      headVets = headVetsData.entries
          .map((e) => {
                'id': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              })
          .toList();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Submit Request',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAnimal,
                  decoration: InputDecoration(
                    labelText: 'Select Animal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: animals.map((animal) {
                    return DropdownMenuItem<String>(
                      value: animal['id'],
                      child: Text(animal['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAnimal = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedHeadVet,
                  decoration: InputDecoration(
                    labelText: 'Select Head Vet',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: headVets.map((headVet) {
                    return DropdownMenuItem<String>(
                      value: headVet['id'],
                      child: Text(headVet['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedHeadVet = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                await _submitRequest(
                  title: titleController.text,
                  animalId: selectedAnimal!,
                  headVetId: selectedHeadVet!,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRequest({
    required String title,
    required String animalId,
    required String headVetId,
  }) async {
    try {
      final requestRef = _database.child('caretakerRequests').push();
      await requestRef.set({
        'title': title,
        'animalId': animalId,
        'headVetId': headVetId,
        'status': 'request',
        'timestamp': ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request submitted successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting request: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildQuickActions(List<Map<String, dynamic>> actions) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        return ElevatedButton.icon(
          icon: Icon(action['icon'] as IconData, size: 20),
          label: Text(
            action['title'] as String,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: action['color'] as Color,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (action['title'] == 'Submit Request') {
              _showRequestForm();
            } else if (action['title'] == 'Reports') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            } else if (action['title'] == 'Appointments Done') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentsDoneScreen(
                    users: _users,
                    animals: _animals,
                  ),
                ),
              );
            }
          },
        ).animate().scale(delay: (1400 + (index * 100)).ms);
      }).toList(),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildUrgentCases(List<Map<String, dynamic>> cases) {
    return CarouselSlider.builder(
      itemCount: cases.length,
      options: CarouselOptions(
        height: 190, // Increased height for better spacing
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayCurve: Curves.easeInOutCubic,
        enableInfiniteScroll: cases.length > 1,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.9,
      ),
      itemBuilder: (context, index, _) {
        final animalData =
            Map<String, dynamic>.from(cases[index]['animalData'] as Map);
        final urgencyColor = Color(0xFFFF6B6B); // Modern red color

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                urgencyColor.withOpacity(0.05),
                urgencyColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: urgencyColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: urgencyColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background pattern (subtle)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: urgencyColor.withOpacity(0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with urgency indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              color: urgencyColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animalData['name']?.toString() ??
                                      'Unknown Animal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3436),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  animalData['scientificName']?.toString() ??
                                      '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF636E72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'URGENT',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: urgencyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Info grid
                      Row(
                        children: [
                          _buildInfoItem(
                            Icons.local_hospital_outlined,
                            'Status',
                            animalData['status']?.toString() ?? 'Unknown',
                          ),
                          const SizedBox(width: 16),
                          _buildInfoItem(
                            Icons.location_on_outlined,
                            'Cage',
                            animalData['AreaCageNumber']?.toString() ??
                                'Unknown',
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Action button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideX();
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF636E72),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF636E72),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointments(List<Map<String, dynamic>> appointments) {
    print(
        'Building appointments with ${appointments.length} items'); // Debug print

    if (appointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        message: 'No pending appointments',
      );
    }

    return CarouselSlider.builder(
      itemCount: appointments.length,
      options: CarouselOptions(
        height: 160,
        enlargeCenterPage: true,
        autoPlay: false, // Disabled autoplay for testing
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: appointments.length > 1,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.8,
      ),
      itemBuilder: (context, index, _) {
        final appointment = appointments[index];
        print('Building appointment: ${appointment['title']}'); // Debug print
        final assignedPerson = appointment['assignedPerson'];
        final animals =
            List<Map<String, dynamic>>.from(appointment['animals'] ?? []);

        return Card(
          elevation: 0,
          color: AppColors.accent.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.accent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['title'] ?? 'Untitled',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Animals: ${animals.map((a) => a['name']).join(", ")}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(appointment['status'] ?? 'pending'),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${appointment['date']} ${appointment['time']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${assignedPerson['name']} (${assignedPerson['role']})',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().scale(delay: (1000 + (index * 100)).ms);
      },
    );
  }

  Widget _buildAssignedAnimals(List<Map<String, dynamic>> animals) {
    if (animals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pets,
        message: 'No animals assigned',
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: animals.length,
        itemBuilder: (context, index) {
          final animal = animals[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 0,
              color: AppColors.success.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.success.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            animal['name'] ?? 'Unknown Animal', // Default name
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Category: ${animal['category'] ?? 'Unknown'}', // Default category
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Count: ${animal['count'] ?? 0}', // Default count
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().scale(delay: (1100 + (index * 100)).ms);
        },
      ),
    );
  }

  Widget _buildTaskProgress(double progress, int completed, int total) {
    String progressMessage = 'Keep up the good work!';
    if (progress == 0) {
      progressMessage = 'Start your tasks for today!';
    } else if (progress == 1) {
      progressMessage = 'Great job! All tasks completed!';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progressMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                  maxLines: 2, // Allow two lines of text
                  overflow:
                      TextOverflow.ellipsis, // Add ellipsis if text overflows
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 1200.ms);
  }

  // Widget _buildQuickActions(List<Map<String, dynamic>> actions) {
  //   return Wrap(
  //     spacing: 12,
  //     runSpacing: 12,
  //     children: actions.asMap().entries.map((entry) {
  //       final index = entry.key;
  //       final action = entry.value;
  //       return ElevatedButton.icon(
  //         icon: Icon(action['icon'] as IconData, size: 20),
  //         label: Text(
  //           action['title'] as String,
  //           style: GoogleFonts.poppins(
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         style: ElevatedButton.styleFrom(
  //           foregroundColor: Colors.white,
  //           backgroundColor: action['color'] as Color,
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: 20,
  //             vertical: 12,
  //           ),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //         ),
  //         onPressed: () {
  //           if (action['title'] == 'Submit Request') {
  //             _showRequestForm();
  //           } else if (action['title'] == 'Reports') {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(builder: (context) => const ReportsScreen()),
  //             );
  //           } else if (action['title'] == 'Appointments Done') {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => AppointmentsDoneScreen(
  //                   users: _users,
  //                   animals: _animals,
  //                 ),
  //               ),
  //             );
  //           }
  //         },
  //       ).animate().scale(delay: (1400 + (index * 100)).ms);
  //     }).toList(),
  //   );
  // }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textLight.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

// Add this method to calculate task progress
  double _calculateTaskProgress(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed =
        tasks.where((task) => task['status'] == 'completed').length;
    return completed / tasks.length;
  }
}
