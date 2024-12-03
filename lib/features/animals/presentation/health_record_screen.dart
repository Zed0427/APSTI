import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../themes.dart';

class HealthRecordScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const HealthRecordScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // Extract record details with fallback values
    final name = record['name'] ?? 'Unknown Name';
    final status = record['status'] ?? 'Unknown Status';
    final remarks = record['remarks'] ?? 'No remarks available';
    final lastCheckup = record['lastCheckup'] ?? 'Not recorded';
    final medications = record['medications'] ?? 'No medications';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBg,
        title: Text(
          '$name - Health Record',
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
            // Record Overview Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(label: 'Name', value: name),
                    _buildDetailRow(label: 'Status', value: status),
                    _buildDetailRow(label: 'Remarks', value: remarks),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health Details Section
            Text(
              'Health Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(label: 'Last Checkup', value: lastCheckup),
                    _buildDetailRow(label: 'Medications', value: medications),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
