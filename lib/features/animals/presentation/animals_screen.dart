// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:albaypark/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import '../../../themes.dart';
import 'animal_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AnimalsScreen extends StatefulWidget {
  final String role;

  const AnimalsScreen({super.key, required this.role});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  List<Map<String, dynamic>> animals = []; // Holds all fetched animals
  List<Map<String, dynamic>> filteredAnimals = []; // Holds filtered animals
  String searchQuery = '';
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchAnimals(); // Fetch animals from Firebase on load
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Create unique file name
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      // Create storage reference
      final storageRef =
          FirebaseStorage.instance.ref().child('animal_images').child(fileName);

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': 'admin'}, // You can add custom metadata
      );

      // Start upload task
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Show upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: $progress%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'unauthorized':
          errorMessage =
              'Not authorized to upload images. Please check permissions.';
          break;
        case 'canceled':
          errorMessage = 'Upload was cancelled';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage = 'Network error occurred. Please try again.';
          break;
        default:
          errorMessage = 'Error uploading image: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error uploading image: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _fetchAnimals() async {
    try {
      final ref = FirebaseDatabase.instance.ref('animals');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> fetchedAnimals = [];

        data.forEach((key, value) {
          if (value is Map) {
            // Add the Firebase key and data
            fetchedAnimals.add({
              'firebaseId': key, // Store the Firebase generated ID
              ...Map<String, dynamic>.from(value),
            });
          }
        });

        setState(() {
          animals = fetchedAnimals;
          _applyRoleFilter();
        });
      }
    } catch (e) {
      debugPrint('Error fetching animals: $e');
    }
  }

  void _handleEmergency(Map<String, dynamic> animal) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Urgency',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to mark ${animal['name']} as urgent?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == null || !confirmed) return;

    try {
      setState(() {
        animal['isUrgent'] = true;
      });

      // Update urgency in Firebase using the Firebase ID
      final ref =
          FirebaseDatabase.instance.ref('animals/${animal['firebaseId']}');
      await ref.update({'isUrgent': true});

      // Send notification
      await NotificationService.instance.sendNotification(
        'Emergency Reported', // Title of the notification
        'Urgency reported for ${animal['name']}!', // Body of the notification
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Urgency reported for ${animal['name']}!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to report urgency for ${animal['name']}.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  void _applyRoleFilter() {
    setState(() {
      switch (widget.role) {
        case 'CaretakerA':
          filteredAnimals =
              animals.where((animal) => animal['category'] == 'Avian').toList();
          break;
        case 'CaretakerB':
          filteredAnimals = animals
              .where((animal) => animal['category'] == 'Mammal')
              .toList();
          break;
        case 'CaretakerC':
          filteredAnimals = animals
              .where((animal) => animal['category'] == 'Reptile')
              .toList();
          break;
        default:
          filteredAnimals = animals; // For HeadVet, AssistantVet, or others
          break;
      }
      _filterAndSearch(); // Apply search query after role-based filtering
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      _filterAndSearch();
    });
  }

  void _filterAndSearch() {
    setState(() {
      filteredAnimals = animals.where((animal) {
        // Apply role-based filter first
        bool roleFilter = false;
        switch (widget.role) {
          case 'CaretakerA':
            roleFilter = animal['category'] == 'Avian';
            break;
          case 'CaretakerB':
            roleFilter = animal['category'] == 'Mammal';
            break;
          case 'CaretakerC':
            roleFilter = animal['category'] == 'Reptile';
            break;
          default:
            roleFilter = true; // For HeadVet, AssistantVet, or others
            break;
        }

        // Apply search query filter
        bool searchFilter =
            animal['name'].toLowerCase().contains(searchQuery.toLowerCase());

        // Apply category filter if selected
        bool categoryFilter =
            selectedCategory == null || animal['category'] == selectedCategory;

        // Combine all filters
        return roleFilter && searchFilter && categoryFilter;
      }).toList();
    });
  }

  void _toggleCategoryFilter(String category) {
    setState(() {
      if (selectedCategory == category) {
        selectedCategory = null; // Clear filter
      } else {
        selectedCategory = category;
      }
      _filterAndSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBg,
        title: Text(
          'Animals',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search animals...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: AppColors.accent.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          if (widget.role == 'HeadVet' || widget.role == 'AssistantVet') ...[
            // Filter Buttons for HeadVet and AssistantVet
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFilterButton('Avian'),
                  _buildFilterButton('Mammal'),
                  _buildFilterButton('Reptile'),
                ],
              ),
            ),
          ],
          const Divider(color: AppColors.textLight, height: 1),
          // Animal List
          Expanded(
            child: filteredAnimals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No animals found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredAnimals.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final animal = filteredAnimals[index];
                      return _buildAnimalCard(animal);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.role == 'HeadVet'
          ? FloatingActionButton(
              onPressed: _showAddAnimalDialog,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddAnimalDialog() {
    final nameController = TextEditingController();
    final scientificNameController = TextEditingController();
    final cageController = TextEditingController();
    final countController = TextEditingController(text: '0');
    String selectedCategory = 'Avian'; // Default value
    String selectedAcquisition = 'Donated'; // Default value
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Add New Animal',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedImage = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (pickedImage != null) {
                          setState(() {
                            selectedImage = File(pickedImage.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent),
                          borderRadius: BorderRadius.circular(12),
                          image: selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImage == null
                            ? Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey.withOpacity(0.7),
                                  size: 32,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scientificNameController,
                      decoration: InputDecoration(
                        labelText: 'Scientific Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: ['Avian', 'Mammal', 'Reptile']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cageController,
                      decoration: InputDecoration(
                        labelText: 'Area/Cage Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedAcquisition,
                      items: ['Donated', 'Purchased', 'Rescued', 'Turned over']
                          .map((acquisition) => DropdownMenuItem(
                                value: acquisition,
                                child: Text(acquisition),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAcquisition = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Nature of Acquisition',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Head Count',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                    await _addNewAnimal(
                      name: nameController.text,
                      scientificName: scientificNameController.text,
                      category: selectedCategory,
                      cageNumber: cageController.text,
                      acquisition: selectedAcquisition,
                      count: int.tryParse(countController.text) ?? 0,
                      image: selectedImage,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewAnimal({
    required String name,
    required String scientificName,
    required String category,
    required String cageNumber,
    required String acquisition,
    required int count,
    File? image,
  }) async {
    try {
      // Upload image if provided
      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadImage(image);
      }

      // Create statistics entry
      final newStatsRef = FirebaseDatabase.instance.ref('statistics').push();
      await newStatsRef.set({
        'Healthy': count,
        'Injured': 0,
        'Isolated': 0,
        'Died': 0,
      });

      // Get the statistics key
      final statisticsId = newStatsRef.key;

      // Create animal entry
      final newAnimalRef = FirebaseDatabase.instance.ref('animals').push();
      await newAnimalRef.set({
        'name': name,
        'scientificName': scientificName,
        'category': category,
        'AreaCageNumber': cageNumber,
        'NatureOfAcquisition': acquisition,
        'count': count,
        'image': imageUrl ?? 'https://via.placeholder.com/150',
        'isUrgent': false,
        'status': 'Healthy',
        'IUCNRedList': 'LC', // Default value
        'APWPropertyIDNumber': ['None'], // Default array with a single "None"
        'lastCheckup': DateTime.now().toLocal().toString().split(' ')[0],
        'statistics': statisticsId, // Link statistics ID
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New animal added successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh the animal list
      _fetchAnimals();
    } catch (e) {
      debugPrint('Error adding new animal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error adding new animal: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildFilterButton(String category) {
    final isSelected = selectedCategory == category;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isSelected ? AppColors.accent : AppColors.cardBg,
        foregroundColor: isSelected ? Colors.white : AppColors.textLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => _toggleCategoryFilter(category),
      child: Text(
        category,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final name = animal['name'] ?? 'Unknown Animal';
    final category = animal['category'] ?? 'Unknown';
    final image = animal['image'] ?? 'https://via.placeholder.com/150';
    final isUrgent = animal['isUrgent'] ?? false;
    final headCount = animal['count'] ?? 0;
    final location = animal['AreaCageNumber'] ?? 'No location';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimalDetailsScreen(
                animalId: animal['firebaseId'], // Pass the Firebase ID
                userRole: widget.role,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(image),
                backgroundColor: AppColors.accent.withOpacity(0.1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      maxLines: 1, // Limit to 1 line
                      overflow:
                          TextOverflow.ellipsis, // Add ellipsis if truncated
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1, // Limit to 1 line
                            overflow: TextOverflow.ellipsis, // Add ellipsis
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        Expanded(
                          child: Text(
                            'Area $location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1, // Limit to 1 line
                            overflow: TextOverflow.ellipsis, // Add ellipsis
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Head Count: $headCount',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.role == 'HeadVet' ||
                  widget.role == 'AssistantVet') ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accent),
                  onPressed: () => _showEditAnimalDialog(animal),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.report_problem, color: AppColors.error),
                onPressed: () => _handleEmergency(animal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAnimalDialog(Map<String, dynamic> animal) {
    final nameController = TextEditingController(text: animal['name']);
    final areaController =
        TextEditingController(text: animal['AreaCageNumber']);
    String selectedCategory = animal['category'];
    File? selectedImageFile;
    String? currentImageUrl = animal['image'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Edit Animal',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Selection
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );

                        if (image != null) {
                          setState(() {
                            selectedImageFile = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: selectedImageFile != null
                                ? FileImage(selectedImageFile!) as ImageProvider
                                : NetworkImage(currentImageUrl ??
                                    'https://via.placeholder.com/150'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white.withOpacity(0.7),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Basic Fields
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['Avian', 'Mammal', 'Reptile']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: areaController,
                      decoration: InputDecoration(
                        labelText: 'Area/Cage Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  onPressed: () => _updateAnimal(
                    context,
                    animal['firebaseId'],
                    {
                      'name': nameController.text,
                      'category': selectedCategory,
                      'AreaCageNumber': areaController.text,
                      'selectedImageFile': selectedImageFile,
                      'currentImageUrl': currentImageUrl,
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateAnimal(BuildContext context, String animalId,
      Map<String, dynamic> updatedData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const Center(child: CircularProgressIndicator()),
      );

      // Handle image upload if new image selected
      String? imageUrl = updatedData['currentImageUrl'];
      if (updatedData['selectedImageFile'] != null) {
        imageUrl = await _uploadImage(updatedData['selectedImageFile']);
        if (imageUrl == null) {
          Navigator.pop(context); // Dismiss loading
          return;
        }
      }

      // Prepare data for update
      final finalData = {
        'name': updatedData['name'],
        'category': updatedData['category'],
        'AreaCageNumber': updatedData['AreaCageNumber'],
      };

      if (imageUrl != null) {
        finalData['image'] = imageUrl;
      }

      // Update in Firebase
      await FirebaseDatabase.instance
          .ref()
          .child('animals')
          .child(animalId)
          .update(finalData);

      // Close dialogs and show success message
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      Navigator.pop(context); // Dismiss edit dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Animal updated successfully',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh the list
      _fetchAnimals();
    } catch (e) {
      debugPrint('Error updating animal: $e');
      if (!context.mounted) return;

      // Dismiss loading if showing
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating animal: $e',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
