import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';

Widget sliverGepY({double? value}) {
  return SliverToBoxAdapter(
    child: SizedBox(height: value ?? Dimensions.paddingSizeDefault),
  );
}

Widget sliverPadX({required Widget child, isSliver = false}) {

  if(isSliver){
   return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      sliver: child,
    );
  }
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        child: child,
      ),
    );
}
