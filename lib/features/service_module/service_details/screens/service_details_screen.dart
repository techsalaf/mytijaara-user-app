import 'package:flutter/material.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int? serviceId;
  final String? heroTag;
  const ServiceDetailsScreen({super.key, this.serviceId, this.heroTag});

  static Future<void> loadData() async {}

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
