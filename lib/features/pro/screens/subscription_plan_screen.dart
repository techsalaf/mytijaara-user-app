import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/widgets/pro_terms_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_active_card_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_benefit_items.dart';
import 'package:sixam_mart/features/pro/widgets/pro_faq_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_plan_card_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_plan_selector_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final bool fromDialog;
  final bool? flag;
  final bool isRenewalMode;
  const SubscriptionPlanScreen({super.key, this.fromDialog = false, this.flag, this.isRenewalMode = false});

  static void open() {
    if(!Get.find<AuthController>().isLoggedIn()){
      Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.subscriptionPlan));
      return;
    }
    if (ResponsiveHelper.isDesktop(Get.context!)) {
      Get.dialog(
        Dialog(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          insetPadding: const EdgeInsets.all(22),
          child: SizedBox(
            width: 700,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.92),
              child: Stack(
                children: [
                  const SubscriptionPlanScreen(fromDialog: true),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Theme.of(Get.context!).hintColor),
                      style: IconButton.styleFrom(backgroundColor: Theme.of(Get.context!).disabledColor.withAlpha(30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        useSafeArea: false,
      );
    } else {
      Get.to(() => const SubscriptionPlanScreen());
    }
  }

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> with WidgetsBindingObserver {
  bool _isRenewalMode = false;
  bool _successShown = false;

  @override
  void initState() {
    super.initState();

    if(AuthHelper.isLoggedIn()) {
      initCall();
    }
  }

  void initCall() {
    _isRenewalMode = widget.isRenewalMode;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_){
      _loadInitialData();
      _showProSuccess();
    });
  }

  Future<void> _loadInitialData() async {
    await Get.find<ProController>().loadInitialData();
    await Get.find<ProfileController>().getUserInfo();
  }

  Future<void> _showProSuccess() async {
    if (_successShown || !mounted) return;
    _successShown = true;
    if(widget.flag != null) {
      Get.find<ProController>().showPlanSubscribeState(widget.isRenewalMode, paymentStatus: widget.flag!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && AuthHelper.isLoggedIn()) {
      Get.find<ProfileController>().getUserInfo();
    }
  }

  void _enterRenewalMode() => setState(() => _isRenewalMode = true);
  void _cancelRenewalMode() => setState(() => _isRenewalMode = false);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(!AuthHelper.isLoggedIn()) {
      return Scaffold(
        appBar: widget.fromDialog ? null : CustomAppBar(
          title: 'subscription_plan'.tr,
          backButton: true,
        ),
        body: NotLoggedInScreen(callBack: (bool value)  {
          initCall();
          setState(() {});
        }),
      );
    }
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isPro = profileController.userInfoModel?.proStatus == true;
      final bool isRenewal = _isRenewalMode;
      return Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: widget.fromDialog ? null : CustomAppBar(
          title: isPro ? 'my_subscription'.tr : 'subscription_plan'.tr,
          backButton: true,
        ),
        endDrawer: widget.fromDialog ? null : const MenuDrawer(),
        endDrawerEnableOpenDragGesture: false,
        body: Column(children: [
          if(!widget.fromDialog) WebScreenTitleWidget(title: isPro ? 'my_subscription'.tr : 'subscription_plan'.tr),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                child: GetBuilder<ProController>(builder: (proController) {
                  if (proController.isLoading && proController.planModel == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final ProPlanModel? model = proController.planModel;
                  return isPro
                      ? (isRenewal ? _RenewalView(model: model, proController: proController, fromDialog: widget.fromDialog, onCancel: _cancelRenewalMode)
                      : _SubscribedView(model: model, proController: proController, fromDialog: widget.fromDialog, onRenew: _enterRenewalMode))
                      : _UnsubscribedView(model: model, proController: proController, fromDialog: widget.fromDialog);
                }),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class _SubscribedView extends StatelessWidget {
  final ProPlanModel? model;
  final ProController proController;
  final bool fromDialog;
  final VoidCallback? onRenew;
  const _SubscribedView({required this.model, required this.proController, required this.fromDialog, this.onRenew});

  @override
  Widget build(BuildContext context) {
    final bool noModule = Get.find<SplashController>().module == null;
    final List<Map<String, String>> allModuleBenefits = noModule ? ProBenefitItems.fromPlanBenefits(model?.benefits) : const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(fromDialog) const _DialogHeader(titleKey: 'my_subscription'),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          ProActiveCardWidget(
            activeOfferModel: proController.activeOfferModel,
            onRenew: onRenew,
            benefitItemsOverride: allModuleBenefits.isNotEmpty ? allModuleBenefits : null,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          if(proController.faqList?.isNotEmpty ?? false) Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                border: Border.all(color: Theme.of(context).disabledColor.withAlpha(100))
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProFaqWidget(faqList: proController.faqList),
                ]
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          const _TermsLink(),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ],
      ),
    );
  }
}

class _UnsubscribedView extends StatelessWidget {
  final ProPlanModel? model;
  final ProController proController;
  final bool fromDialog;
  const _UnsubscribedView({required this.model, required this.proController, required this.fromDialog});

  @override
  Widget build(BuildContext context) {
    final List<PlanItem> plans = model?.plans?.where((plan) => plan.status == true).toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(fromDialog) const SizedBox(height: 60),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Center(child: Text('choose_your_pro_plan'.tr, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge))),
          Center(
            child: Text(
              'unlock_exclusive_benefits_save_more'.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Container(
            width: double.infinity,
            // padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              // color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(color: Theme.of(context).disabledColor.withAlpha(100))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProPlanCardWidget(model: model,),

                if (plans.isNotEmpty) Padding(
                  padding: const EdgeInsetsGeometry.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    ProPlanSelectorWidget(plans: plans),
                  ]),
                )
              ],
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          if(proController.faqList?.isNotEmpty ?? false) Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                border: Border.all(color: Theme.of(context).disabledColor.withAlpha(100))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProFaqWidget(faqList: proController.faqList),
              ]
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          const _TermsLink(),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ],
      ),
    );
  }
}

class _RenewalView extends StatelessWidget {
  final ProPlanModel? model;
  final ProController proController;
  final bool fromDialog;
  final VoidCallback? onCancel;
  const _RenewalView({required this.model, required this.proController, required this.fromDialog, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final List<PlanItem> plans = model?.plans
        ?.where((plan) => plan.status == true && plan.planType != ProPlanType.freeTrial)
        .toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(fromDialog) const SizedBox(height: 60),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Center(child: Text('renew_your_subscription'.tr, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge))),
          Center(
            child: Text(
              'unlock_exclusive_benefits_save_more'.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(color: Theme.of(context).disabledColor.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProPlanCardWidget(model: model),

                if (plans.isNotEmpty) Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    ProPlanSelectorWidget(
                      plans: plans,
                      currentPlanId: proController.activeOfferModel?.benefit?.planId,
                      isRenewal: true,
                      onCancel: onCancel,
                    ),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          if(proController.faqList?.isNotEmpty ?? false) Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                border: Border.all(color: Theme.of(context).disabledColor.withAlpha(100))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProFaqWidget(faqList: proController.faqList),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          const _TermsLink(),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String titleKey;
  const _DialogHeader({required this.titleKey});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Text(titleKey.tr, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'unlock_exclusive_benefits_save_more'.tr,
            textAlign: TextAlign.center,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }
}

class _TermsLink extends StatelessWidget {
  const _TermsLink();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showTerms(context),
        child: Text(
          'terms_and_condition'.tr,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            decoration: TextDecoration.underline,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
          insetPadding: const EdgeInsets.all(22),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: const SizedBox(width: 600, child: ProTermsBottomSheetWidget()),
        ),
        useSafeArea: false,
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
        ),
        builder: (context) => const ProTermsBottomSheetWidget(),
      );
    }
  }
}
