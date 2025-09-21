import 'package:flutter/material.dart';
import 'package:vape_builder/screens/check.dart';
// import 'package:vape_builder/models/inventory_item.dart';
import 'package:vape_builder/screens/inventory.dart';
import 'package:vape_builder/screens/pod_systems.dart';
import 'package:vape_builder/screens/vape_dispo.dart';
import 'screens/homepage.dart';
import 'package:google_fonts/google_fonts.dart';
import '/screens/vape_mods.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('inventoryBox');

  // ✅ Check if splash has been shown before launching the app
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenSplash = prefs.getBool('hasSeenSplash') ?? false;

  runApp(MyApp(hasSeenSplash: hasSeenSplash));
}



final ThemeData myTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Color(0xFF41378B),
    onPrimary: Color(0xFFEFEFEF),
    secondary: Color(0xFF867AD2),
    onSecondary: Colors.white,
    tertiary: Color(0xFF685AC4),
    surface: Color(0xFF1A1F3B),
    onSurface: Colors.white,
  ),
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold), // Primary font
    headlineMedium: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.normal), // Secondary font
    bodyMedium: GoogleFonts.raleway(fontSize: 16),
  ),
  scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(Color(0xFF867AD2)), // Set thumb color
      trackColor: WidgetStateProperty.all(Color(0x7F4A5F77)), // Set track color
      thickness: WidgetStateProperty.all(5), // Set thickness
      radius: Radius.circular(8), // Set border radius
    ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF685AC4), // Default button color
      foregroundColor: Color(0xFFEFEFEF), // Text color
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
);

class MyApp extends StatelessWidget {
  final bool hasSeenSplash;
  const MyApp({Key? key, required this.hasSeenSplash}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vape Pro',
      theme: myTheme,
      debugShowCheckedModeBanner: false,
      initialRoute:'/', // Skip splash if already seen
      routes: {
        '/': (context) => MyHomePage(title: 'VapePro'), // Show custom splash after native splash
        '/vape_mods': (context) => const VapeMods(),
        '/pod_systems': (context) => const PodSystems(),
        '/vape_dispo': (context) => const DisposableVapes(),
        '/inventory': (context) => const InventoryScreen(),
        '/check': (context) => const CheckHiveScreen(),
      },
    );
  }
}
