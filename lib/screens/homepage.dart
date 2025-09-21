import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vape_builder/data/vape_dispo_data.dart';
import 'package:vape_builder/data/vape_mods_data.dart';
import 'package:vape_builder/data/vape_pods_data.dart';
import 'package:vape_builder/widgets/card_widget.dart';
import 'package:vape_builder/widgets/item_dialogs.dart';
import 'package:vape_builder/widgets/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VapePro',
      home: const MyHomePage(title: 'VapePro'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _firstRowScrollController = ScrollController();
  final ScrollController _secondRowScrollController = ScrollController();

  List<Map<String, dynamic>> _newReleases = [];
  List<Map<String, dynamic>> _userRecommendations = [];
  List<Map<String, dynamic>> _vapeInventory = [];
  List<Map<String, dynamic>> _inventory = [];

  @override
  void initState() {
    super.initState();
    _loadVapeInventory();
  }

  Future<void> _saveInventory() async {
    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox'); // Open before saving
    }
    var box = Hive.box('inventoryBox');
    await box.put('inventory', _inventory);
  }

  /// **🚀 Runs Hive Loading in a Background Thread (No UI Lag)**
  Future<void> _loadVapeInventory() async {
    debugPrint("Loading vape inventory...");

    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox('inventoryBox');
    }
    var box = Hive.box('inventoryBox');

    // ✅ Load data directly without compute()
    List<Map<String, dynamic>> loadedInventory =
        (box.get('inventory') as List?)?.map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            ).toList() ?? [];

    if (loadedInventory.isEmpty) {
      loadedInventory = [
        ...vapeMods.map((item) => {...item, 'category': 'Vape Mods'}),
        ...vapeDispo.map((item) => {...item, 'category': 'Vape Dispos'}),
        ...podSystems.map((item) => {...item, 'category': 'Pod Systems'}),
      ];
    }

    if (!mounted) return;

    setState(() {
      _vapeInventory = loadedInventory;
      _inventory = List.from(loadedInventory);
      _filterProducts();
    });

    await _saveInventory();
}




  /// **🔹 Background Isolate for Hive Loading**
  // static List<Map<String, dynamic>> _loadInventoryData(dynamic savedInventory) {
  //   if (savedInventory == null) {
  //     return [
  //       ...vapeMods.map((item) => {...item, 'category': 'Vape Mods'}),
  //       ...vapeDispo.map((item) => {...item, 'category': 'Vape Dispos'}),
  //       ...podSystems.map((item) => {...item, 'category': 'Pod Systems'}),
  //     ];
  //   }

  //   return savedInventory.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
  // }

  /// **Filters New Releases & User Recommendations**
  void _filterProducts() {
    DateTime now = DateTime.now();
    DateTime twoMonthsAgo = now.subtract(const Duration(days: 60));

    _newReleases = _vapeInventory.where((vape) {
      if (vape["date_released"] == null) return false;
      DateTime releaseDate = DateFormat("yyyy-MM-dd").parse(vape["date_released"]);
      return releaseDate.isAfter(twoMonthsAgo) && releaseDate.isBefore(now);
    }).toList();

    _userRecommendations = _vapeInventory.where((vape) {
      return vape["rating"] != null && vape["rating"] >= 4;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: RefreshIndicator(
        onRefresh: _loadVapeInventory,
        child: SingleChildScrollView( // ✅ Make it scrollable
          physics: const AlwaysScrollableScrollPhysics(), // ✅ Ensures it always detects pull-down
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔵 Category Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleButton("Pod Systems", "pod_systems", 'podSystems'),
                  _buildCircleButton("Vape Dispo", "vape_dispo", 'vapeDispo'),
                  _buildCircleButton("Vape Mods", "vape_mods", 'vapeMod'),
                ],
              ),
              const SizedBox(height: 20),

              // 🟢 New Releases Section
              Text("New Releases", style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 10),
              _buildScrollableRow(_newReleases, _firstRowScrollController),

              const SizedBox(height: 50),

              // 🔵 User Recommendations Section
              Text("User Recommendations", style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 10),
              _buildScrollableRow(_userRecommendations, _secondRowScrollController),
            ],
          ),
        ),
      ),
    );
  }


  /// **🔵 Creates Circular Category Buttons**
  Widget _buildCircleButton(String label, String redirect, String imgPath) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/$redirect'),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/$imgPath.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// **🔲 Builds Scrollable Product Rows**
  Widget _buildScrollableRow(List<Map<String, dynamic>> items, ScrollController scrollController) {
    return SizedBox(
      height: 160,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return CustomCard(
              label: item["name"],
              imagePath: item["image"],
              onTap: () => showItemDetails(
                context,
                item["name"],
                item["name"],
                item["description"],
                item["image"],
                item["stocks"],
                item["price"],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstRowScrollController.dispose();
    _secondRowScrollController.dispose();
    super.dispose();
  }
}
