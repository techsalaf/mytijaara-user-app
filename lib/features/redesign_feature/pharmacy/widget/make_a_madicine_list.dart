
import 'package:flutter/material.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/single_deal_widget.dart';

class MakeAMedicineList extends StatelessWidget {
  const MakeAMedicineList({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleDealWidget(beginColor: Colors.blueAccent.withAlpha(60), endColor: Colors.blueAccent.withAlpha(30), title: 'Make a Medicine List', subTitle: 'Order multiple medicines as easy as possible.',);
  }
}
