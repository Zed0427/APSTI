import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../themes.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final DateTime date;
  final List<Map<String, dynamic>> appointments;
  final VoidCallback onAddAppointment;
  final Map<DateTime, List<Map<String, dynamic>>> appointmentsByDate;
  final VoidCallback onAppointmentStatusChanged;
  final String userRole;
  final Function(DateTime, Map<String, dynamic>) onCancelAppointment; // New

  final Function(String) getAnimalById;

  const AppointmentDetailsScreen({
    super.key,
    required this.date,
    required this.appointments,
    required this.onAddAppointment,
    required this.appointmentsByDate,
    required this.onAppointmentStatusChanged,
    required this.userRole,
    required this.onCancelAppointment,
    required this.getAnimalById, // Add this
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final assignedPerson = appointment['assignedPerson'] is Map
        ? appointment['assignedPerson']
        : {'name': 'Unknown', 'role': 'Unknown'};

    final animalList = (appointment['animals'] is List)
        ? (appointment['animals'] as List).map((animal) {
            if (animal is String) {
              return widget.getAnimalById(animal)['name'] ?? 'Unknown Animal';
            } else if (animal is Map && animal['name'] != null) {
              return animal['name'];
            } else {
              return 'Unknown Animal';
            }
          }).join(', ')
        : 'Unknown Animal';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          appointment['title'] ?? 'Appointment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: appointment['date'] ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Time',
                value: appointment['time'] ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.person,
                label: 'Assigned To',
                value: '${assignedPerson['name']} (${assignedPerson['role']})',
              ),
              if (animalList.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.pets,
                  label: 'Animals',
                  value: animalList,
                ),
              _buildStatusBadge(appointment['status'] ?? 'pending'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: AppColors.accent),
            ),
          ),
          if (appointment['status'] == 'approved' ||
              appointment['status'] == 'pending')
            ElevatedButton(
              onPressed: () async {
                try {
                  // Call the cancellation method
                  await widget.onCancelAppointment(
                    widget.date,
                    appointment,
                  );

                  if (!mounted) return;

                  // Update UI and show success SnackBar
                  setState(() {
                    Navigator.pop(context); // Close the details dialog
                  });
                } catch (error, stackTrace) {
                  // Log the error for debugging purposes
                  debugPrint('Error cancelling appointment: $error');
                  debugPrintStack(stackTrace: stackTrace);

                  // Show error SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to cancel appointment. Try again.',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(12),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Cancel Appointment',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'approved'
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  @override
  Widget build(BuildContext context) {
    // Filter appointments to include only those with status 'approved'
    final filteredAppointments = widget.appointments
        .where((appointment) => appointment['status'] == 'approved')
        .toList();

    final sortedAppointments =
        List<Map<String, dynamic>>.from(filteredAppointments)
          ..sort((a, b) {
            final aTime = a['time'] ?? '';
            final bTime = b['time'] ?? '';
            return aTime.compareTo(bTime);
          });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: sortedAppointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No approved appointments for this date',
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
              padding: const EdgeInsets.all(16),
              itemCount: sortedAppointments.length,
              itemBuilder: (context, index) {
                final appointment = sortedAppointments[index];

                // Extract assignedPerson and animals correctly
                final assignedPerson = appointment['assignedPerson'] is Map
                    ? appointment['assignedPerson']['name']
                    : appointment['assignedPerson'] ?? 'N/A';
                final animalList = (appointment['animals'] is List)
                    ? (appointment['animals'] as List)
                        .map((animal) => animal is Map && animal['name'] != null
                            ? animal['name']
                            : 'Unknown Animal')
                        .join(', ')
                    : 'Unknown Animal';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showAppointmentDetails(appointment),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  appointment['title'] ?? 'Untitled',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(
                                  appointment['status'] ?? 'pending'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                appointment['time'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  assignedPerson,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (appointment['animals'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.pets,
                                  size: 16,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    animalList,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddAppointment,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Appointment',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}
