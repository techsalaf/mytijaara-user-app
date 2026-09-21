import 'package:flutter/material.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int? serviceId;
  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
