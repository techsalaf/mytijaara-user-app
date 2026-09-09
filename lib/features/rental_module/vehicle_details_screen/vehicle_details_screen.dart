import 'package:flutter/material.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final int? vehicleId;
  final bool? fromSelectVehicleScreen;
  const VehicleDetailsScreen({super.key, required this.vehicleId, this.fromSelectVehicleScreen = false});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}