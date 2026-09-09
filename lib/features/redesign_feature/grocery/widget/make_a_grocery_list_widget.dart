import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/single_deal_widget.dart';
import 'package:sixam_mart/features/redesign_feature/grocery/screens/create_list_screen.dart';

class MakeAGroceryListWidget extends StatelessWidget {
  const MakeAGroceryListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleDealWidget(
      onTap: (){
        Get.to(()=> const CreateListScreen());
      },
      beginColor: Colors.yellow.withAlpha(100),
      endColor: Colors.yellow.withAlpha(50),
      title: 'Make a Grocery List',
      subTitle: 'Create a list to faster & repeated order easily.',);
  }
}
