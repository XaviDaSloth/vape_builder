import 'package:flutter/material.dart';
import 'package:vape_builder/widgets/item_dialogs.dart'; // Import the dialog
import 'package:vape_builder/widgets/card_widget.dart';
import 'package:vape_builder/widgets/main_layout.dart'; // Import the custom card widget
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VapeMods extends StatefulWidget {
  const VapeMods({super.key});

  @override
  State<VapeMods> createState() => _VapeModsState();
}

class _VapeModsState extends State<VapeMods> {
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
    print("Loading vape mods inventory...");

    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox');
    }

    var box = await Hive.box('inventoryBox');
    var savedInventory = box.get('inventory') as List<dynamic>?;

    if (savedInventory != null) {
      setState(() {
        _vapeModsInventory = savedInventory
            .where((item) => item["category"] == "Vape Mods")
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    }
    print("Vape Mods loaded: ${_vapeModsInventory.length}");
  }

  // Sample vape mod data
  String _getVaporLabel(double value) {
    if (value == 0) return "Any";
    if(value == 1) return "Low";
    if (value == 2) return "Medium";
    return "High";
  }

  List<FilterOption> filterOptions = [
    FilterOption(label: "Mod Type", options: ["Any", "Box Mod", "Tube Mod", "Squonk Mod"]),
    FilterOption(label: "Atomizer Type", options: ["Any", "RDA", "RTA", "Sub-Ohm Tank"]),
    FilterOption(label: "Coil Type", options: ["Any", "Single Coil", "Dual Coil", "Mesh Coil"]),
    FilterOption(label: "Battery Type", options: ["Any", "Single", "Dual", "Built-in"]),
    FilterOption(label: "Build Material", options: ["Any", "Stainless Steel", "Aluminum", "Plastic"]),
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
        // Map<String, String> tempSelectedFilters = {};
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
                              color: Color(0xFF41378B), // Custom label color
                              fontWeight: FontWeight.bold,
                            ),
                            contentPadding: EdgeInsets.all(4),
                          ),
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 214, 214, 214),
                          ),
                          value: filter.selectedValue ?? filter.options.first, // Default to the first option
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
                              _selectedFilters[filter.label] = newValue ?? "Any"; // Store selected value
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
                          divisions: 3, // Low (0), Medium (1), High (2)
                          label: _getVaporLabel(tempVaporProduction),
                          onChanged: (value) {
                            setModalState(() {
                              tempVaporProduction = value; // Update temp value
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
                            // _selectedFilters = tempSelectedFilters;
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
    String query = _searchQuery.toLowerCase();

    // Ensure filters have default values before filtering
    for (var filter in filterOptions) {
      _selectedFilters.putIfAbsent(filter.label, () => filter.options.first);
    }

    return _vapeModsInventory.where((mod) {
      if (query.isNotEmpty && !mod["name"].toLowerCase().contains(query)) return false;
      if (_vaporProduction > 0 && mod["vapor"] != _vaporProduction) return false;

      for (var filter in filterOptions) {
        String selectedValue = _selectedFilters[filter.label] ?? "Any";
        if (selectedValue != "Any") {
          String modKey = filter.label.toLowerCase().replaceAll(" ", "_");
          if (!mod[modKey].toString().toLowerCase().contains(selectedValue.toLowerCase())) return false;
        }
      }
      return true;
    }).toList();
  }




  @override
  Widget build(BuildContext context) {
    int crossAxisCount = (MediaQuery.of(context).size.width ~/ 200).clamp(2, 4);

    
    // Get the filtered list of vape mods
    List<Map<String, dynamic>> filteredVapeMods = _filterVapeMods();
    // print(filteredVapeMods);
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
              Center(child: Text("Vape Mods", style: Theme.of(context).textTheme.headlineMedium)),
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