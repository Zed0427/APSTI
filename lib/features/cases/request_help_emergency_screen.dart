import 'package:flutter/material.dart';
import '../../../data/mock/mock_data.dart';

class RequestHelpEmergencyScreen extends StatelessWidget {
  const RequestHelpEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    String priority = 'normal'; // Default priority level
    List<String> selectedAnimals = [];
    final List<Map<String, dynamic>> availableAnimals = [
      {'id': 1, 'name': 'Lovebird A'},
      {'id': 2, 'name': 'Cassowary A'},
      {'id': 3, 'name': 'Python A'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Help Emergency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              const Text(
                'Title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Title',
                ),
              ),
              const SizedBox(height: 16),

              // Priority Selection
              const Text(
                'Priority Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'normal',
                      groupValue: priority,
                      title: const Text('Normal'),
                      onChanged: (value) {
                        if (value != null) priority = value;
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'high',
                      groupValue: priority,
                      title: const Text('Urgent'),
                      onChanged: (value) {
                        if (value != null) priority = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animals Selection
              const Text(
                'Select Animals (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: availableAnimals.map((animal) {
                  return FilterChip(
                    label: Text(animal['name']),
                    selected: selectedAnimals.contains(animal['name']),
                    onSelected: (isSelected) {
                      if (isSelected) {
                        selectedAnimals.add(animal['name']);
                      } else {
                        selectedAnimals.remove(animal['name']);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Description Field
              const Text(
                'Detailed Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Provide details',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Location Field
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Location',
                ),
              ),
              const SizedBox(height: 16),

              // Upload Image
              const Text(
                'Upload Image (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement image upload functionality
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Image'),
                ),
              ),
              const SizedBox(height: 24),

              // Create Case Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Save the emergency request
                    final request = {
                      'id': 'req_${DateTime.now().millisecondsSinceEpoch}',
                      'title': titleController.text,
                      'information': descriptionController.text,
                      'location': locationController.text,
                      'priority': priority,
                      'animals': selectedAnimals,
                      'requestedBy': 'logged_user@example.com',
                      'status': 'pending',
                      'requestDate':
                          DateTime.now().toIso8601String().split('T')[0],
                    };

                    mockRequests.add(request);

                    // Confirmation Dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Request Submitted'),
                        content: const Text(
                            'Your request has been submitted successfully.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
