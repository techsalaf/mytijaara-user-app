import 'package:flutter/material.dart';

class ServiceScreen extends StatefulWidget {
  static Future<void> loadData() async {}
  final ScrollController? scrollController;
  const ServiceScreen({super.key, this.scrollController});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
