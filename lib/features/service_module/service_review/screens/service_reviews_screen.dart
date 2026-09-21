import 'package:flutter/material.dart';

class ServiceReviewsScreen extends StatefulWidget {
  final int serviceId;
  final String? serviceName;

  const ServiceReviewsScreen({super.key, required this.serviceId, this.serviceName});

  @override
  State<ServiceReviewsScreen> createState() => _ServiceReviewsScreenState();
}

class _ServiceReviewsScreenState extends State<ServiceReviewsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
