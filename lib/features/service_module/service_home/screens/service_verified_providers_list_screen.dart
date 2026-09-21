import 'package:flutter/material.dart';

class ServiceVerifiedProvidersListScreen extends StatefulWidget {
  final String type;
  final String titleKey;

  const ServiceVerifiedProvidersListScreen({super.key, this.type = 'all', this.titleKey = 'verified_providers'});

  @override
  State<ServiceVerifiedProvidersListScreen> createState() => _ServiceVerifiedProvidersListScreenState();
}

class _ServiceVerifiedProvidersListScreenState extends State<ServiceVerifiedProvidersListScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
