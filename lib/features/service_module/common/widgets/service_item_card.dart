import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class ServiceItemCard extends StatelessWidget {
  final Service service;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onFavourite;

  const ServiceItemCard({super.key,
    required this.service, required this.width, this.onTap, this.onFavourite,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}
