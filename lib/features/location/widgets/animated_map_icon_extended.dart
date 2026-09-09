import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class AnimatedMapIconExtended extends StatefulWidget {
  const AnimatedMapIconExtended({super.key});

  @override
  State<AnimatedMapIconExtended> createState() => _AnimatedMapIconExtendedState();
}

class _AnimatedMapIconExtendedState extends State<AnimatedMapIconExtended>  {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController){
      return Center(
        child: Stack(clipBehavior: Clip.none, alignment: AlignmentDirectional.center, children: [
          Positioned(
            top: -30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Text('is_this_your_location'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          Lottie.asset(Images.mapIconExtended , repeat: false, height: Dimensions.pickMapIconSize,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['Red circle Outlines', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['Shape Layer 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['Layer 4', 'Group 1', 'Stroke 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                // Change color of Stroke 1 in Group 2
                ValueDelegate.color(
                  const ['Layer 4', 'Group 2', 'Stroke 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                // Change color of Stroke 1 in Group 3
                ValueDelegate.color(
                  const ['Layer 4', 'Group 3', 'Stroke 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['shadow Outlines', '**'],
                  value: Theme.of(context).colorScheme.primary,
                )
              ],
            ),

          ),
          Padding(
            padding:  const EdgeInsets.only(top: Dimensions.pickMapIconSize * 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min,
              children: List.generate(9, (index){
                return  Icon(Icons.circle, size: index == 8 ? Dimensions.pickMapIconSize * 0.06 : Dimensions.pickMapIconSize * 0.03,
                  color: Theme.of(context).colorScheme.primary,
                );
              }),
            ),
          ),
        ],),
      );
    });
  }
}