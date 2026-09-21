import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/styles.dart';

class ClosedRibbonBadge extends StatelessWidget {
  final double height;
  final double width;

  const ClosedRibbonBadge({super.key, this.height = 44, this.width = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: width,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14)
      ),
      alignment: Alignment.center,
      child: Text('closed_now'.tr, textAlign: TextAlign.center,
        style: robotoRegular.copyWith(fontSize: 8, color: Colors.white),
      ),
    );
  }
}
