import 'package:hive/hive.dart';

part 'inventory_item.g.dart'; // Required for generated adapter

@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int stocks;

  @HiveField(2)
  String category;

  @HiveField(3)
  String description;

  @HiveField(4)
  double price;

  InventoryItem({
    required this.name,
    required this.stocks,
    required this.category,
    required this.description,
    required this.price,
  });
}
