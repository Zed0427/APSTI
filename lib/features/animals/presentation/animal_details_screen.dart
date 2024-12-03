// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:albaypark/features/animals/presentation/image_modal.dart';
import 'package:albaypark/features/animals/remark_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../themes.dart';

class AnimalDetailsScreen extends StatefulWidget {
  final String animalId;
  final String userRole;

  const AnimalDetailsScreen({
    super.key,
    required this.animalId,
    required this.userRole,
  });

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<String, dynamic> animal = {};
  bool isLoading = true;
  late Stream<DatabaseEvent> _statsStream; // Initialize in initState
  Map<String, dynamic>? _cachedStats; // Cache for stream data

  bool get canSolveCase {
    return widget.userRole == 'HeadVet' || widget.userRole == 'AssistantVet';
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final usersSnapshot = await _dbRef.child('users').get();
      if (usersSnapshot.exists) {
        final users = Map<String, dynamic>.from(usersSnapshot.value as Map);

        // Find user with matching role
        final user = users.entries.firstWhere(
          (entry) => (entry.value as Map)['role'] == widget.userRole,
          orElse: () => const MapEntry('', {}),
        );

        if (user.key.isNotEmpty) {
          return user.key;
        }
      }
    } catch (e) {
      debugPrint('Error getting user ID: $e');
    }
    return null;
  }

// Add method to get user name by role
  Future<String> _getUserNameByRole(String role) async {
    try {
      final usersSnapshot = await _dbRef.child('users').get();
      if (usersSnapshot.exists) {
        final users = Map<String, dynamic>.from(usersSnapshot.value as Map);

        final user = users.entries.firstWhere(
          (entry) => (entry.value as Map)['role'] == role,
          orElse: () => const MapEntry('', {'name': 'Unknown User'}),
        );

        return (user.value as Map)['name']?.toString() ?? 'Unknown User';
      }
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }
    return 'Unknown User';
  }

// Add this method to track likes
  Future<void> _handleLike(String photoId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not found');

      // Get current likes
      final likesRef = _dbRef.child('gallery/$photoId/likes');
      final likesSnapshot = await likesRef.get();
      final currentLikes = (likesSnapshot.value as int?) ?? 0;

      // Get liked status for this user
      final userLikesRef = _dbRef.child('user_likes/$userId/$photoId');
      final userLikeSnapshot = await userLikesRef.get();

      if (userLikeSnapshot.exists) {
        // User already liked, remove like
        await userLikesRef.remove();
        await likesRef.set(currentLikes - 1);
      } else {
        // User hasn't liked, add like
        await userLikesRef.set(true);
        await likesRef.set(currentLikes + 1);
      }
    } catch (e) {
      debugPrint('Error handling like: $e');
    }
  }

// Updated comment posting logic
  Future<void> _addComment(String photoId, String commentText) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not found');

      // Create new comment
      final newCommentRef = _dbRef.child('comments').push();
      await newCommentRef.set({
        'text': commentText.trim(),
        'user': userId,
        'timestamp': ServerValue.timestamp,
      });

      // Initialize or update comments array in gallery
      final galleryRef = _dbRef.child('gallery/$photoId');
      final snapshot = await galleryRef.child('comments').get();

      List<String> currentComments = [];
      if (snapshot.exists) {
        final dynamic value = snapshot.value;
        if (value is List) {
          currentComments = List<String>.from(value);
        }
      }

      currentComments = [...currentComments, newCommentRef.key!];
      await galleryRef.child('comments').set(currentComments);
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Widget _buildContent(
    RemarkType type,
    TextEditingController remarkController,
    TextEditingController healthyController,
    TextEditingController injuredController,
    TextEditingController isolatedController,
    TextEditingController diedController,
    TextEditingController diagnosisController,
    TextEditingController treatmentController,
    TextEditingController medicationController,
    TextEditingController locationController,
    TextEditingController causeController,
    TextEditingController dateController,
  ) {
    switch (type) {
      case RemarkType.healthCheck:
        return Column(
          children: [
            TextFormField(
              controller: diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: treatmentController,
              decoration: InputDecoration(
                labelText: 'Treatment',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: medicationController,
              decoration: InputDecoration(
                labelText: 'Medication',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(remarkController),
          ],
        );
      case RemarkType.animalAddition:
        return Column(
          children: [
            TextFormField(
              controller: healthyController,
              decoration: InputDecoration(
                labelText: 'Number of Animals Added',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
              readOnly: true, // Prevents manual editing
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
                  dateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(remarkController),
          ],
        );

      case RemarkType.death:
        return Column(
          children: [
            TextFormField(
              controller: diedController,
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
                if (animal['count'] - intValue < 0) {
                  return 'Number of deaths exceeds the total animal count.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
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
                  dateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: causeController,
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
            _buildAdditionalNotes(remarkController),
          ],
        );

      case RemarkType.sickOrInjured:
        return Column(
          children: [
            TextFormField(
              controller: injuredController,
              decoration: InputDecoration(
                labelText: 'Number of Animals Sick/Injured',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
              readOnly: true, // Prevents manual editing
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
                  dateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: diagnosisController,
              decoration: InputDecoration(
                labelText: 'Condition/Symptoms',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: treatmentController,
              decoration: InputDecoration(
                labelText: 'Initial Treatment',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(remarkController),
          ],
        );
      case RemarkType.recovery:
        return Column(
          children: [
            TextFormField(
              controller: healthyController, // Reuse for recovered count
              decoration: InputDecoration(
                labelText: 'Number of Animals Recovered',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final intValue = int.tryParse(value ?? '0') ?? 0;
                if (intValue <= 0) {
                  return 'Number must be greater than 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
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
                  dateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(remarkController),
          ],
        );

      case RemarkType.transfer:
        return Column(
          children: [
            TextFormField(
              controller: isolatedController,
              decoration: InputDecoration(
                labelText: 'Number of Animals Transferred',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
              readOnly: true, // Prevents manual editing
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
                  dateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'New Location',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdditionalNotes(remarkController),
          ],
        );

      default:
        return _buildAdditionalNotes(remarkController);
    }
  }

  Widget _buildAdditionalNotes(TextEditingController controller) {
    return TextFormField(
      controller: controller,
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
  void initState() {
    super.initState();
    _loadAnimalData();
  }
// void _setupRealtimeListener() {
//   _dbRef.child('animals/${widget.animalId}').onValue.listen((event) {
//     if (event.snapshot.exists) {
//       setState(() {
//         animal = Map<String, dynamic>.from(event.snapshot.value as Map);
//         isLoading = false;
//       });
//     }
//   }, onError: (error) {
//     print('Error in realtime listener: $error');
//   });
// }

  Future<void> _loadAnimalData() async {
    try {
      final snapshot = await _dbRef.child('animals/${widget.animalId}').get();

      if (snapshot.exists) {
        setState(() {
          animal = Map<String, dynamic>.from(snapshot.value as Map);
          isLoading = false;
        });

        if (animal['statistics'] != null) {
          _statsStream = _dbRef
              .child('statistics')
              .child(animal['statistics'])
              .onValue
              .asBroadcastStream();
        }
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Animal data not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading animal data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAsResolved() async {
    try {
      await _dbRef.child('animals/${widget.animalId}/isUrgent').set(false);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${animal['name']} case resolved!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Error marking as resolved: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating status',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

// Get user by ID
  Future<Map<String, dynamic>> _getUserById(String userId) async {
    try {
      final snapshot = await _dbRef.child('users/$userId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {'name': 'Anonymous'};
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return {'name': 'Anonymous'};
    }
  }

// Add Remark
  Future<void> _addRemark(BuildContext context) async {
    RemarkType? selectedType;

    // Show type selection dialog first
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Select Remark Type',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: RemarkType.values.map((type) {
                IconData icon;
                Color color;
                String title;

                switch (type) {
                  case RemarkType.healthCheck:
                    icon = Icons.health_and_safety;
                    color = Colors.green;
                    title = 'Health Check';
                    break;
                  case RemarkType.animalAddition:
                    icon = Icons.add;
                    color = Colors.blue;
                    title = 'Animal Addition';
                    break;
                  case RemarkType.death:
                    icon = Icons.warning;
                    color = Colors.red;
                    title = 'Death Report';
                    break;
                  case RemarkType.sickOrInjured:
                    icon = Icons.local_hospital;
                    color = Colors.orange;
                    title = 'Sick/Injured';
                    break;
                  case RemarkType.transfer:
                    icon = Icons.transfer_within_a_station;
                    color = Colors.purple;
                    title = 'Transfer';
                    break;
                  case RemarkType.generalNote:
                    icon = Icons.note;
                    color = Colors.grey;
                    title = 'General Note';
                    break;
                  case RemarkType.recovery:
                    icon = Icons.health_and_safety_outlined;
                    color = Colors.green;
                    title = 'Recovery';
                    break;
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(title, style: GoogleFonts.poppins()),
                  onTap: () {
                    selectedType = type;
                    Navigator.pop(dialogContext);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    // If type was selected, show the details dialog
    if (selectedType != null && mounted) {
      await _showRemarkDetailsDialog(context, selectedType!);
    }
  }

  Future<void> _showRemarkDetailsDialog(
      BuildContext context, RemarkType type) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return RemarkDetailsDialog(
            type: type,
            animalCount: animal['count'] ?? 0,
            statisticsId: animal['statistics'] ?? '', // Add this
            onSubmit: (context, type, data) async {
              await _submitRemark(
                context,
                type,
                data['remarkController']!,
                data['healthyController']!,
                data['injuredController']!,
                data['isolatedController']!,
                data['diedController']!,
                data['diagnosisController']!,
                data['treatmentController']!,
                data['medicationController']!,
                data['locationController']!,
                data['causeController']!,
                data['dateController']!,
                DateTime.now().toLocal().toString().split(' ')[0],
              );
            },
          );
        },
      );

      // Only show success message if result is true
      if (result == true && mounted) {
        await _loadAnimalData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Record added successfully',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Separate submit function
  Future<void> _submitRemark(
    BuildContext context,
    RemarkType type,
    TextEditingController remarkController,
    TextEditingController healthyController,
    TextEditingController injuredController,
    TextEditingController isolatedController,
    TextEditingController diedController,
    TextEditingController diagnosisController,
    TextEditingController treatmentController,
    TextEditingController medicationController,
    TextEditingController locationController,
    TextEditingController causeController,
    TextEditingController dateController,
    String selectedDate,
  ) async {
    try {
      // Get current user ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('Unable to identify current user');
      }

      // Parse numeric inputs
      final healthyCount = int.tryParse(healthyController.text) ?? 0;
      final injuredCount = int.tryParse(injuredController.text) ?? 0;
      final isolatedCount = int.tryParse(isolatedController.text) ?? 0;

      final totalCount = animal['count'] ?? 0; // Current total count of animals

      // Prepare remark data
      final newRemarkRef = _dbRef.child('remarks').push();
      final userName = await _getUserNameByRole(widget.userRole);

      final Map<String, dynamic> remarkData = {
        'type': type.toString().split('.').last,
        'user': userId,
        'userName': userName,
        'userRole': widget.userRole,
        'remark': remarkController.text.trim(),
        'date': selectedDate,
        'time': TimeOfDay.now().format(context),
        'animal_id': widget.animalId,
        'timestamp': ServerValue.timestamp, // For sorting remarks
      };

      // Update statistics based on the type
      final statsSnapshot =
          await _dbRef.child('statistics').child(animal['statistics']).get();
      Map<String, dynamic> currentStats = statsSnapshot.exists
          ? Map<String, dynamic>.from(statsSnapshot.value as Map)
          : {'Healthy': 0, 'Injured': 0, 'Isolated': 0, 'Died': 0};

      switch (type) {
        case RemarkType.healthCheck:
          remarkData.addAll({
            'diagnosis': diagnosisController.text.trim(),
            'treatment': treatmentController.text.trim(),
            'medication': medicationController.text.trim(),
          });
          break;
        case RemarkType.death:
          // Parse death count
          final deathCount = int.tryParse(diedController.text) ?? 0;

          // Validation: Death count must be greater than 0
          if (deathCount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Number of deaths must be greater than 0.',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return; // Stop submission
          }

          // Validation: Resulting count must not be less than 0
          if (totalCount - deathCount < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Number of deaths exceeds the total count ($totalCount).',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return; // Stop submission
          }

          // Validation: Cause of death must not be empty
          if (causeController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Please specify the cause of death.',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return; // Stop submission
          }

          // Update remark and statistics
          remarkData.addAll({
            'death_count': deathCount,
            'cause': causeController.text.trim(),
            'dateOfDeath': dateController.text.trim(),
          });
          currentStats['Died'] = (currentStats['Died'] ?? 0) + deathCount;

          // Decrease total animal count
          await _dbRef.child('animals/${widget.animalId}/count').set(
                totalCount - deathCount,
              );
          break;

        case RemarkType.animalAddition:
          // Add animals as healthy
          remarkData.addAll({
            'animals_added': healthyCount,
            'dateAdded': dateController.text.trim()
          });
          currentStats['Healthy'] =
              (currentStats['Healthy'] ?? 0) + healthyCount;

          // Update total count
          await _dbRef.child('animals/${widget.animalId}/count').set(
                totalCount + healthyCount,
              );
          break;

        case RemarkType.sickOrInjured:
          // Validate affected animals
          if (injuredCount > totalCount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Injured animals (${injuredCount}) exceed total count ($totalCount).',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return; // Stop submission
          }

          remarkData.addAll({
            'injured_count': injuredCount,
            'diagnosis': diagnosisController.text.trim(),
            'treatment': treatmentController.text.trim(),
            'dateOfIncident': dateController.text.trim(),
          });

          // Update both Injured and Healthy counts
          currentStats['Injured'] =
              (currentStats['Injured'] ?? 0) + injuredCount;
          currentStats['Healthy'] =
              (currentStats['Healthy'] ?? 0) - injuredCount;
          break;
        case RemarkType.recovery:
          final recoveredCount = int.tryParse(healthyController.text) ?? 0;
          if (recoveredCount > (currentStats['Injured'] ?? 0)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error: Recovery count exceeds injured animals.')),
            );
            return;
          }

          remarkData.addAll({
            'recovered_count': recoveredCount,
            'dateOfRecovery': dateController.text.trim(),
          });

          // Update both Healthy and Injured counts
          currentStats['Healthy'] =
              (currentStats['Healthy'] ?? 0) + recoveredCount;
          currentStats['Injured'] =
              (currentStats['Injured'] ?? 0) - recoveredCount;
          break;

        case RemarkType.transfer:
          // Validate transferred animals
          if (isolatedCount > totalCount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Transferred animals (${isolatedCount}) exceed total count ($totalCount).',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return; // Stop submission
          }

          remarkData.addAll({
            'animals_transferred': isolatedCount,
            'new_location': locationController.text.trim(),
            'dateOfTransfer': dateController.text.trim(),
          });
          currentStats['Isolated'] =
              (currentStats['Isolated'] ?? 0) + isolatedCount;
          break;

        default:
          break;
      }

      // Save remark and update statistics
      await newRemarkRef.set(remarkData);
      await _dbRef
          .child('statistics')
          .child(animal['statistics'])
          .set(currentStats);

      // Update remarks in animal data
      final List<dynamic> currentRemarks = List.from(animal['remarks'] ?? []);
      currentRemarks.add(newRemarkRef.key);
      await _dbRef
          .child('animals/${widget.animalId}/remarks')
          .set(currentRemarks);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Remark added successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error submitting remark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting remark: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper function to get title
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

  Widget buildStatisticsTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _statsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedStats == null) {
          // Show a loading indicator only if no cached data exists
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          // Update cached stats when new data arrives
          _cachedStats = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
        }

        // Use cached stats if available, otherwise show the "No statistics" message
        if (_cachedStats != null) {
          return _buildStatisticsContent(_cachedStats!);
        }

        return Center(
          child: Text(
            'No statistics found',
            style: GoogleFonts.poppins(color: AppColors.textLight),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsContent(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: _getMaxValue(stats) + 2,
                barGroups: _buildBarChartGroups(stats),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          'Healthy',
                          'Injured',
                          'Isolated',
                          'Died'
                        ];
                        if (value.toInt() < labels.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              labels[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      const labels = ['Healthy', 'Injured', 'Isolated', 'Died'];
                      return BarTooltipItem(
                        '${labels[group.x]}\n${rod.toY.toInt()}',
                        GoogleFonts.poppins(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxValue(Map<String, dynamic> stats) {
    double maxValue = 0;
    for (var v in stats.values) {
      if (v is num) {
        maxValue = max(maxValue, v.toDouble());
      } else if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) {
          maxValue = max(maxValue, parsed);
        }
      }
    }
    return maxValue;
  }

// Open Image Modal
  void _openImageModal(BuildContext context, String photoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImageModal(
          photoId: photoId,
          getUserById: _getUserById,
          getCurrentUserId: _getCurrentUserId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.cardBg,
          title: Text(
            animal['name'] ?? 'Animal Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildAnimalInfo(),
            if (canSolveCase && (animal['isUrgent'] ?? false)) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _markAsResolved,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  'Mark as Resolved',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
            TabBar(
              indicatorColor: AppColors.accent,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "Remarks"),
                Tab(text: "Statistics"),
                Tab(text: "Gallery"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRemarksTab(),
                  buildStatisticsTab(),
                  _buildGalleryTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.accent,
          onPressed: () => _addRemark(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

// Add this to your state class
  void _showAnimalDetails(BuildContext context) {
    bool isEditing = false;
    Map<String, TextEditingController> controllers = {
      'name': TextEditingController(text: animal['name']),
      'scientificName': TextEditingController(text: animal['scientificName']),
      'IUCNRedList': TextEditingController(text: animal['IUCNRedList']),
      'category': TextEditingController(text: animal['category']),
      'count': TextEditingController(text: animal['count']?.toString()),
      'status': TextEditingController(text: animal['status']),
      'lastCheckup': TextEditingController(text: animal['lastCheckup']),
      'NatureOfAcquisition':
          TextEditingController(text: animal['NatureOfAcquisition']),
      'AreaCageNumber': TextEditingController(text: animal['AreaCageNumber']),
      'additionalDetails':
          TextEditingController(text: animal['additionalDetails']),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Additional Details',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                      isEditing ? Icons.close : Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      isEditing = !isEditing;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildDetailSection('Basic Information', [
                          _buildDetailRow('Name',
                              isEditing ? controllers['name'] : animal['name']),
                          _buildDetailRow(
                              'Scientific Name',
                              isEditing
                                  ? controllers['scientificName']
                                  : animal['scientificName']),
                          _buildDetailRow(
                              'IUCN Red List Status',
                              isEditing
                                  ? controllers['IUCNRedList']
                                  : animal['IUCNRedList']),
                          _buildDetailRow(
                              'Category',
                              isEditing
                                  ? controllers['category']
                                  : animal['category']),
                          _buildDetailRow(
                              'Count',
                              isEditing
                                  ? controllers['count']
                                  : animal['count']?.toString()),
                          _buildDetailRow(
                              'Health Status',
                              isEditing
                                  ? controllers['status']
                                  : animal['status']),
                          _buildDetailRow(
                              'Last Checkup',
                              isEditing
                                  ? controllers['lastCheckup']
                                  : animal['lastCheckup']),
                        ]),
                        _buildDetailSection('Location & Acquisition', [
                          _buildDetailRow(
                              'Nature of Acquisition',
                              isEditing
                                  ? controllers['NatureOfAcquisition']
                                  : animal['NatureOfAcquisition']),
                          _buildDetailRow(
                              'Area/Cage Number',
                              isEditing
                                  ? controllers['AreaCageNumber']
                                  : animal['AreaCageNumber']),
                        ]),
                        if (!isEditing &&
                            (animal['additionalDetails']?.isNotEmpty ??
                                false)) ...[
                          const SizedBox(height: 16),
                          _buildDetailSection('Additional Details', [
                            _buildDetailRow('Additional Details',
                                animal['additionalDetails']),
                          ]),
                        ],
                        if (isEditing) ...[
                          const SizedBox(height: 16),
                          _buildDetailSection('Additional Details', [
                            _buildDetailRow('Additional Details',
                                controllers['additionalDetails']),
                          ]),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                Map<String, dynamic> updatedAnimal = {
                                  'name': controllers['name']!.text,
                                  'scientificName':
                                      controllers['scientificName']!.text,
                                  'IUCNRedList':
                                      controllers['IUCNRedList']!.text,
                                  'category': controllers['category']!.text,
                                  'count': int.tryParse(
                                          controllers['count']!.text) ??
                                      animal['count'],
                                  'status': controllers['status']!.text,
                                  'lastCheckup':
                                      controllers['lastCheckup']!.text,
                                  'NatureOfAcquisition':
                                      controllers['NatureOfAcquisition']!.text,
                                  'AreaCageNumber':
                                      controllers['AreaCageNumber']!.text,
                                  'additionalDetails':
                                      controllers['additionalDetails']!.text,
                                };

                                await _dbRef
                                    .child('animals/${widget.animalId}')
                                    .update(updatedAnimal);

                                setState(() {
                                  animal.addAll(updatedAnimal);
                                  isEditing = false;
                                });

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Changes saved successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving changes: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: value is TextEditingController
                ? TextField(
                    controller: value,
                    decoration: InputDecoration(
                      hintText: label,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : Text(
                    value ?? 'Not specified',
                    style: GoogleFonts.poppins(color: AppColors.text),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  // Widget _buildDetailRow(String label, String? value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 120,
  //           child: Text(
  //             label,
  //             style: GoogleFonts.poppins(
  //               color: AppColors.textLight,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value ?? 'Not specified',
  //             style: GoogleFonts.poppins(color: AppColors.text),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

// Update your _buildAnimalInfo method
  Widget _buildAnimalInfo() {
    if (animal.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Animal details not found.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                animal['image'] ?? 'https://via.placeholder.com/200',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: AppColors.cardBg,
                    child: const Icon(Icons.error),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                animal['name'] ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Scientific Name', animal['scientificName']),
              _buildInfoRow('Category', animal['category']),
              _buildInfoRow('Count', animal['count']?.toString()),
              _buildInfoRow('Area/Cage Number', animal['AreaCageNumber']),
              _buildInfoRow('Last Checkup', animal['lastCheckup']),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showAnimalDetails(context),
                  icon: const Icon(Icons.info_outline),
                  label: Text(
                    'View More Details',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: ${value ?? 'Unknown'}',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  Widget _buildRemarksTab() {
    if (animal['remarks'] == null || (animal['remarks'] as List).isEmpty) {
      return Center(
        child: Text(
          'No remarks yet',
          style: GoogleFonts.poppins(color: AppColors.textLight),
        ),
      );
    }

    List<dynamic> remarksList = List.from(animal['remarks'] ?? []);
    remarksList = remarksList.reversed.toList(); // Show newest first

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: remarksList.length,
      itemBuilder: (context, index) {
        String remarkId = remarksList[index].toString();
        return StreamBuilder(
          stream: _dbRef.child('remarks/$remarkId').onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return const SizedBox.shrink();
            }

            final remark =
                Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accent.withOpacity(0.1),
                          child: Icon(
                            _getRemarkTypeIcon(remark['type'] ?? ''),
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                remark['userName'] ?? 'Unknown User',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${remark['userRole'] ?? ''} • ${remark['date']} at ${remark['time']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (remark['type'] != null) ...[
                      _buildRemarkTypeSpecificInfo(remark),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      remark['remark']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getRemarkTypeIcon(String type) {
    switch (type) {
      case 'healthCheck':
        return Icons.health_and_safety;
      case 'animalAddition':
        return Icons.add_circle;
      case 'death':
        return Icons.warning;
      case 'sickOrInjured':
        return Icons.local_hospital;
      case 'transfer':
        return Icons.transfer_within_a_station;
      case 'recovery':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.note;
    }
  }

  Widget _buildRemarkTypeSpecificInfo(Map<String, dynamic> remark) {
    final type = remark['type'] as String;
    final textStyle = GoogleFonts.poppins(
      fontSize: 13,
      color: AppColors.textLight,
      height: 1.5,
    );

    switch (type) {
      case 'healthCheck':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (remark['diagnosis']?.isNotEmpty ?? false)
              Text('Diagnosis: ${remark['diagnosis']}', style: textStyle),
            if (remark['treatment']?.isNotEmpty ?? false)
              Text('Treatment: ${remark['treatment']}', style: textStyle),
            if (remark['medication']?.isNotEmpty ?? false)
              Text('Medication: ${remark['medication']}', style: textStyle),
          ],
        );

      case 'animalAddition':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Added ${remark['animals_added']} animals',
              style: textStyle,
            ),
            Text(
              'Date Added: ${remark['dateAdded'] ?? 'Not specified'}',
              style: textStyle,
            ),
          ],
        );

      case 'death':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deaths: ${remark['death_count'] ?? 'Not specified'}',
              style: textStyle,
            ),
            Text(
              'Cause: ${remark['cause'] ?? 'Not specified'}',
              style: textStyle,
            ),
            Text(
              'Date of Death: ${remark['dateOfDeath'] ?? 'Not specified'}',
              style: textStyle,
            ),
          ],
        );

      case 'transfer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transferred ${remark['animals_transferred'] ?? 0} animals',
              style: textStyle,
            ),
            Text(
              'To: ${remark['new_location'] ?? 'Not specified'}',
              style: textStyle,
            ),
            Text(
              'Date of Transfer: ${remark['dateOfTransfer'] ?? 'Not specified'}',
              style: textStyle,
            ),
          ],
        );

      case 'sickOrInjured':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condition: ${remark['diagnosis'] ?? 'Not specified'}',
              style: textStyle,
            ),
            Text(
              'Treatment: ${remark['treatment'] ?? 'Not specified'}',
              style: textStyle,
            ),
            Text(
              'Affected Animals: ${remark['injured_count'] ?? 0}',
              style: textStyle,
            ),
            Text(
              'Date of Incident: ${remark['dateOfIncident'] ?? 'Not specified'}',
              style: textStyle,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  List<BarChartGroupData> _buildBarChartGroups(
      Map<String, dynamic> statistics) {
    const categories = ['Healthy', 'Injured', 'Isolated', 'Died'];
    const colors = [Colors.green, Colors.red, Colors.orange, Colors.black];

    return List.generate(categories.length, (index) {
      final category = categories[index];
      double value = 0.0;
      var rawValue = statistics[category];

      if (rawValue != null) {
        if (rawValue is num) {
          value = rawValue.toDouble();
        } else if (rawValue is String) {
          value = double.tryParse(rawValue) ?? 0.0;
        }
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: colors[index],
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildGalleryTab() {
    if (animal['gallery'] == null || (animal['gallery'] as List).isEmpty) {
      return Center(
        child: Text(
          'No gallery images yet',
          style: GoogleFonts.poppins(color: AppColors.textLight),
        ),
      );
    }

    List<dynamic> galleryList = List.from(animal['gallery'] ?? []);

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: galleryList.length,
      itemBuilder: (context, index) {
        String galleryId = galleryList[index].toString();
        return StreamBuilder(
          stream: _dbRef.child('gallery/$galleryId').onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return const SizedBox.shrink();
            }

            final dynamic photoData = snapshot.data!.snapshot.value;
            if (photoData == null) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () => _openImageModal(context, galleryId),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoData['image']?.toString() ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.cardBg,
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        photoData['caption']?.toString() ?? '',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
