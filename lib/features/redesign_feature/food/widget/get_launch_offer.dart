import 'package:flutter/material.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/single_deal_widget.dart';

class GetLaunchOffer extends StatelessWidget {
  const GetLaunchOffer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleDealWidget(beginColor: Colors.amber.withAlpha(180), endColor:  Colors.amber.withAlpha(100), title: 'Get Launch Up to 50% Off?', subTitle: 'Don’t miss out, order your favorites now',);
  }
}
