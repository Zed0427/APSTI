import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:albaypark/features/head_veterinarian/presentation/reports/autopsy_report_form.dart';
import 'package:albaypark/features/head_veterinarian/presentation/reports_form.dart';
import '../../../themes.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String reportType = 'Necropsy Report';
  bool isSubmitting = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> reportTypes = [
    'Necropsy Report',
  ];

  ReportForm? _currentForm;

  @override
  void initState() {
    super.initState();
    _setCurrentForm(reportType);
  }

  void _setCurrentForm(String type) {
    setState(() {
      switch (type) {
        case 'Necropsy Report':
          _currentForm = AutopsyReportForm(); // Regular constructor
          break;
        default:
          _currentForm = null;
      }
    });
  }

  Future<void> _submitReport() async {
    if (_currentForm != null && !isSubmitting) {
      if (_currentForm!.formKey.currentState?.validate() ?? false) {
        try {
          setState(() {
            isSubmitting = true;
          });

          final formData = _currentForm!.getFormData();

          // Print for debugging
          debugPrint('Form Data: $formData');

          // Make sure we have required fields
          if (formData.isEmpty) {
            throw Exception('No form data available');
          }

          final report = {
            'type': reportType,
            'date': DateTime.now().toIso8601String(),
            'author': 'logged_user@example.com',
            'createdAt': ServerValue.timestamp,
            ...formData,
          };

          // Create a new reference for the report
          final newReportRef = _database.child('reports').push();

          // Save the report with the generated ID
          await newReportRef.set(report);

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(
                  'Report Submitted',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Your report has been submitted successfully.',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          _showErrorDialog('Error submitting report: $e');
        } finally {
          if (mounted) {
            setState(() {
              isSubmitting = false;
            });
          }
        }
      } else {
        _showErrorDialog('Please fill in all required fields correctly.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Report',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Type',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: reportType,
                items: reportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      reportType = value;
                      _setCurrentForm(value);
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  labelText: 'Select Report Type',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              if (_currentForm != null) _currentForm!,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Report',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
