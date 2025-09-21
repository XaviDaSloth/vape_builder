import 'package:flutter/material.dart';
import 'package:vape_builder/widgets/item_dialogs.dart'; // Import the dialog
import 'package:vape_builder/widgets/card_widget.dart';
import 'package:vape_builder/widgets/main_layout.dart'; // Import the custom card widget
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PodSystems extends StatefulWidget {
  const PodSystems({super.key});

  @override
  State<PodSystems> createState() => _PodSystemsState();
}

class _PodSystemsState extends State<PodSystems> {
  double _vaporProduction = 0; // Default value
  Map<String, String> _selectedFilters = {}; // Stores selected filter values
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _vapeModsInventory = [];
 
  @override
  void initState() {
    super.initState();
    _loadVapeMods(); // ✅ Load inventory data on startup
  }

  Future<void> _loadVapeMods() async {
    debugPrint("Loading vape inventory...");
    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox'); 
    }

    var box = Hive.box('inventoryBox');
    List<dynamic>? savedInventory = box.get('inventory');

    if (savedInventory != null) {
      debugPrint("Loading vape inventory...");
      setState(() {
        _vapeModsInventory = savedInventory
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .where((item) => item["category"] == "Pod Systems") // ✅ Filter only Vape Mods
            .toList();
      });
    }

  }

  String _getVaporLabel(double value) {
    if (value == 0) return "Any";
    if (value == 1) return "Low";
    if (value == 2) return "Medium";
    return "High";
  }

  List<FilterOption> filterOptions = [
    FilterOption(label: "Brand", options: ["Any", "Voopoo", "Smok", "GeekVape", "Uwell", "Lost Vape"]),
    FilterOption(label: "Pod System Type", options: ["Any", "Closed System", "Open System", "Refillable"]),
    FilterOption(label: "Battery Life", options: ["Any", "Short", "Moderate", "Long"]),
    FilterOption(label: "Nicotine Type", options: ["Any", "Salt Nic", "Freebase", "Hybrid"]),
  ];

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double tempVaporProduction = _vaporProduction;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Filters", style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: filterOptions.map((filter) {
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: filter.label,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            labelStyle: GoogleFonts.raleway(
                              fontSize: 16,
                              color: const Color(0xFF41378B),
                              fontWeight: FontWeight.bold,
                            ),
                            contentPadding: const EdgeInsets.all(4),
                          ),
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.normal,
                            color: const Color.fromARGB(255, 214, 214, 214),
                          ),
                          value: filter.selectedValue ?? filter.options.first,
                          dropdownColor: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(9),
                          items: filter.options.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setModalState(() {
                              filter.selectedValue = newValue;
                              _selectedFilters[filter.label] = newValue ?? "Any";
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vapor Production: ${_getVaporLabel(tempVaporProduction)}"),
                        Slider(
                          value: tempVaporProduction,
                          min: 0,
                          max: 3,
                          divisions: 3,
                          label: _getVaporLabel(tempVaporProduction),
                          onChanged: (value) {
                            setModalState(() {
                              tempVaporProduction = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _vaporProduction = tempVaporProduction;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Apply Filters"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterVapeMods() {
    return _vapeModsInventory.where((mod) {
      if (_searchQuery.isNotEmpty && !mod["name"].toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false; // Filter by search query
      }

      if (_vaporProduction == 1 && mod["vapor"] != 1) return false;
      if (_vaporProduction == 2 && mod["vapor"] != 2) return false;
      if (_vaporProduction == 3 && mod["vapor"] != 3) return false;

      for (var filter in filterOptions) {
        String selectedValue = _selectedFilters[filter.label] ?? "Any";
        if (selectedValue != "Any") {
          String modKey = filter.label.toLowerCase().replaceAll(" ", "_");
          if (mod[modKey] != selectedValue) return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    List<Map<String, dynamic>> filteredVapeMods = _filterVapeMods();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _loadVapeMods(); // ✅ Reload VapeMods when returning
        }
      },
      child: MainLayout(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text("Pod Systems", style: Theme.of(context).textTheme.headlineMedium)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.filter_list),
                    label: const Text("Filters"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  itemCount: filteredVapeMods.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredVapeMods[index];
                    return CustomCard(
                      label: item["name"],
                      imagePath: item["image"],
                      onTap: () {
                        showItemDetails(context, item["name"].toString(),item["name"], item["description"], item["image"], item["stocks"],item["price"]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class FilterOption {
  final String label;
  final List<String> options;
  String? selectedValue; // Holds the selected value

  FilterOption({required this.label, required this.options, this.selectedValue});
}