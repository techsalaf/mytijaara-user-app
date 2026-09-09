import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BackToTopButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const BackToTopButton({super.key, required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 150,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, -0.6),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: CustomInkWell(
                  radius: 99,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Theme.of(context).cardColor, width: 0.2),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('back_to_top'.tr,
                          style: robotoBold.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeDefault),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Icon(Icons.arrow_upward_outlined, size: 18, color: Theme.of(context).cardColor),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}