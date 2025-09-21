import 'package:flutter/material.dart';
import 'dart:async';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenSplash = prefs.getBool('hasSeenSplash') ?? false;

    if (hasSeenSplash) {
      // If already seen, go straight to homepage
      _navigateToHome();
    } else {
      // Show splash screen for 2 seconds, then set it as seen
      await prefs.setBool('hasSeenSplash', true);
      Timer(Duration(seconds: 2), _navigateToHome);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(title: 'VapePro')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1F3B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/SplashScreen.png'),
            SizedBox(height: 20),
            Text(
              'VapePro',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
      ),
    );
  }
}
