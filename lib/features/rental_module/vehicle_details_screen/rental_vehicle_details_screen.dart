

import 'package:flutter/material.dart';

class RentalVehicleDetailsScreen extends StatefulWidget {
  final int? vehicleId;
  final bool? fromSelectVehicleScreen;
  const RentalVehicleDetailsScreen({super.key, required this.vehicleId, this.fromSelectVehicleScreen = false});

  @override
  State<RentalVehicleDetailsScreen> createState() => _RentalVehicleDetailsScreenState();
}

class _RentalVehicleDetailsScreenState extends State<RentalVehicleDetailsScreen> {

  @override
  Widget build(BuildContext context) {

    return const SizedBox();
  }
}