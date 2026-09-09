import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_category_model.dart';

class ServiceCategoryScreen extends StatefulWidget {
  final ServiceCategoryModel category;
  const ServiceCategoryScreen({super.key, required this.category});

  static Future<void> loadData() async {}

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
