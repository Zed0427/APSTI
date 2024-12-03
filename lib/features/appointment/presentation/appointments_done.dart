import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../themes.dart';

class AppointmentsDoneScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> users;
  final Map<String, Map<String, dynamic>> animals;

  const AppointmentsDoneScreen({
    super.key,
    required this.users,
    required this.animals,
  });

  @override
  State<AppointmentsDoneScreen> createState() => _AppointmentsDoneScreenState();
}

class _AppointmentsDoneScreenState extends State<AppointmentsDoneScreen> {
  final List<Map<String, dynamic>> _doneAppointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  bool isLoading = true;
  String _searchQuery = '';
  String _selectedMonth = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDoneAppointments();
  }

  void _filterAppointments() {
    setState(() {
      _filteredAppointments = _doneAppointments.where((appointment) {
        // Search filter
        final matchesSearch = appointment['title']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (appointment['animals'] as List).any((animal) => animal['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()));

        // Date filter
        final matchesDate = _selectedMonth.isEmpty ||
            appointment['date'].toString() == _selectedMonth;

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _fetchDoneAppointments() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('appointments').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _doneAppointments.clear();

        for (var entry in data.entries) {
          final appointment = Map<String, dynamic>.from(entry.value);
          if (appointment['status'] == 'done') {
            appointment['id'] = entry.key;

            if (appointment['animals'] is List) {
              List<dynamic> animalIds = List.from(appointment['animals']);
              List<Map<String, dynamic>> resolvedAnimals = [];

              for (var animalId in animalIds) {
                final animalSnapshot =
                    await ref.child('animals/$animalId').get();
                if (animalSnapshot.exists) {
                  final animalData =
                      Map<String, dynamic>.from(animalSnapshot.value as Map);
                  resolvedAnimals.add({
                    'id': animalId,
                    'name': animalData['name'] ?? 'Unknown Animal'
                  });
                }
              }
              appointment['animals'] = resolvedAnimals;
            }

            _doneAppointments.add(appointment);
          }
        }

        _filteredAppointments = List.from(_doneAppointments);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching done appointments: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Completed Appointments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search appointments...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _filterAppointments();
                            });
                          },
                        ).animate().fadeIn().slideX(),

                        const SizedBox(height: 16),

                        // Month Filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _selectedMonth.isEmpty,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedMonth = '';
                                    _filterAppointments();
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                avatar:
                                    const Icon(Icons.calendar_today, size: 16),
                                label: Text(_selectedMonth.isEmpty
                                    ? 'Select Date'
                                    : _selectedMonth),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2025),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.accent,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (picked != null) {
                                    setState(() {
                                      // Format date as YYYY-MM-DD to match appointment date format
                                      _selectedMonth =
                                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                      _filterAppointments();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideX(),
                      ],
                    )),

                // Appointments List
                Expanded(
                  child: _filteredAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _selectedMonth.isNotEmpty
                                    ? 'No appointments completed on $_selectedMonth'
                                    : _searchQuery.isNotEmpty
                                        ? 'No appointments match your search'
                                        : 'No completed appointments found',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _filteredAppointments[index];
                            final animalList = (appointment['animals'] as List)
                                .map((animal) => animal['name'])
                                .join(', ');

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Row(
                                  children: [
                                    const Icon(Icons.event_available,
                                        color: AppColors.success),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        appointment['title'] ?? 'Untitled',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(left: 34),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            appointment['date'],
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (animalList.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.pets,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                animalList,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().slideX(
                                duration: Duration(
                                    milliseconds: 200 + (index * 100)));
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
