import 'package:flutter/material.dart';
  
class RideHomeScreen extends StatefulWidget {
  static Future<void> loadData() async{}
  const RideHomeScreen({super.key});

  @override
  State<RideHomeScreen> createState() => _RideHomeScreenState();
}

class _RideHomeScreenState extends State<RideHomeScreen>  with WidgetsBindingObserver{

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
  