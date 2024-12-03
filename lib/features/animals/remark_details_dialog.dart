// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../themes.dart';

enum RemarkType {
  healthCheck,
  animalAddition,
  death,
  sickOrInjured,
  transfer,
  generalNote,
  recovery
}

class RemarkDetailsDialog extends StatefulWidget {
  final RemarkType type;
  final int animalCount;
  final String statisticsId; // Add this
  final Future<void> Function(
    BuildContext context,
    RemarkType type,
    Map<String, TextEditingController> controllers,
  ) onSubmit;

  const RemarkDetailsDialog({
    super.key,
    required this.type,
    required this.animalCount,
    required this.statisticsId, // Add this
    required this.onSubmit,
  });

  @override
  State<RemarkDetailsDialog> createState() => _RemarkDetailsDialogState();
}

class _RemarkDetailsDialogState extends State<RemarkDetailsDialog> {
  final Map<String, TextEditingController> controllers = {
    'remarkController': TextEditingController(),
    'healthyController': TextEditingController(text: '0'),
    'injuredController': TextEditingController(text: '0'),
    'isolatedController': TextEditingController(text: '0'),
    'diedController': TextEditingController(text: '0'),
    'diagnosisController': TextEditingController(),
    'treatmentController': TextEditingController(),
    'medicationController': TextEditingController(),
    'locationController': TextEditingController(),
    'causeController': TextEditingController(),
    'dateController': TextEditingController(),
  };

  bool isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic> currentStats = {
    'Injured': 0,
    'Isolated': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentStats();
  }

  Future<void> _loadCurrentStats() async {
    try {
      final statsSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('statistics')
          .child(widget.statisticsId)
          .get();

      if (statsSnapshot.exists) {
        final stats = Map<String, dynamic>.from(statsSnapshot.value as Map);
        setState(() {
          currentStats = {
            'Injured': int.tryParse(stats['Injured']?.toString() ?? '0') ?? 0,
            'Isolated': int.tryParse(stats['Isolated']?.toString() ?? '0') ?? 0,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  String? validateCount(String? value, RemarkType type) {
    final intValue = int.tryParse(value ?? '0') ?? 0;
    if (intValue <= 0) {
      return 'Number must be greater than 0';
    }

    // Check against total animal count for each specific type
    switch (type) {
      case RemarkType.sickOrInjured:
        // For sick/injured, check against current injured count
        final currentInjured =
            int.tryParse(currentStats['Injured']?.toString() ?? '0') ?? 0;
        if ((currentInjured + intValue) > widget.animalCount) {
          return 'Total injured animals (current: $currentInjured + new: $intValue) would exceed total count (${widget.animalCount})';
        }
        break;
      case RemarkType.recovery:
        final currentInjured =
            int.tryParse(currentStats['Injured']?.toString() ?? '0') ?? 0;
        if (intValue > currentInjured) {
          return 'Recovery count cannot exceed injured animals ($currentInjured)';
        }
        break;

      case RemarkType.transfer:
        // For transfers, check against current isolated count
        final currentIsolated =
            int.tryParse(currentStats['Isolated']?.toString() ?? '0') ?? 0;
        if ((currentIsolated + intValue) > widget.animalCount) {
          return 'Total isolated animals (current: $currentIsolated + new: $intValue) would exceed total count (${widget.animalCount})';
        }
        break;

      default:
        return null;
    }

    return null;
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getTitle(RemarkType type) {
    switch (type) {
      case RemarkType.healthCheck:
        return 'Add Health Check';
      case RemarkType.animalAddition:
        return 'Add Animals';
      case RemarkType.death:
        return 'Report Death';
      case RemarkType.sickOrInjured:
        return 'Report Sick/Injured';
      case RemarkType.transfer:
        return 'Record Transfer';
      case RemarkType.generalNote:
        return 'Add General Note';
      case RemarkType.recovery:
        return 'Record Recovery';
      default:
        return 'Add Remark';
    }
  }

  Future<bool> validateTotalStats(RemarkType type, int newValue) async {
    try {
      final statsSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('statistics')
          .child(widget.statisticsId)
          .get();

      if (!statsSnapshot.exists) return true;

      final stats = Map<String, dynamic>.from(statsSnapshot.value as Map);
      int currentInjured =
          int.tryParse(stats['Injured']?.toString() ?? '0') ?? 0;
      int currentIsolated =
          int.tryParse(stats['Isolated']?.toString() ?? '0') ?? 0;

      // Calculate new totals based on type
      int newTotal = 0;
      switch (type) {
        case RemarkType.sickOrInjured:
          newTotal = currentIsolated + newValue;
          break;
        case RemarkType.transfer:
          newTotal = currentInjured + newValue;
          break;
        default:
          return true;
      }

      return newTotal <= widget.animalCount;
    } catch (e) {
      debugPrint('Error validating stats: $e');
      return false;
    }
  }

  Widget _buildContent(RemarkType type) {
    switch (type) {
      case RemarkType.healthCheck:
        return Column(
          children: [
            TextFormField(
              controller: controllers['diagnosisController'],
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['treatmentController'],
              decoration: InputDecoration(
                labelText: 'Treatment',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['medicationController'],
              decoration: InputDecoration(
                labelText: 'Medication',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(),
          ],
        );

      case RemarkType.animalAddition:
        return Column(
          children: [
            TextFormField(
              controller: controllers['healthyController'],
              decoration: InputDecoration(
                labelText: 'Number of Animals Added',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['dateController'],
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date of Addition',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  controllers['dateController']!.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(),
          ],
        );

      case RemarkType.death:
        return Column(
          children: [
            TextFormField(
              controller: controllers['diedController'],
              decoration: InputDecoration(
                labelText: 'Number of Animals Died',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final intValue = int.tryParse(value ?? '0') ?? 0;
                if (intValue <= 0) {
                  return 'Number of deaths must be greater than 0.';
                }
                if (widget.animalCount - intValue < 0) {
                  return 'Number of deaths exceeds the total animal count.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['dateController'],
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date of Death',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  controllers['dateController']!.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['causeController'],
              decoration: InputDecoration(
                labelText: 'Cause of Death',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please specify the cause of death.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(),
          ],
        );

      case RemarkType.sickOrInjured:
        return Column(
          children: [
            TextFormField(
              controller: controllers['injuredController'],
              decoration: InputDecoration(
                labelText: 'Number of Animals Sick/Injured',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText:
                    'Current injured: ${currentStats['Injured']} | Total count: ${widget.animalCount}',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  validateCount(value, RemarkType.sickOrInjured),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['dateController'],
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date of Incident',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  controllers['dateController']!.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['diagnosisController'],
              decoration: InputDecoration(
                labelText: 'Condition/Symptoms',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['treatmentController'],
              decoration: InputDecoration(
                labelText: 'Initial Treatment',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(),
          ],
        );

      case RemarkType.recovery:
        return Column(
          children: [
            TextFormField(
              controller: controllers['healthyController'],
              decoration: InputDecoration(
                labelText: 'Number of Animals Recovered',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText:
                    'Current injured: ${currentStats['Injured']} | Total count: ${widget.animalCount}',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final intValue = int.tryParse(value ?? '0') ?? 0;
                if (intValue <= 0) {
                  return 'Number must be greater than 0';
                }
                // Check if recovery count doesn't exceed injured count
                if (intValue > (currentStats['Injured'] ?? 0)) {
                  return 'Recovery count cannot exceed number of injured animals (${currentStats['Injured']})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['dateController'],
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date of Recovery',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  controllers['dateController']!.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(),
          ],
        );
      case RemarkType.transfer:
        return Column(
          children: [
            TextFormField(
              controller: controllers['isolatedController'],
              decoration: InputDecoration(
                labelText: 'Number of Animals Transferred',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText:
                    'Current isolated: ${currentStats['Isolated']} | Total count: ${widget.animalCount}',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => validateCount(value, RemarkType.transfer),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['dateController'],
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date of Transfer',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  controllers['dateController']!.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['locationController'],
              decoration: InputDecoration(
                labelText: 'New Location',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(),
          ],
        );

      case RemarkType.generalNote:
        return _buildAdditionalNotes();
    }
  }

  Widget _buildAdditionalNotes() {
    return TextFormField(
      controller: controllers['remarkController'],
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Additional Notes',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter additional notes';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get available screen height and keyboard height
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: !isSubmitting,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: 40.0,
          vertical: screenHeight * 0.01, // 4% of screen height padding
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // Adjust height based on keyboard
          constraints: BoxConstraints(
            maxHeight:
                screenHeight * 0.8 - viewInsets, // 80% of available height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _getTitle(widget.type),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              // Dialog Content
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stats if needed
                          if (widget.type == RemarkType.sickOrInjured ||
                              widget.type == RemarkType.transfer)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16.0),
                            ),
                          // Main content
                          _buildContent(widget.type),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0 +
                      (viewInsets > 0
                          ? 8
                          : 0), // Add extra padding when keyboard is shown
                  top: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      child: Text('Cancel', style: GoogleFonts.poppins()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => isSubmitting = true);
                                try {
                                  await widget.onSubmit(
                                    context,
                                    widget.type,
                                    controllers,
                                  );
                                  if (mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Save',
                              style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
