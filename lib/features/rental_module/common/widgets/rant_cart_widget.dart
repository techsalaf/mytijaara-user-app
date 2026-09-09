import 'package:flutter/material.dart';

class RantCartWidget extends StatelessWidget {
  final bool? fromSelectVehicleScreen;
  final Function(bool)? callback;
  final Color ? color;
  const RantCartWidget({super.key, this.fromSelectVehicleScreen = false, this.callback, this.color});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
