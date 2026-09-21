import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class ServiceSearchCard extends StatelessWidget {
  final Service service;
  final double? width;
  final VoidCallback? onFavourite;

  const ServiceSearchCard({super.key, required this.service, this.width, this.onFavourite});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
