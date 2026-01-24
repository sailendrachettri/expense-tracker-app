import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'home_screen.dart';

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Force DB initialization + default inserts
    await DatabaseHelper.instance.database;

    // Optional delay for UX smoothness
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  
 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Image(
            image: AssetImage('assets/icon/app_icon.png'),
            width: 96,
            height: 96,
          ),
          SizedBox(height: 20),
          Text(
            'Loading your data...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

}
