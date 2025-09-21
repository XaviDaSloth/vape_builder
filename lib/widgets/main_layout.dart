import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "VapePro",
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: _buildDrawer(context), // Sidebar Menu
      body: child,
      
    );
  }

  // Sidebar Menu (Drawer)
 Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        
        Container(
          height: 150, // Reduced height
          width: double.infinity,
          color: Theme.of(context).colorScheme.primary,
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.only(bottom: 20),
          child: const Text(
            'Menu',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildDrawerItem(context, Icons.home, 'Home', '/'),
              _buildDrawerItem(context, Icons.shopping_cart, 'Vape Mods', '/vape_mods'),
              _buildDrawerItem(context, Icons.cloud, 'Pod Systems', '/pod_systems'),
              _buildDrawerItem(context, Icons.smoking_rooms, 'Disposable Vapes', '/vape_dispo'),
              _buildDrawerItem(context, Icons.inventory, 'Inventory', '/inventory'),
              const Divider(),
              _buildDrawerItem(context, Icons.info, 'About', '/about'),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Developed by: Johnny Xavier Obar",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    ),
  );
}


  // Drawer Item
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route) {
    return Material(
      child: InkWell(
        onTap: () {
            Navigator.pop(context); // Close the drawer
            Navigator.pushNamed(context, route);
          },
        splashColor: Theme.of(context).colorScheme.secondary.withAlpha(77), // Light bounce effect
        highlightColor: Theme.of(context).colorScheme.secondary.withAlpha(26), // Subtle highlightr
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
        ),
      ),
    );
  }
}
