import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class ProviderServiceItemWidget extends StatelessWidget {
  final Service service;
  final VoidCallback? onBeforeTap;

  const ProviderServiceItemWidget({super.key, required this.service, this.onBeforeTap});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
