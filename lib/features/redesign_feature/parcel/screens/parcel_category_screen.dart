import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/screens/subscription_plan_screen.dart';
import 'package:sixam_mart/features/pro/widgets/pro_plan_banner_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/banner_slider.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/widget/all_parcel_type_bottom_sheet.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/widget/need_help_to_getting_start_widget.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/widget/parcel_category_card_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';


class ParcelCategoryNewScreen extends StatefulWidget {
  const ParcelCategoryNewScreen({super.key});

  @override
  State<ParcelCategoryNewScreen> createState() => _ParcelCategoryNewScreenState();
}

class _ParcelCategoryNewScreenState extends State<ParcelCategoryNewScreen> {

  @override
  void initState() {
    super.initState();
    if(AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
    Get.find<BannerController>().getParcelOtherBannerList(true);
    Get.find<ParcelController>().getParcelCategoryList();
    Get.find<ParcelController>().getWhyChooseDetails();
    Get.find<ParcelController>().getVideoContentDetails();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<ParcelController>(builder: (parcelController) {
      return GetBuilder<BannerController>(builder: (bannerController) {
        return SizedBox(width: Dimensions.webMaxWidth,
          child: Column(crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [

            const SizedBox(height: Dimensions.paddingSizeLarge),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeLarge),
              child: Text('what_would_you_like_to_send'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            parcelController.parcelCategoryList != null ? parcelController.parcelCategoryList!.isNotEmpty ? _ParcelCategoryGridView(
              categories: parcelController.parcelCategoryList!,
              isDesktop: isDesktop,
            ) : Center(child: Text('no_parcel_category_found'.tr)) : ParcelShimmer(isEnabled: parcelController.parcelCategoryList == null, isDeliveryItem: true),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            const Padding(
              padding : EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: NeedHelpToGettingStartWidget(),
            ),

            // pro plan banner
            const SizedBox(height: Dimensions.paddingSizeDefault,),
            const  _ParcelProPlanBanner(),

            const SizedBox(height: Dimensions.paddingSizeDefault,),
            bannerController.parcelOtherBannerModel != null && bannerController.parcelOtherBannerModel!.banners != null ? bannerController.parcelOtherBannerModel!.banners!.isNotEmpty ?
                BannerSliderWidget(bannerList: bannerController.parcelOtherBannerModel!.banners!)
             : const SizedBox() : Shimmer(
              duration: const Duration(seconds: 2),
              enabled: true,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: isDesktop ? 395 : 150,
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),

                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeLarge),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault,),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  // Light lavender wash in light mode; a subtle indigo glow fading to
                  // transparent in dark mode so it isn't a bright band.
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF5C6BC0).withValues(alpha: 0.20), const Color(0xFF5C6BC0).withValues(alpha: 0.0)]
                      : [const Color(0xFFDADEFA), const Color(0xFFDADEFA).withAlpha(20)],
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text('why_choose_us'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                parcelController.whyChooseDetails != null ? isDesktop ? webExperienceView(isDesktop, parcelController) : mobileExperienceView(isDesktop, parcelController)
                    : ParcelShimmer(isEnabled: parcelController.parcelCategoryList == null, isDeliveryItem: false),
              ]),
            ),

          ]));
      });
    });
  }

  Widget webExperienceView(bool isDesktop, ParcelController parcelController) {
    return GridView.builder(
      controller: ScrollController(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : ResponsiveHelper.isTab(context) ? 2 : 1,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisExtent: 150,
      ),
      itemCount: parcelController.whyChooseDetails!.banners!.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return _ExperienceCardWidget(
          image: '${parcelController.whyChooseDetails!.banners![index].imageFullUrl}',
          title: parcelController.whyChooseDetails!.banners![index].title!,
          description: parcelController.whyChooseDetails!.banners![index].shortDescription!,
        );
      },
    );
  }

  Widget mobileExperienceView(bool isDesktop, ParcelController parcelController) {
    final bool isLtr = Get.find<LocalizationController>().isLtr;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        itemCount: parcelController.whyChooseDetails!.banners!.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          return SizedBox(
            width: context.width * 0.5,
            child: _ExperienceCardWidget(
              image: '${parcelController.whyChooseDetails!.banners![index].imageFullUrl}',
              title: parcelController.whyChooseDetails!.banners![index].title!,
              description: parcelController.whyChooseDetails!.banners![index].shortDescription!,
              isLtr: isLtr,
            ),
          );
        },
      ),
    );
  }
}

class _ExperienceCardWidget extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final bool isLtr;
  const _ExperienceCardWidget({
    required this.image,
    required this.title,
    required this.description,
    this.isLtr = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImage(image: image, height: 40, width: 40),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(
          title,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: isLtr ? TextAlign.left : TextAlign.right,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
        ),
        const SizedBox(height: 2),

        Text(
          description,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          textAlign: isLtr ? TextAlign.center : TextAlign.center,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
      ]),
    );
  }
}


class _ParcelCategoryGridView extends StatelessWidget {
  final List<ParcelCategoryModel> categories;
  final bool isDesktop;
  const _ParcelCategoryGridView({required this.categories, required this.isDesktop});

  static const int _initialVisibleCount = 4;

  @override
  Widget build(BuildContext context) {
    final bool hasExtra = categories.length > _initialVisibleCount;
    final int visibleCount = hasExtra ? _initialVisibleCount : categories.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      GridView.builder(
        controller: ScrollController(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : 2,
          crossAxisSpacing: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
          mainAxisSpacing: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
          mainAxisExtent: isDesktop ? 100 : 90,
        ),
        itemCount: visibleCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeLarge),
        itemBuilder: (context, index) {
          return ParcelCategoryCardWidget(
            image: '${categories[index].imageFullUrl}',
            itemName: categories[index].name ?? '',
            description: categories[index].description ?? '',
            colorIndex: index,
            onTap: () {
              if (AddressHelper.getUserAddressFromSharedPref() == null) {
                Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
                return;
              }
              Get.toNamed(RouteHelper.getParcelLocationRoute(categories[index]));
            },
          );
        },
      ),

      if (hasExtra) Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
        child: Center(
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (con) => const AllParcelTypeBottomSheet(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeSmall,
                horizontal: Dimensions.paddingSizeDefault,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'see_more'.tr,
                  style: robotoMedium.copyWith(
                    color: Colors.blueAccent,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 20,
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}


class ParcelShimmer extends StatelessWidget {
  final bool isEnabled;
  final bool isDeliveryItem;
  const ParcelShimmer({super.key, required this.isEnabled, required this.isDeliveryItem});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    if (!isDeliveryItem && !isDesktop) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: _ExperienceShimmerCard(isEnabled: isEnabled),
            );
          },
        ),
      );
    }

    return GridView.builder(
      gridDelegate: isDeliveryItem ? SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
        mainAxisSpacing: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
        mainAxisExtent: isDesktop ? 100 : 75,
      ) : const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisExtent: 140,
      ),
      itemCount: isDeliveryItem ? 7 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeLarge),
      itemBuilder: (context, index) {
        if (!isDeliveryItem) {
          return _ExperienceShimmerCard(isEnabled: isEnabled);
        }
        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: isEnabled,
            child: Row(children: [

              Container(
                height: 50, width: 50, alignment: Alignment.center,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(height: 15, width: 200, color: Colors.grey[300]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(height: 15, width: 100, color: Colors.grey[300]),
              ])),
              const SizedBox(width: Dimensions.paddingSizeSmall),
            ]),
          ),
        );
      },
    );
  }
}

class _ParcelProPlanBanner extends StatelessWidget {
  const _ParcelProPlanBanner();

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SplashController>().proStaus) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: ProPlanBannerWidget(
        onSubscribe: () {
          Get.find<ProController>().saveCurrentPath(route: RouteHelper.getMainRoute('home'));
          SubscriptionPlanScreen.open();
        },
      ),
    );
  }
}

class _ExperienceShimmerCard extends StatelessWidget {
  final bool isEnabled;
  const _ExperienceShimmerCard({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        enabled: isEnabled,
        child: Column(children: [

          Container(
            height: 40, width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(height: 14, width: 90, color: Colors.grey[300]),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Container(height: 10, width: 120, color: Colors.grey[300]),
          const SizedBox(height: 4),
          Container(height: 10, width: 70, color: Colors.grey[300]),
        ]),
      ),
    );
  }
}

class VideoContentDetailsShimmer extends StatelessWidget {
  const VideoContentDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

      Expanded(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 350,
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
      ),
      const SizedBox(width: 125),

      Expanded(
        child: ListView.builder(
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          itemCount: 6,
          itemBuilder: (context, index) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Container(
                  height: 14, width: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                Container(height: 15, width: 200, color: Colors.grey[300]),
              ]),

              Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: 22.5),
                margin: const EdgeInsets.only(left: 7),
                decoration: BoxDecoration(
                    border: index == 6 - 1 ? null : Border(left: BorderSide(width: 1, color: Theme.of(context).disabledColor))),
                child: Container(height: 15, width: 100, color: Colors.grey[300]),
              ),
            ]);
          },
        ),
      ),
    ]) : Column(children: [

      Container(
        width: MediaQuery.of(context).size.width,
        height: 185,
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      ListView.builder(
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [
              Container(
                height: 14, width: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),

              Container(height: 15, width: 200, color: Colors.grey[300]),
            ]),

            Container(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: 22.5),
              margin: const EdgeInsets.only(left: 7),
              decoration: BoxDecoration(
                  border: index == 6 - 1 ? null : Border(left: BorderSide(width: 1, color: Theme.of(context).disabledColor))),
              child: Container(height: 15, width: 100, color: Colors.grey[300]),
            ),
          ]);
        },
      ),
    ]);
  }
}

