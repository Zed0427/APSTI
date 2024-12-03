import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../themes.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _specialtyController;
  late TextEditingController _experienceController;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _specialtyController = TextEditingController();
    _experienceController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    try {
      final userId =
          widget.user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          // Update controllers with latest data
          _nameController.text = _userData['name'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';
          _addressController.text = _userData['address'] ?? '';
          _specialtyController.text = _userData['specialty'] ?? '';
          _experienceController.text = _userData['experience'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId =
          widget.user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User ID not found');

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'email': widget.user['email'],
        'role': widget.user['role'],
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'experience': _experienceController.text.trim(),
        'lastUpdated': ServerValue.timestamp,
      };

      final userRef =
          FirebaseDatabase.instance.ref().child('users').child(userId);
      await userRef.update(updateData);

      // Reload user data after saving
      await _loadUserData();

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              validator: validator ??
                  (value) {
                    if (value?.isEmpty ?? true) return 'This field is required';
                    return null;
                  },
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.text.isEmpty ? 'Not specified' : controller.text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildRoleSpecificFields() {
    switch (widget.user['role']) {
      case 'HeadVet':
      case 'AssistantVet':
        return Column(
          children: [
            _buildProfileField(
              label: 'Medical Specialty',
              controller: _specialtyController,
              validator: (value) => null, // Make it optional
            ),
            _buildProfileField(
              label: 'Years of Experience',
              controller: _experienceController,
              validator: (value) => null, // Make it optional
            ),
          ],
        );
      case 'CaretakerA':
        return Column(
          children: [
            _buildProfileField(
              label: 'Assigned Section (Avian)',
              controller: _specialtyController,
              validator: (value) => null,
            ),
            _buildProfileField(
              label: 'Work Experience',
              controller: _experienceController,
              validator: (value) => null,
            ),
          ],
        );
      case 'CaretakerB':
        return Column(
          children: [
            _buildProfileField(
              label: 'Assigned Section (Mammal)',
              controller: _specialtyController,
              validator: (value) => null,
            ),
            _buildProfileField(
              label: 'Work Experience',
              controller: _experienceController,
              validator: (value) => null,
            ),
          ],
        );
      case 'CaretakerC':
        return Column(
          children: [
            _buildProfileField(
              label: 'Assigned Section (Reptile)',
              controller: _specialtyController,
              validator: (value) => null,
            ),
            _buildProfileField(
              label: 'Work Experience',
              controller: _experienceController,
              validator: (value) => null,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.accent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.accent,
                        AppColors.accent.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ).animate().scale(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    if (_isEditing) {
                                      _saveProfile();
                                    } else {
                                      setState(() => _isEditing = true);
                                    }
                                  },
                            icon: Icon(
                              _isEditing ? Icons.save : Icons.edit,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Full Name',
                        controller: _nameController,
                      ),
                      _buildProfileField(
                        label: 'Email',
                        controller:
                            TextEditingController(text: widget.user['email']),
                        validator: null,
                      ),
                      _buildProfileField(
                        label: 'Phone',
                        controller: _phoneController,
                      ),
                      _buildProfileField(
                        label: 'Address',
                        controller: _addressController,
                        maxLines: 2,
                      ),
                      const Divider(height: 32),
                      Text(
                        'Professional Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildRoleSpecificFields(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            bool confirmed = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    'Confirm Logout',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  content: Text(
                                    'Are you sure you want to logout?',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('Cancel',
                                          style: GoogleFonts.poppins()),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text(
                                        'Logout',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == null || !confirmed) return;

                            await FirebaseAuth.instance.signOut();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
