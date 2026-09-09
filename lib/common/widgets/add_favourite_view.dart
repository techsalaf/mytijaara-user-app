import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/util/dimensions.dart';

class AddFavouriteView extends StatefulWidget {
  final Item? item;
  final double? top, right;
  final double? left;
  final int? storeId;
  final bool interceptPointers;
  final double? size;
  const AddFavouriteView({super.key, required this.item, this.top = 15, this.right = 15, this.left, this.storeId, this.interceptPointers = false, this.size});

  @override
  State<AddFavouriteView> createState() => _AddFavouriteViewState();
}

class _AddFavouriteViewState extends State<AddFavouriteView> with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top, right: widget.right, left: widget.left,
      child: GetBuilder<FavouriteController>(builder: (favouriteController) {
        bool isWished;
        if(widget.storeId != null) {
          isWished = favouriteController.wishStoreIdList.contains(widget.storeId);
        } else {
          isWished = favouriteController.wishItemIdList.contains(widget.item!.id);
        }
        Widget favouriteButton = InkWell(
          onTap: favouriteController.isRemoving ? (){} : () {
            if(AuthHelper.isLoggedIn()) {
              if(widget.storeId != null) {
                isWished ? favouriteController.removeFromFavouriteList(widget.storeId, true) : favouriteController.addToFavouriteList(null, widget.storeId, true);
              } else {
                isWished ? favouriteController.removeFromFavouriteList(widget.item!.id, false) : favouriteController.addToFavouriteList(widget.item, null, false);
              }
            }else {
              showCustomSnackBar('you_are_not_logged_in'.tr);
            }
            _controller.reverse().then((value) => _controller.forward());
          },
          child: Container(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall, left: Dimensions.paddingSizeExtraSmall, right: Dimensions.paddingSizeExtraSmall, bottom: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              // boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
              child: Icon(isWished ? CupertinoIcons.heart_solid : CupertinoIcons.heart, color: Colors.red, size: widget.size??22),
            ),
          ),
        );
        return PointerInterceptor(intercepting: widget.interceptPointers, child: favouriteButton);
      }),
    );
  }
}
