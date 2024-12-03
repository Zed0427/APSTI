import 'dart:async';

import 'package:albaypark/features/appointment/presentation/_create_appointment_dialog.dart';
import 'package:albaypark/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../themes.dart';
import 'appointment_details_screen.dart'; // Import the new file

class AppointmentsScreen extends StatefulWidget {
  final String userRole;
  final String currentUser;
  final List<String> headVets;

  const AppointmentsScreen({
    super.key,
    required this.userRole,
    required this.currentUser,
    required this.headVets,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<DateTime, List<Map<String, dynamic>>> _appointments = {};
  final List<Map<String, dynamic>> _allAppointments = [];
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _animals = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupAppointmentNotifications(); // Remove this line
  }

  // Add these methods in the _AppointmentsScreenState class
  Future<void> _setupAppointmentNotifications() async {
    // Check and schedule notifications for all appointments
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndNotifyAppointments();
    });
  }

  Future<void> _checkAndNotifyAppointments() async {
    final now = DateTime.now();

    for (var appointments in _appointments.values) {
      for (var appointment in appointments) {
        if (appointment['status'] != 'approved') continue;

        try {
          final appointmentDate = DateTime.parse(appointment['date']);
          final timeStr = appointment['time'].toString().trim();

          debugPrint('Processing appointment time: $timeStr');

          // Parse time in "3:30 PM" format
          final RegExp timeRegex =
              RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
          final Match? match = timeRegex.firstMatch(timeStr);

          if (match != null) {
            final hour = int.parse(match.group(1)!);
            final minute = int.parse(match.group(2)!);
            final period = match.group(3)!.toUpperCase();

            // Convert to 24-hour format
            var scheduledHour = hour;
            if (period == 'PM' && hour != 12) {
              scheduledHour += 12;
            } else if (period == 'AM' && hour == 12) {
              scheduledHour = 0;
            }

            final scheduledTime = DateTime(
              appointmentDate.year,
              appointmentDate.month,
              appointmentDate.day,
              scheduledHour,
              minute,
            );

            debugPrint('Parsed time components:');
            debugPrint('Hour: $hour');
            debugPrint('Minute: $minute');
            debugPrint('Period: $period');
            debugPrint('Scheduled time: $scheduledTime');
            debugPrint('Current time: $now');

            // Check for 30-minute reminder
            final reminderTime =
                scheduledTime.subtract(const Duration(minutes: 30));

            if (now.isAfter(reminderTime) && now.isBefore(scheduledTime)) {
              debugPrint('Sending 30-minute reminder');
              await _sendAppointmentNotification(appointment, isUpcoming: true);
            }

            // Check for start time notification
            if (now.isAtSameMomentAs(scheduledTime) ||
                (now.isAfter(scheduledTime) &&
                    now.isBefore(
                        scheduledTime.add(const Duration(minutes: 1))))) {
              debugPrint('Sending start time notification');
              await _sendAppointmentNotification(appointment,
                  isUpcoming: false);
            }
          } else {
            debugPrint('Failed to parse time string: $timeStr');
          }
        } catch (e) {
          debugPrint('Error processing appointment: $e');
          debugPrint('Appointment data: ${appointment.toString()}');
        }
      }
    }
  }

  Future<void> _sendAppointmentNotification(Map<String, dynamic> appointment,
      {required bool isUpcoming}) async {
    final title =
        isUpcoming ? 'Upcoming Appointment' : 'Appointment Starting Now';
    final time = appointment['time'].toString();

    final body = isUpcoming
        ? 'Your appointment "${appointment['title']}" starts in 30 minutes (scheduled for $time)'
        : 'Your appointment "${appointment['title']}" is starting now';

    try {
      await NotificationService.instance.sendNotification(
        title,
        body,
        isAppointment: true,
      );
      debugPrint('Successfully sent notification: $title - $body');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> _fetchData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();

    try {
      // Fetch users
      DataSnapshot usersSnapshot = await ref.child('users').get();
      if (usersSnapshot.exists) {
        Map<dynamic, dynamic> usersData =
            usersSnapshot.value as Map<dynamic, dynamic>;
        _users.clear();
        usersData.forEach((key, value) {
          _users[key] = Map<String, dynamic>.from(value);
        });
      }

      // Fetch animals
      DataSnapshot animalsSnapshot = await ref.child('animals').get();
      if (animalsSnapshot.exists) {
        Map<dynamic, dynamic> animalsData =
            animalsSnapshot.value as Map<dynamic, dynamic>;
        _animals.clear();
        animalsData.forEach((key, value) {
          _animals[key] = Map<String, dynamic>.from(value);
        });
      }

      // Fetch appointments
      DataSnapshot appointmentsSnapshot = await ref.child('appointments').get();
      if (appointmentsSnapshot.exists) {
        Map<dynamic, dynamic> appointmentsData =
            appointmentsSnapshot.value as Map<dynamic, dynamic>;
        _appointments.clear();
        _allAppointments.clear();

        appointmentsData.forEach((key, value) {
          Map<String, dynamic> appointment = Map<String, dynamic>.from(value);
          appointment['id'] =
              key; // Assign the database key as the appointment ID

          // Resolve assigned person
          if (appointment['assignedPerson'] is String) {
            final assignedPersonId = appointment['assignedPerson'];
            final assignedPerson = _users[assignedPersonId] ??
                {'name': 'Unknown', 'role': 'Unknown'};
            appointment['assignedPerson'] = {
              'id': assignedPersonId,
              'name': assignedPerson['name'],
              'role': assignedPerson['role'],
            };
          }

          // Resolve animals
          if (appointment['animals'] is List) {
            appointment['animals'] = (appointment['animals'] as List)
                .map((animalId) => {
                      'id': animalId,
                      'name': _animals[animalId]?['name'] ?? 'Unknown Animal',
                    })
                .toList();
          }

          // Add to appointments map
          DateTime date = DateTime.parse(appointment['date']);
          if (!_appointments.containsKey(date)) {
            _appointments[date] = [];
          }
          _appointments[date]!.add(appointment);
          _allAppointments.add(appointment);
        });
      }

      // Fetch caretaker requests
      DataSnapshot caretakerRequestsSnapshot =
          await ref.child('caretakerRequests').get();
      if (caretakerRequestsSnapshot.exists) {
        Map<dynamic, dynamic> caretakerRequestsData =
            caretakerRequestsSnapshot.value as Map<dynamic, dynamic>;
        caretakerRequestsData.forEach((key, value) {
          Map<String, dynamic> request = Map<String, dynamic>.from(value);
          request['id'] = key; // Assign the database key as the request ID
          _allAppointments.add(request);
        });
      }

      _allAppointments
          .removeWhere((appointment) => appointment['status'] == 'done');

      // Trigger UI update
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _markAppointmentDone(Map<String, dynamic> appointment) async {
    try {
      final appointmentId = appointment['id'];
      if (appointmentId == null) {
        throw Exception('Appointment ID is null');
      }

      DatabaseReference ref =
          FirebaseDatabase.instance.ref('appointments/$appointmentId');
      await ref.update({'status': 'done'});

      setState(() {
        appointment['status'] = 'done';
      });

      _showCustomSnackBar(
        message: 'Appointment marked as done!',
        color: AppColors.success,
        icon: Icons.check_circle,
      );
    } catch (e) {
      debugPrint('Error marking appointment as done: $e');
      _showCustomSnackBar(
        message: 'Error updating appointment status',
        color: AppColors.error,
        icon: Icons.error_outline,
      );
    }
  }

  List<Map<String, dynamic>> _getAppointmentsForDate(DateTime date) {
    return _appointments[date] ?? [];
  }

  Map<String, dynamic> getUserById(String id) {
    return _users[id] ?? {'name': 'Unknown', 'role': 'Unknown'};
  }

  Map<String, dynamic> getAnimalById(String id) {
    return _animals[id] ?? {'name': 'Unknown Animal'};
  }

  void _cancelAppointment(
      DateTime date, Map<String, dynamic> appointment) async {
    try {
      debugPrint("Cancelling appointment: ${appointment['id']}");
      final appointmentId = appointment['id'];

      // Notify about cancellation
      await NotificationService.instance.sendNotification(
        'Appointment Cancelled',
        'The appointment "${appointment['title']}" has been cancelled.',
        isAppointment: true,
      );

      // Reference to the appointment in Firebase
      DatabaseReference ref =
          FirebaseDatabase.instance.ref('appointments/$appointmentId');

      // Attempt to remove the appointment
      await ref.remove();

      // Update UI state
      setState(() {
        _appointments[date]?.remove(appointment);
        _allAppointments.remove(appointment);
      });

      // Display success SnackBar
      _showCustomSnackBar(
        message: 'Appointment cancelled successfully.',
        color: AppColors.warning,
        icon: Icons.event_busy,
      );
    } catch (error) {
      debugPrint('Error cancelling appointment: $error');
      _showCustomSnackBar(
        message: 'Failed to cancel appointment. Please try again.',
        color: AppColors.error,
        icon: Icons.error_outline,
      );
    }
  }

  bool _isTimeSlotAvailable(DateTime date, String time,
      {String? excludeAppointmentId}) {
    for (var appointment in _allAppointments) {
      try {
        final appointmentDate = DateTime.parse(appointment['date']);
        if (isSameDay(appointmentDate, date) &&
            appointment['time'] == time &&
            appointment['id'] != excludeAppointmentId &&
            appointment['status'] == 'approved') {
          return false;
        }
      } catch (e) {
        debugPrint('Error checking appointment: $e');
      }
    }
    return true;
  }

  void _approveAppointment(Map<String, dynamic> appointment) async {
    try {
      final appointmentId = appointment['id'];
      if (appointmentId == null) {
        throw Exception('Appointment ID is null');
      }

      DatabaseReference ref;
      String newStatus;

      if (appointment['status'] == 'request') {
        ref = FirebaseDatabase.instance.ref('caretakerRequests/$appointmentId');
        newStatus = 'accepted';
        _showCreateAppointmentDialog(appointment);
      } else {
        ref = FirebaseDatabase.instance.ref('appointments/$appointmentId');
        newStatus = 'approved';

        try {
          final String dateStr = appointment['date'];
          final String timeStr = appointment['time'].trim();

          debugPrint('Raw time string: $timeStr');

          // First, try to parse time in "3:05 PM" format
          int hour;
          int minute = 0;
          String? period;

          // Split time components
          List<String> timeParts = timeStr.split(' ');
          if (timeParts.length == 2) {
            period = timeParts[1].toUpperCase();
            String timeComponent = timeParts[0];

            if (timeComponent.contains(':')) {
              // Format: "3:05" or "15:05"
              List<String> hourMin = timeComponent.split(':');
              hour = int.parse(hourMin[0]);
              minute = int.parse(hourMin[1]);
            } else {
              // Format: "3" or "15"
              hour = int.parse(timeComponent);
            }

            // Validate hour
            if (hour > 12) {
              hour = hour % 12;
            }

            // Convert to 24-hour format
            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }

            final scheduledTime = DateTime.parse(dateStr)
                .add(Duration(hours: hour, minutes: minute));
            final now = DateTime.now();

            debugPrint('\n=== Appointment Time Details ===');
            debugPrint('Raw time: $timeStr');
            debugPrint('Parsed hour: $hour');
            debugPrint('Parsed minute: $minute');
            debugPrint('Period: $period');
            debugPrint('Date: $dateStr');
            debugPrint('Scheduled time: $scheduledTime');
            debugPrint('Current time: $now');

            final timeUntilAppointment = scheduledTime.difference(now);
            final timeUntilReminder = scheduledTime
                .subtract(const Duration(minutes: 30))
                .difference(now);

            debugPrint(
                'Minutes until appointment: ${timeUntilAppointment.inMinutes}');
            debugPrint(
                'Minutes until reminder: ${timeUntilReminder.inMinutes}');

            // Send immediate confirmation
            await NotificationService.instance.sendNotification(
              'Appointment Scheduled',
              'Appointment "${appointment['title']}" scheduled for ${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${period}',
              isAppointment: true,
            );

            // Schedule 30-minute reminder
            if (timeUntilReminder.inMinutes > 0) {
              Timer(timeUntilReminder, () {
                NotificationService.instance.sendNotification(
                  'Appointment Reminder',
                  'Appointment "${appointment['title']}" starts in 30 minutes',
                  isAppointment: true,
                );
                debugPrint('Reminder notification sent at: ${DateTime.now()}');
              });
            }

            // Schedule start notification
            if (timeUntilAppointment.inMinutes > 0) {
              Timer(timeUntilAppointment, () {
                NotificationService.instance.sendNotification(
                  'Appointment Starting',
                  'Appointment "${appointment['title']}" is starting now',
                  isAppointment: true,
                );
                debugPrint('Start notification sent at: ${DateTime.now()}');
              });
            }
          } else {
            debugPrint('Invalid time format: $timeStr');
            throw FormatException('Invalid time format: $timeStr');
          }
        } catch (e) {
          debugPrint('Error scheduling notifications: $e');
        }
      }

      await ref.update({'status': newStatus});

      setState(() {
        appointment['status'] = newStatus;
      });

      _showCustomSnackBar(
        message:
            'Appointment ${newStatus == 'accepted' ? 'accepted' : 'approved'} successfully!',
        color: AppColors.success,
        icon: Icons.check_circle,
      );
    } catch (e) {
      debugPrint('Error approving appointment: $e');
      _showCustomSnackBar(
        message: 'Error approving appointment. Please try again.',
        color: AppColors.error,
        icon: Icons.error_outline,
      );
    }
  }

  void _showCreateAppointmentDialog(Map<String, dynamic> request) async {
    final newAppointment = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateAppointmentDialog(
        date: _selectedDate,
        existingAppointments: _getAppointmentsForDate(_selectedDate),
        userRole: widget.userRole,
        currentUser: widget.currentUser,
        headVets: widget.headVets,
        request: request,
      ),
    );

    if (!mounted || newAppointment == null) return;

    // Resolve assignedPerson to user ID
    final assignedPersonEmail = newAppointment['assignedPerson'];
    final assignedPersonId = _users.entries
        .firstWhere(
          (entry) => entry.value['email'] == assignedPersonEmail,
          orElse: () => MapEntry('', {}),
        )
        .key;

    if (assignedPersonId.isEmpty) {
      _showCustomSnackBar(
        message: 'Assigned person not found.',
        color: AppColors.error,
        icon: Icons.error,
      );
      return;
    }

    // Create appointment with correct format
    final appointment = {
      ...newAppointment,
      'assignedPerson': assignedPersonId, // Use user ID instead of email
    };
    appointment.remove('id'); // Remove the 'id' field if it's present

    // Save to Firebase
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('appointments').push();
    await ref.set(appointment);

    // Update local state
    setState(() {
      if (!_appointments.containsKey(_selectedDate)) {
        _appointments[_selectedDate] = [];
      }
      _appointments[_selectedDate]!.add({
        ...appointment,
        'assignedPerson': {
          'id': assignedPersonId,
          'name': _users[assignedPersonId]?['name'] ?? 'Unknown',
          'role': _users[assignedPersonId]?['role'] ?? 'Unknown',
        },
        'animals': appointment['animals']
            .map((animalId) => {
                  'id': animalId,
                  'name': getAnimalById(animalId)['name'],
                })
            .toList(),
      });
      _allAppointments.add(appointment);
    });

    _showCustomSnackBar(
      message: 'Appointment created successfully!',
      color: AppColors.success,
      icon: Icons.check_circle,
    );
  }

  void _rejectAppointment(
      DateTime date, Map<String, dynamic> appointment) async {
    try {
      final appointmentId = appointment['id']; // Ensure this is correctly set
      if (appointmentId == null) {
        throw Exception('Appointment ID is null');
      }

      DatabaseReference ref =
          FirebaseDatabase.instance.ref('appointments/$appointmentId');
      await ref.remove(); // Completely remove the appointment

      setState(() {
        _appointments[date]?.remove(appointment);
        _allAppointments.removeWhere((a) => a['id'] == appointmentId);
      });

      _showCustomSnackBar(
        message: 'Appointment rejected and removed.',
        color: AppColors.error,
        icon: Icons.cancel,
      );
    } catch (e) {
      debugPrint('Error rejecting appointment: $e');
      _showCustomSnackBar(
        message: 'Error rejecting appointment. Please try again.',
        color: AppColors.error,
        icon: Icons.error_outline,
      );
    }
  }

  void _createAppointment(DateTime date) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (date.isBefore(todayStart)) {
      _showCustomSnackBar(
        message: 'Cannot create appointments for past dates.',
        color: AppColors.warning,
        icon: Icons.warning,
      );
      return;
    }

    final newAppointment = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateAppointmentDialog(
        date: date,
        existingAppointments: _getAppointmentsForDate(date),
        userRole: widget.userRole,
        currentUser: widget.currentUser,
        headVets: widget.headVets,
      ),
    );

    if (!mounted || newAppointment == null) return;

    // Resolve assignedPerson to user ID
    final assignedPersonEmail = newAppointment['assignedPerson'];
    final assignedPersonId = _users.entries
        .firstWhere(
          (entry) => entry.value['email'] == assignedPersonEmail,
          orElse: () => MapEntry('', {}),
        )
        .key;

    if (assignedPersonId.isEmpty) {
      _showCustomSnackBar(
        message: 'Assigned person not found.',
        color: AppColors.error,
        icon: Icons.error,
      );
      return;
    }

    // Create appointment with correct format
    final appointment = {
      ...newAppointment,
      'assignedPerson': assignedPersonId, // Use user ID instead of email
    };
    appointment.remove('id'); // Remove the 'id' field if it's present

    // Save to Firebase
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('appointments').push();
    await ref.set(appointment);

    // Update local state
    setState(() {
      if (!_appointments.containsKey(date)) {
        _appointments[date] = [];
      }
      _appointments[date]!.add({
        ...appointment,
        'assignedPerson': {
          'id': assignedPersonId,
          'name': _users[assignedPersonId]?['name'] ?? 'Unknown',
          'role': _users[assignedPersonId]?['role'] ?? 'Unknown',
        },
        'animals': appointment['animals']
            .map((animalId) => {
                  'id': animalId,
                  'name': getAnimalById(animalId)['name'],
                })
            .toList(),
      });
      _allAppointments.add(appointment);
    });

    _showCustomSnackBar(
      message: 'Appointment created successfully!',
      color: AppColors.success,
      icon: Icons.check_circle,
    );
  }

  void _viewAppointments(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final approvedAppointments = _appointments[normalizedDate]
            ?.where((appointment) => appointment['status'] == 'approved')
            .toList() ??
        [];

    debugPrint(
        "Approved Appointments for $normalizedDate: $approvedAppointments");

    if (approvedAppointments.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentDetailsScreen(
            date: date,
            appointments: _allAppointments,
            onAddAppointment: () => _createAppointment(date),
            appointmentsByDate: _appointments,
            onAppointmentStatusChanged: () {
              setState(() {}); // Refresh UI if needed
            },
            userRole: widget.userRole,
            onCancelAppointment: _cancelAppointment, // Pass this function
            getAnimalById: getAnimalById, // Pass the method
          ),
        ),
      );
    } else {
      _showCustomSnackBar(
        message: 'No approved appointments for this date.',
        color: AppColors.warning,
        icon: Icons.info,
      );
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final assignedPerson = appointment['assignedPerson'] is Map
        ? appointment['assignedPerson']['name']
        : 'Unknown';

    final animalList = (appointment['animals'] is List)
        ? (appointment['animals'] as List).map((animal) {
            if (animal is String) {
              return getAnimalById(animal)['name'] ?? 'Unknown Animal';
            } else if (animal is Map && animal['name'] != null) {
              return animal['name'];
            } else {
              return 'Unknown Animal';
            }
          }).join(', ')
        : 'Unknown Animal';

    debugPrint("Assigned person: $assignedPerson");
    debugPrint("Animal list: $animalList");

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
                value: assignedPerson,
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
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'approved'
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : status == 'request'
                ? AppColors.accent
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCustomSnackBar({
    required String message,
    required Color color,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out appointments with status 'accepted'
    final filteredAppointments = _allAppointments
        .where((appointment) => appointment['status'] != 'accepted')
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Calendar Section (Visible to all roles)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TableCalendar(
                      firstDay: DateTime.now(), // Change this line
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _selectedDate,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDate, day),
                      calendarStyle: CalendarStyle(
                        disabledTextStyle: GoogleFonts.poppins(
                          color: AppColors.textLight.withOpacity(0.5),
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        markersMaxCount: 1,
                        markerSize: 8,
                        markerMargin: const EdgeInsets.only(top: 8),
                      ),
                      headerStyle: HeaderStyle(
                        titleTextStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      enabledDayPredicate: (day) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        return !day.isBefore(today);
                      },
                      eventLoader: (date) {
                        final normalizedDate =
                            DateTime(date.year, date.month, date.day);
                        final events =
                            _appointments[normalizedDate]?.where((appointment) {
                          return appointment['status'] == 'approved';
                        }).toList();

                        debugPrint(
                            "Events for $normalizedDate: $events"); // Debugging
                        return events ?? [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDate = selectedDay;
                        });

                        _viewAppointments(selectedDay);
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Empty State
            if (filteredAppointments.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 48,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Appointments',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Debug index value and type
                      debugPrint('Index: $index, Type: ${index.runtimeType}');

                      final appointment = filteredAppointments[index];
                      return AppointmentCard(
                        appointment: appointment,
                        userRole: widget.userRole,
                        onApprove: () => _approveAppointment(appointment),
                        onReject: () =>
                            _rejectAppointment(_selectedDate, appointment),
                        onCancel: () =>
                            _cancelAppointment(_selectedDate, appointment),
                        onTap: () => _showAppointmentDetails(appointment),
                        onDone: () => _markAppointmentDone(appointment),
                        index: index, // Ensure this is always an integer
                        users: _users, // Pass users map
                        animals: _animals, // Pass animals map
                      );
                    },
                    childCount: filteredAppointments.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createAppointment(_selectedDate),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Appointment',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.accent,
      ).animate().scale(delay: 800.ms),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String userRole;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onTap;
  final int index;
  final Map<String, Map<String, dynamic>> users;
  final Map<String, Map<String, dynamic>> animals;
  final VoidCallback onDone;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onDone,
    required this.userRole,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onTap,
    required this.index,
    required this.users,
    required this.animals,
  });

  @override
  Widget build(BuildContext context) {
    final animalId = appointment['animalId'];
    final headVetId = appointment['headVetId'];

    final animalName = animals[animalId]?['name'] ?? 'Unknown Animal';
    final headVetName = users[headVetId]?['name'] ?? 'Unknown Head Vet';

    if (appointment['status'] == 'request') {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['title'] ?? 'Untitled',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.pets, animalName),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, headVetName),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final assignedPersonId = appointment['assignedPerson'] is Map
          ? appointment['assignedPerson']['id']
          : appointment['assignedPerson'] is String
              ? appointment['assignedPerson']
              : null;

      final assignedPerson =
          users[assignedPersonId] ?? {'name': 'Unknown', 'role': 'Unknown'};

      final animalList = (appointment['animals'] is List)
          ? (appointment['animals'] as List).map((animal) {
              if (animal is Map && animal.containsKey('name'))
                return animal['name'];
              if (animal is String)
                return animals[animal]?['name'] ?? 'Unknown Animal';
              return 'Unknown Animal';
            }).join(', ')
          : 'Unknown Animal';

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                    _buildStatusBadge(appointment['status'] ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.calendar_today, appointment['date']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, appointment['time']),
                _buildInfoRow(Icons.person,
                    '${assignedPerson['name']} (${assignedPerson['role']})'),
                if (animalList.isNotEmpty)
                  _buildInfoRow(Icons.pets, animalList),
                if (appointment['status'] == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (userRole.toLowerCase() == 'headvet') ...[
                  if (appointment['status'] == 'approved') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: onDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Mark as Done',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'approved'
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : status == 'request'
                ? AppColors.accent
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

  Widget _buildInfoRow(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
