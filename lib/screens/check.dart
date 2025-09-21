import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CheckHiveScreen extends StatefulWidget {
  const CheckHiveScreen({super.key});

  @override
  _CheckHiveDataScreenState createState() => _CheckHiveDataScreenState();
}

class _CheckHiveDataScreenState extends State<CheckHiveScreen> {
  Map<String, dynamic> hiveData = {};
  List<String> boxNames = ['inventoryBox', 'settingsBox']; // Add known box names

  @override
  void initState() {
    super.initState();
    _loadHiveData();
  }

  Future<void> _loadHiveData() async {
    Map<String, dynamic> allData = {};
    for (var boxName in boxNames) {
      var box = await Hive.openBox(boxName);
      allData[boxName] = box.toMap();
    }
    setState(() {
      hiveData = allData;
    });
  }

  void _clearHiveData() async {
    for (var boxName in boxNames) {
      var box = await Hive.openBox(boxName);
      await box.clear();
    }
    _loadHiveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hive Data Viewer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHiveData,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearHiveData,
          ),
        ],
      ),
      body: hiveData.isEmpty
          ? const Center(child: Text("No data found in Hive."))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: hiveData.length,
              itemBuilder: (context, index) {
                String boxName = hiveData.keys.elementAt(index);
                var boxContent = hiveData[boxName];
                return Card(
                  child: ExpansionTile(
                    title: Text("Box: $boxName"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(boxContent.toString()),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}