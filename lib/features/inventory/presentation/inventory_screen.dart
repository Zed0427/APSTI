import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppColors {
  static const background = Color(0xFFF5F5F5);
  static const cardBg = Color(0xFFFFFFFF);
  static const text = Color(0xFF333333);
  static const textLight = Color(0xFF888888);
  static const accent = Color(0xFF6C63FF);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE63946);
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> inventoryItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  Map<String, Map<String, dynamic>> animals = {};
  final _database = FirebaseDatabase.instance.ref();
  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchInventoryData();
  }

  Future<void> fetchInventoryData() async {
    try {
      // Fetch animals
      final animalsSnapshot = await _database.child('animals').get();
      if (animalsSnapshot.exists) {
        final data = Map<String, dynamic>.from(animalsSnapshot.value as Map);
        animals = data.map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }

      // Fetch inventory
      final inventorySnapshot = await _database.child('inventory').get();
      if (inventorySnapshot.exists) {
        final data = Map<String, dynamic>.from(inventorySnapshot.value as Map);
        final List<Map<String, dynamic>> items = data.entries.map((entry) {
          final item = Map<String, dynamic>.from(entry.value);
          final assignedAnimals = (item['animalAssigned'] as List)
              .map((id) => id as String)
              .toList();

          final animalNames = assignedAnimals
              .map((id) => animals[id]?['name'] ?? 'Unknown')
              .toList();

          return {
            ...item,
            'id': entry.key,
            'animalNames': animalNames.join(', '),
          };
        }).toList();

        setState(() {
          inventoryItems = items;
          filteredItems = items;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void filterItems() {
    setState(() {
      filteredItems = inventoryItems.where((item) {
        final matchesSearch = item['description']
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
        final matchesFilter = selectedFilter == 'All' ||
            item['unit'].toLowerCase() == selectedFilter.toLowerCase();
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _addOrEditInventory({
    Map<String, dynamic>? existingItem,
    required bool isEdit,
  }) async {
    final descriptionController = TextEditingController(
      text: existingItem?['description'] ?? '',
    );
    final prQtyController = TextEditingController(
      text: existingItem?['prQty']?.toString() ?? '',
    );
    final actualQtyController = TextEditingController(
      text: existingItem?['actualQty']?.toString() ?? '',
    );
    String selectedUnit = existingItem?['unit'] ?? 'Pcs';
    final lbNoController = TextEditingController(
      text: existingItem?['lbNo'] ?? '',
    );
    final mfgDateController = TextEditingController(
      text: existingItem?['mfgDate'] ?? '',
    );
    final expController = TextEditingController(
      text: existingItem?['exp'] ?? '',
    );
    List<String> selectedAnimals = List<String>.from(
      existingItem?['animalAssigned'] ?? [],
    );

    Future<void> _selectDate(TextEditingController controller) async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        controller.text =
            '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'Edit Inventory' : 'Add Inventory',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: prQtyController,
                      decoration:
                          const InputDecoration(labelText: 'PR Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: actualQtyController,
                      decoration:
                          const InputDecoration(labelText: 'Actual Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: ['Pcs', 'Box', 'Bot'].map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnit = value ?? 'Pcs';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lbNoController,
                      decoration: const InputDecoration(labelText: 'L/B No.'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mfgDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Manufacture Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(mfgDateController),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Expiration Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(expController),
                    ),
                    const SizedBox(height: 12),
                    const Text('Assign to Animals:'),
                    Wrap(
                      spacing: 8.0,
                      children: animals.entries.map((entry) {
                        final isSelected = selectedAnimals.contains(entry.key);
                        return FilterChip(
                          label: Text(entry.value['name']),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedAnimals.add(entry.key);
                              } else {
                                selectedAnimals.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final itemData = {
                      "description": descriptionController.text,
                      "prQty": int.tryParse(prQtyController.text) ?? 0,
                      "actualQty": int.tryParse(actualQtyController.text) ?? 0,
                      "unit": selectedUnit,
                      "lbNo": lbNoController.text,
                      "mfgDate": mfgDateController.text,
                      "exp": expController.text,
                      "animalAssigned": selectedAnimals,
                    };

                    if (isEdit) {
                      await _database
                          .child('inventory/${existingItem!['id']}')
                          .set(itemData);
                    } else {
                      await _database.child('inventory').push().set(itemData);
                    }

                    fetchInventoryData();
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteInventory(String id) async {
    await _database.child('inventory/$id').remove();
    fetchInventoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBg,
        title: Text(
          'Inventory Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _addOrEditInventory(isEdit: false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Filter Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filterItems();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.textLight),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ['All', 'Pcs', 'Box', 'Bot']
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value ?? 'All';
                      filterItems();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.poppins(color: AppColors.text),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildInventoryCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            'No inventory items available.',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item['description'],
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Qty: ${item['actualQty']} | Exp: ${item['exp']}\nAnimals: ${item['animalNames']}',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _addOrEditInventory(existingItem: item, isEdit: true);
            } else if (value == 'delete') {
              _deleteInventory(item['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ).animate().fadeIn().slideX(),
    );
  }
}
