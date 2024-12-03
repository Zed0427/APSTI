import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../themes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String task;
  final String details;
  final List<String> animals;
  final String taskId;
  final String assignedTo; // Add this

  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.details,
    required this.animals,
    required this.taskId,
    required this.assignedTo, // Add this
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  File? _image;
  final TextEditingController _remarksController = TextEditingController();
  final _database = FirebaseDatabase.instance.ref(); // Firebase reference
  List<String> animalNames = []; // Resolved animal names

  @override
  void initState() {
    super.initState();
    _fetchAnimalNames();
  }

  Future<void> _fetchAnimalNames() async {
    try {
      final snapshot = await _database.child('animals').get();
      if (snapshot.exists) {
        final animalsData = Map<String, dynamic>.from(snapshot.value as Map);

        final resolvedNames = widget.animals
            .map((id) {
              return animalsData[id]?['name'] ?? 'Unknown';
            })
            .cast<String>()
            .toList(); // Cast to List<String>

        setState(() {
          animalNames = resolvedNames;
        });
      }
    } catch (e) {
      debugPrint('Error fetching animal names: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery); // or .camera

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submitTask() async {
    final remarks = _remarksController.text.trim();

    if (_image == null || remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // 1. Upload image to Firebase Storage
      final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('task_images').child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': 'caretaker'},
      );

      final uploadTask = storageRef.putFile(_image!, metadata);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Create gallery entries for each animal
      for (String animalId in widget.animals) {
        // Gallery entry creation logic
        final newGalleryRef = _database.child('gallery').push();
        final galleryEntry = {
          'image': downloadUrl,
          'caption': remarks,
          'likes': 0,
          'likes_by_user': {},
          'comments': []
        };

        await newGalleryRef.set(galleryEntry);

        // Update animal's gallery
        final animalRef = _database.child('animals').child(animalId);
        final animalSnapshot = await animalRef.get();

        if (animalSnapshot.exists) {
          final animalData =
              Map<String, dynamic>.from(animalSnapshot.value as Map);
          List<String> currentGallery =
              List<String>.from(animalData['gallery'] ?? []);
          currentGallery.add(newGalleryRef.key!);
          await animalRef.update({
            'gallery': currentGallery,
          });
        }
      }

      // 3. Create CompletedDailyTasks entry
      final completedTaskRef = _database.child('completedDailyTasks').push();
      final completedTask = {
        'taskId': widget.taskId,
        'taskTitle': widget.task,
        'taskDetails': widget.details,
        'animals': widget.animals,
        'completedAt': DateTime.now().toIso8601String(),
        'remarks': remarks,
        'imageUrl': downloadUrl,
        'completedBy': widget
            .assignedTo, // Add assignedTo to TaskDetailsScreen constructor
      };

      await completedTaskRef.set(completedTask);

      // 4. Update original task status to Completed
      await _database.child('dailyTasks').child(widget.taskId).update({
        'status': 'Completed' // Make sure it's exactly 'Completed'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error submitting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting task: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBg,
        title: Text(
          widget.task,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header
            _buildTaskHeader(widget.task, widget.details, animalNames),

            const SizedBox(height: 16),

            // Image Picker Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                ),
                child: _image == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 48,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload an image',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Remarks Section
            Text(
              'Remarks:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                hintText: 'Enter any remarks for this task...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accent.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
              maxLines: 3,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.text,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit Task',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(String task, String details, List<String> animals) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Details:',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          if (animals.isNotEmpty) ...[
            Text(
              'Animals Involved:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: animals
                  .map((animal) => Chip(
                        label: Text(animal),
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.text,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
