import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:albaypark/themes.dart';
import 'package:albaypark/features/head_veterinarian/presentation/reports_form.dart';

class AutopsyReportForm extends ReportForm {
  final _state = _AutopsyReportFormState();

  AutopsyReportForm({super.key});

  @override
  State<AutopsyReportForm> createState() => _state;

  @override
  Map<String, dynamic> getFormData() {
    return _state.getFormData();
  }
}

class _AutopsyReportFormState extends ReportFormState<AutopsyReportForm> {
  // Animal Information Controllers
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController sexController = TextEditingController();

  // Death Information Controllers
  final TextEditingController dateOfDeathController = TextEditingController();
  final TextEditingController timeOfDeathController = TextEditingController();
  final TextEditingController locationOfDeathController =
      TextEditingController();
  final TextEditingController circumstancesController = TextEditingController();

  // Examination Findings Controllers
  final TextEditingController causeOfDeathController = TextEditingController();
  final TextEditingController postMortemFindingsController =
      TextEditingController();
  final TextEditingController organSystemFindingsController =
      TextEditingController();
  final TextEditingController histopathologyController =
      TextEditingController();
  final TextEditingController toxicologyResultsController =
      TextEditingController();
  final TextEditingController bacteriologyResultsController =
      TextEditingController();
  final TextEditingController parasitologyResultsController =
      TextEditingController();
  final TextEditingController additionalTestsController =
      TextEditingController();
  final TextEditingController recommendationsController =
      TextEditingController();

  // Dropdowns and Toggles
  String _selectedCondition = 'Fresh';
  String _selectedMethod = 'Natural';
  bool _wasEuthanized = false;

  final List<String> _bodyConditions = [
    'Fresh',
    'Mild Decomposition',
    'Moderate Decomposition',
    'Advanced Decomposition'
  ];

  final List<String> _deathMethods = [
    'Natural',
    'Accident',
    'Disease',
    'Unknown',
    'Euthanasia'
  ];

  List<Map<String, dynamic>> animals = [];
  List<String> selectedCategories = [];
  String? selectedAnimalId;

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  @override
  void dispose() {
    // Dispose all controllers
    ageController.dispose();
    weightController.dispose();
    sexController.dispose();
    dateOfDeathController.dispose();
    timeOfDeathController.dispose();
    locationOfDeathController.dispose();
    circumstancesController.dispose();
    causeOfDeathController.dispose();
    postMortemFindingsController.dispose();
    organSystemFindingsController.dispose();
    histopathologyController.dispose();
    toxicologyResultsController.dispose();
    bacteriologyResultsController.dispose();
    parasitologyResultsController.dispose();
    additionalTestsController.dispose();
    recommendationsController.dispose();
    super.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateOfDeathController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeOfDeathController.text = picked.format(context);
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator ??
            (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }

  Map<String, dynamic> getFormData() {
    final selectedAnimal = animals.firstWhere(
        (animal) => animal['id'] == selectedAnimalId,
        orElse: () => {});

    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'animalId': selectedAnimalId,
      'age': ageController.text,
      'weight': weightController.text,
      'sex': sexController.text,
      'dateOfDeath': dateOfDeathController.text,
      'timeOfDeath': timeOfDeathController.text,
      'locationOfDeath': locationOfDeathController.text,
      'circumstances': circumstancesController.text,
      'bodyCondition': _selectedCondition,
      'wasEuthanized': _wasEuthanized.toString(),
      'methodOfDeath': _selectedMethod,
      'causeOfDeath': causeOfDeathController.text,
      'postMortemFindings': postMortemFindingsController.text,
      'organSystemFindings': organSystemFindingsController.text,
      'histopathologyResults': histopathologyController.text,
      'toxicologyResults': toxicologyResultsController.text,
      'bacteriologyResults': bacteriologyResultsController.text,
      'parasitologyResults': parasitologyResultsController.text,
      'additionalTests': additionalTestsController.text,
      'recommendations': recommendationsController.text,
    };
  }

  @override
  Widget buildFormFields() {
    final animalsByCategory = animals.where((animal) {
      return selectedCategories.isEmpty ||
          selectedCategories.contains(animal['category']);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animal Information Section
        _buildSectionHeader('Animal Information'),
        _buildCategorySelection(),
        if (selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Select Animal'),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: animalsByCategory.map((animal) {
              final isSelected = selectedAnimalId == animal['id'];
              return FilterChip(
                label: Text(animal['name']),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedAnimalId = animal['id'];
                      ageController.text = animal['age'] ?? '';
                      weightController.text = animal['weight'] ?? '';
                      sexController.text = animal['sex'] ?? '';
                    } else {
                      selectedAnimalId = null;
                    }
                  });
                },
                selectedColor: AppColors.accent.withOpacity(0.2),
                backgroundColor: AppColors.background,
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Age',
                controller: ageController,
                keyboardType: TextInputType.number,
                readOnly: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'Weight (kg)',
                controller: weightController,
                keyboardType: TextInputType.number,
                readOnly: false,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Sex',
                controller: sexController,
                readOnly: false,
              ),
            ),
          ],
        ),

        // Death Information Section
        _buildSectionHeader('Death Information'),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Date of Death',
                controller: dateOfDeathController,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'Time of Death',
                controller: timeOfDeathController,
                readOnly: true,
                onTap: () => _selectTime(context),
              ),
            ),
          ],
        ),
        _buildFormField(
          label: 'Location of Death',
          controller: locationOfDeathController,
        ),
        _buildFormField(
          label: 'Circumstances of Death',
          controller: circumstancesController,
          maxLines: 3,
        ),

        DropdownButtonFormField<String>(
          value: _selectedCondition,
          decoration: InputDecoration(
            labelText: 'Body Condition *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _bodyConditions.map((condition) {
            return DropdownMenuItem(
              value: condition,
              child: Text(condition),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCondition = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        CheckboxListTile(
          title: const Text('Was Euthanized'),
          value: _wasEuthanized,
          onChanged: (value) {
            setState(() {
              _wasEuthanized = value!;
              if (value) {
                _selectedMethod = 'Euthanasia';
              }
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedMethod,
          decoration: InputDecoration(
            labelText: 'Method of Death *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _deathMethods.map((method) {
            return DropdownMenuItem(
              value: method,
              child: Text(method),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMethod = value!;
            });
          },
        ),

        // Examination Findings Section
        _buildSectionHeader('Post-Mortem Examination'),
        _buildFormField(
          label: 'Cause of Death',
          controller: causeOfDeathController,
          maxLines: 2,
        ),
        _buildFormField(
          label: 'Post-Mortem Findings',
          controller: postMortemFindingsController,
          maxLines: 4,
        ),
        _buildFormField(
          label: 'Organ System Findings',
          controller: organSystemFindingsController,
          maxLines: 4,
        ),
        _buildFormField(
          label: 'Histopathology Results',
          controller: histopathologyController,
          maxLines: 3,
          isRequired: false,
        ),
        _buildFormField(
          label: 'Toxicology Results',
          controller: toxicologyResultsController,
          maxLines: 2,
          isRequired: false,
        ),
        _buildFormField(
          label: 'Bacteriology Results',
          controller: bacteriologyResultsController,
          maxLines: 2,
          isRequired: false,
        ),
        _buildFormField(
          label: 'Parasitology Results',
          controller: parasitologyResultsController,
          maxLines: 2,
          isRequired: false,
        ),
        _buildFormField(
          label: 'Additional Tests/Analysis',
          controller: additionalTestsController,
          maxLines: 2,
          isRequired: false,
        ),
        _buildFormField(
          label: 'Recommendations',
          controller: recommendationsController,
          maxLines: 3,
        ),
      ],
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
                selectedAnimalId = null; // Reset animal when categories change
              }
            });
          },
        );
      }).toList(),
    );
  }
}
