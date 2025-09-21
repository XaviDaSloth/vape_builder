import 'package:flutter/material.dart';
import 'package:vape_builder/widgets/item_dialogs.dart'; // Import the dialog
import 'package:vape_builder/widgets/card_widget.dart';
import 'package:vape_builder/widgets/main_layout.dart'; // Import the custom card widget
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';


class DisposableVapes extends StatefulWidget {
  const DisposableVapes({super.key});

  @override
  State<DisposableVapes> createState() => _DisposableVapes();
}

class _DisposableVapes extends State<DisposableVapes> {
  double _puffCount = 0; // Default value
  double _vaporIntensity = 0; // Default value
  Map<String, String> _selectedFilters = {}; // Stores selected filter values
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _vapeModsInventory = [];

  @override
  void initState() {
    super.initState();
    _loadVapeMods(); // ✅ Load inventory on startup
  }

  void _loadVapeMods() async {
    print("Loading vape mods inventory...");

    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox');
    }

    var box = Hive.box('inventoryBox');
    List<dynamic>? savedInventory = box.get('inventory');

    if (savedInventory != null) {
      setState(() {
        _vapeModsInventory = savedInventory
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .where((item) => item["category"] == "Vape Dispos") // ✅ Filter only Vape Mods
            .toList();
      });
    }
  }
  // Sample vape mod data

  String _getVaporLabel(double value) {
    if (value == 0) return "Any";
    if(value == 1) return "Low";
    if (value == 2) return "Medium";
    return "High";
  }

   List<FilterOption> filterOptions = [
    FilterOption(label: "Nicotine mg", options: ["Any", "10mg","20mg","30mg","40mg","50mg"]),
    FilterOption(label: "Brand", options: ["Any", "Brand A", "Brand B", "Brand C"]),
    FilterOption(label: "Size", options: ["Any", "Small", "Medium", "Large"]),
  ];

  

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double tempPuffCount = _puffCount;
        double tempVaporIntensity = _vaporIntensity;
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
                          value: _selectedFilters[filter.label] ?? filter.options.first, // Default to the first option
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
                        Text("Puff Count: $tempPuffCount"),
                        Slider(
                          value: tempPuffCount,
                          min: 0,
                          max: 20000,
                          divisions: 40, // Low (0), Medium (1), High (2)
                          label: "$tempPuffCount",
                          onChanged: (value) {
                            setModalState(() {
                              tempPuffCount = value; // Update temp value
                            });
                          },
                        ),
                        Text("Vapor Intensity: ${_getVaporLabel(tempVaporIntensity)}"),
                        Slider(
                          value: tempVaporIntensity,
                          min: 0,
                          max: 3,
                          divisions: 3, // Low (0), Medium (1), High (2)
                          label: "${_getVaporLabel(tempVaporIntensity)}",
                          onChanged: (value) {
                            setModalState(() {
                              tempVaporIntensity = value; // Update temp value
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
                            _puffCount = tempPuffCount;
                            _vaporIntensity = tempVaporIntensity;
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

List<Map<String, dynamic>> _filterVapeDispo() {
  return _vapeModsInventory.where((mod) {
    if (_searchQuery.isNotEmpty && !mod["name"].toLowerCase().contains(_searchQuery.toLowerCase())) {
      return false; // Filter by search query
    }
    // Vapor Intensity Filtering
    if (_vaporIntensity > 0 && mod["vapor"] != _vaporIntensity) return false;

    // Puff Count Filtering (Assuming puff count is a numeric range)
    if (_puffCount > 0 && (mod["puff_count"] ?? 0) < _puffCount) return false;


    // Attribute Filtering (Nicotine mg, Brand, Size)
    for (var filter in filterOptions) {
      String selectedValue = _selectedFilters[filter.label] ?? "Any";
      if (selectedValue != "Any") {
        String modKey = filter.label.toLowerCase().replaceAll(" ", "_");
        // Ensure key exists and matches the selected filter
        if (!mod.containsKey(modKey) || mod[modKey] != selectedValue) return false;
      }
    }
    
    return true;
  }).toList();
}


  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    
    // Get the filtered list of vape mods
    List<Map<String, dynamic>> filteredVapeMods = _filterVapeDispo();
    // print(filteredVapeMods);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _loadVapeMods(); // ✅ Reload VapeMods when returning
        }
      },
      child: MainLayout(

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text("Disposable Vapes", style: Theme.of(context).textTheme.headlineMedium)),
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