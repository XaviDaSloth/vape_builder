import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vape_builder/data/vape_mods_data.dart';
import 'package:vape_builder/data/vape_dispo_data.dart';
import 'package:vape_builder/data/vape_pods_data.dart';
import 'package:vape_builder/widgets/add_vape.dart';
import 'package:vape_builder/widgets/item_dialogs.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = "";
  String _selectedCategory = "";
  List<Map<String, dynamic>> _inventory = [];
  List<TextEditingController> _controllers = [];


  Future<void> _clearHiveData() async {
    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox');
    }
    var box = Hive.box('inventoryBox');
    await box.clear(); // Clears all stored data
    print("Hive storage cleared.");

    setState(() {
      _inventory.clear();
      _controllers.clear();
    });
  }

  void initState() {
    super.initState();
    _loadAllItems();
  }

  void _saveInventory() async {
    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox'); // Open before saving
    }
    var box = Hive.box('inventoryBox');
    await box.put('inventory', _inventory);
  }


  Future<void> _loadAllItems() async {
    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox');
    }

    var box = Hive.box('inventoryBox');
    List<dynamic>? savedInventory = box.get('inventory');

    setState(() {
      if (savedInventory != null) {
        _inventory = savedInventory.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        _inventory = [
          ...vapeMods.map((item) => {...item, 'category': 'Vape Mods'}),
          ...vapeDispo.map((item) => {...item, 'category': 'Vape Dispos'}),
          ...podSystems.map((item) => {...item, 'category': 'Pod Systems'}),
        ];
        _saveInventory();
      }

      /// Ensure controllers are correctly initialized
      _controllers = List.generate(
        _inventory.length,
        (index) => TextEditingController(text: _inventory[index]['stocks'].toString()),
      );
    });

    print("Final inventory count: ${_inventory.length}");
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = (_selectedCategory == category) ? "" : category;
    });
  }

  void _updateStock(Map<String, dynamic> item, int change) {
    int realIndex = _inventory.indexOf(item);
    if (realIndex == -1) return; // Prevent out-of-range errors

    setState(() {
      _inventory[realIndex]['stocks'] = (_inventory[realIndex]['stocks'] + change).clamp(0, 99999);
      _controllers[realIndex].text = _inventory[realIndex]['stocks'].toString();
    });
    _saveInventory();
  }



  void _setStock(int index, int newStock) {
    if (_inventory[index]['stocks'] != newStock) {
      setState(() {
        _inventory[index]['stocks'] = newStock;
        _controllers[index].text = newStock.toString();
      });
      _saveInventory();
    }
  }


  void _removeItem(Map<String, dynamic> item) {
    int realIndex = _inventory.indexOf(item);
    if (realIndex == -1) return; // Prevent errors

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove Item"),
        content: Text("Are you sure you want to remove ${item['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _inventory.removeAt(realIndex);
                _controllers.removeAt(realIndex); // ✅ Ensure controllers remain in sync
                _saveInventory();
              });
              Navigator.pop(context);
            },
            child: Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  Widget _buildCircleButton(String label) {
    return GestureDetector(
      onTap: () => _filterByCategory(label),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedCategory == label
                  ? Colors.blueAccent
                  : Theme.of(context).colorScheme.tertiary,
            ),
            child: Center(
                child: Text(label[0], style: TextStyle(fontSize: 20, color: Colors.white))),
          ),
          const SizedBox(height: 5),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _addVapeItem() {
    showAddVapeItemDialog(context, (newItem) {
      setState(() {
        _inventory.add(newItem);
        _controllers.add(TextEditingController(text: newItem['stocks'].toString())); // ✅ Add new controller
        _saveInventory();
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedItems = _inventory.where((item) {
      bool matchesSearch = _searchQuery.isEmpty || item['name'].toLowerCase().contains(_searchQuery);
      bool matchesCategory = _selectedCategory.isEmpty || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(hintText: "Search inventory...", border: InputBorder.none),
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
        actions: [IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: _clearHiveData, // Calls the function
        ),],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["Vape Mods", "Vape Dispos", "Pod Systems"].map(_buildCircleButton).toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayedItems.length,
              itemBuilder: (context, index) {
                final item = displayedItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(item['name'], style: TextStyle(color: Colors.white)),
                      subtitle: Text("Stocks: ${item['stocks']}", style: TextStyle(color: Colors.grey)),
                      onTap: () => showItemDetails(
                        context,
                        item['name'].toString(),
                        item["name"],
                        item['description'],
                        item['image'],
                        item['stocks'],
                        item["price"],
                        
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.red),
                            onPressed: () => _updateStock(item, -1),
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _controllers[index], // Controller for each item
                              keyboardType: TextInputType.number, // Number input only
                              textAlign: TextAlign.center,
                              style: TextStyle(color: const Color.fromARGB(255, 228, 227, 227)), // ✅ Text color white
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)), // ✅ White border
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)), // ✅ White border when focused
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color.fromARGB(255, 224, 224, 224))), // ✅ White border when not focused
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                              onChanged: (value) {
                                int? newStock = int.tryParse(value);
                                if (newStock != null) {
                                  _setStock(index, newStock); // Update stock manually
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => _updateStock(item, 1),
                          ),

                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removeItem(item),
                          ),
                        ],

                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(onPressed: _addVapeItem,backgroundColor: Theme.of(context).colorScheme.secondary, child: Icon(Icons.add)),
    );
  }
}
