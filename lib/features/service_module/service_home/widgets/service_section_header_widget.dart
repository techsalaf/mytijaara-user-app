import 'package:flutter/material.dart';

class ServiceSectionHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeMore;

  const ServiceSectionHeaderWidget({super.key, required this.title, this.subtitle, this.onSeeMore});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
