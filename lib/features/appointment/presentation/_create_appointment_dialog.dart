import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../themes.dart';

class CreateAppointmentDialog extends StatefulWidget {
  final DateTime date;
  final List<Map<String, dynamic>> existingAppointments;
  final String userRole; // User role: 'headvet' or 'assistvet'
  final String currentUser; // Current logged-in user
  final List<String> headVets; // Available head vets (if assistvet role)
  final Map<String, dynamic>? request; // Caretaker request details

  const CreateAppointmentDialog({
    super.key,
    required this.date,
    required this.existingAppointments,
    required this.userRole,
    required this.currentUser,
    required this.headVets,
    this.request,
  });

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  List<Map<String, dynamic>> animals = [];
  List<String> selectedCategories = [];
  List<String> selectedAnimals = []; // Store selected animal IDs
  String? selectedAppointmentType; // Store selected appointment type
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? assignedVet;

  // List of appointment types
  final List<String> appointmentTypes = [
    'Check up',
    'Vaccine',
    'Deworm',
    'Medical treatment',
    'Health monitoring',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'headvet') {
      assignedVet = widget.currentUser; // Automatically assign headvet
    }
    _fetchAnimals();

    // Pre-fill fields if request is provided
    if (widget.request != null) {
      selectedAppointmentType = widget.request!['title'];
      selectedAnimals = [widget.request!['animalId']];
      assignedVet = widget.request!['headVetId'];
      selectedDate = widget.date; // Use the provided date
    }
  }

  Future<void> _fetchAnimals() async {
    try {
      final ref = FirebaseDatabase.instance.ref('animals');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          animals = data.entries.map((entry) {
            final animal = Map<String, dynamic>.from(entry.value);
            return {'id': entry.key, ...animal};
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching animals: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter animals based on selected categories
    final animalsByCategory = animals.where((animal) {
      return selectedCategories.isEmpty ||
          selectedCategories.contains(animal['category']);
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Create Appointment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Appointment Type Dropdown or Title from Request
                      if (widget.request == null) ...[
                        _buildSectionTitle('Select Appointment Type'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedAppointmentType,
                          hint: Text(
                            'Select an appointment type',
                            style: GoogleFonts.poppins(
                              color: AppColors.textLight,
                            ),
                          ),
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: appointmentTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: AppColors.text,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => selectedAppointmentType = value),
                        ),
                      ] else ...[
                        _buildSectionTitle('Title'),
                        const SizedBox(height: 8),
                        Text(
                          widget.request!['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Date Picker
                      _buildSectionTitle('Select Date'),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            selectedDate?.toLocal().toString().split(' ')[0] ??
                                'Select Date',
                            style: GoogleFonts.poppins(
                              color: selectedDate == null
                                  ? AppColors.textLight
                                  : AppColors.text,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.calendar_today,
                            color: AppColors.accent,
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Picker
                      _buildSectionTitle('Select Time'),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            selectedTime?.format(context) ?? 'Select Time',
                            style: GoogleFonts.poppins(
                              color: selectedTime == null
                                  ? AppColors.textLight
                                  : AppColors.text,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.access_time,
                            color: AppColors.accent,
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                        ),
                      ),
                      const Divider(height: 32),

                      // Animals Section
                      if (widget.request != null) ...[
                        _buildSectionTitle('Animal'),
                        const SizedBox(height: 8),
                        Text(
                          animals.firstWhere((animal) =>
                              animal['id'] == selectedAnimals[0])['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.text,
                          ),
                        ),
                      ] else ...[
                        _buildSectionTitle('Select Categories'),
                        const SizedBox(height: 8),
                        _buildCategorySelection(),
                        if (selectedCategories.isNotEmpty) ...[
                          const Divider(height: 32),
                          _buildSectionTitle('Select Animals'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: animalsByCategory.map((animal) {
                              final isSelected =
                                  selectedAnimals.contains(animal['id']);
                              return FilterChip(
                                label: Text(animal['name']),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedAnimals.add(animal['id']);
                                    } else {
                                      selectedAnimals.remove(animal['id']);
                                    }
                                  });
                                },
                                selectedColor:
                                    AppColors.accent.withOpacity(0.2),
                                backgroundColor: AppColors.background,
                              );
                            }).toList(),
                          ),
                        ],
                      ],

                      // Vet Selection
                      if (widget.userRole == 'assistvet') ...[
                        const Divider(height: 32),
                        _buildSectionTitle('Assign Vet'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: assignedVet,
                          hint: Text(
                            'Select a head vet',
                            style: GoogleFonts.poppins(
                              color: AppColors.textLight,
                            ),
                          ),
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: widget.headVets.map((vet) {
                            return DropdownMenuItem<String>(
                              value: vet,
                              child: Text(
                                vet,
                                style: GoogleFonts.poppins(
                                  color: AppColors.text,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => assignedVet = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Save Button
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Save Appointment',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave() async {
    if (selectedDate == null ||
        selectedTime == null ||
        selectedAnimals.isEmpty ||
        (widget.userRole == 'assistvet' && assignedVet == null)) {
      _showError('Please fill in all fields.');
      return;
    }

    // Convert selectedTime to a formatted string for comparison
    final selectedTimeString = selectedTime!.format(context);

    // Query Firebase Realtime Database to check for existing appointments
    final ref = FirebaseDatabase.instance.ref('appointments');
    final snapshot = await ref
        .orderByChild('date')
        .equalTo(selectedDate!.toIso8601String().split('T')[0])
        .once();

    if (snapshot.snapshot.value != null) {
      final appointments =
          Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final isTimeTaken = appointments.values.any((appt) {
        final apptTimeString = appt['time'] as String;
        return apptTimeString == selectedTimeString;
      });

      if (isTimeTaken) {
        _showError('An appointment already exists at this time.');
        return;
      }
    }

    // Correct format for saving appointment
    final appointment = {
      'title': widget.request != null
          ? widget.request!['title']
          : selectedAppointmentType,
      'time': selectedTimeString,
      'animals': selectedAnimals, // This is already the array of animal IDs
      'assignedPerson': widget.userRole == 'headvet'
          ? widget.currentUser // User ID for headvet
          : assignedVet, // Selected vet's user ID
      'date': selectedDate!.toIso8601String().split('T')[0],
      'status': widget.userRole == 'headvet' ? 'approved' : 'pending',
    };

    Navigator.pop(context, appointment);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: ['Avian', 'Mammal', 'Reptile'].map((category) {
        return CheckboxListTile(
          activeColor: AppColors.accent,
          title: Text(
            category,
            style: GoogleFonts.poppins(color: AppColors.text),
          ),
          value: selectedCategories.contains(category),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedCategories.add(category);
              } else {
                selectedCategories.remove(category);
                selectedAnimals.clear(); // Reset animals when categories change
              }
            });
          },
        );
      }).toList(),
    );
  }
}
