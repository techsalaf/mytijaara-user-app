import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateScreen extends StatefulWidget {
  final bool isUpdate;
  const UpdateScreen({super.key, required this.isUpdate});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<SplashController>(builder: (configModel) {
        return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                Image.asset(
                  widget.isUpdate ? Images.update : Images.maintenance,
                  width: MediaQuery.of(context).size.height*0.3,
                  height: MediaQuery.of(context).size.height*0.3,
                ),
                SizedBox(height: MediaQuery.of(context).size.height*0.01),

                Text(
                  widget.isUpdate ? 'update'.tr : configModel.configModel!.maintenanceModeData?.maintenanceMessageSetup?.maintenanceMessage ?? 'we_are_cooking_up_something_special'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height*0.01),

                Text(
                  widget.isUpdate ? 'your_app_is_deprecated'.tr : configModel.configModel!.maintenanceModeData?.maintenanceMessageSetup?.messageBody ?? 'maintenance_mode'.tr ,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: widget.isUpdate ? MediaQuery.of(context).size.height*0.04 : MediaQuery.of(context).size.height*0.01),
                Divider(height: MediaQuery.of(context).size.height*0.05, color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
                SizedBox(height: widget.isUpdate ? MediaQuery.of(context).size.height*0.04 : MediaQuery.of(context).size.height*0.01),

                if(!widget.isUpdate)
                  Column(
                    children: [
                      Text(
                        'any_query_feel_free_to_contact'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height*0.02),
                      GestureDetector(
                        onTap: () async {
                          String phone = '${configModel.configModel!.maintenanceModeData?.maintenanceMessageSetup?.businessNumber}'.tr;
                          if(await canLaunchUrlString('tel:$phone')) {
                            launchUrlString('tel:$phone');
                          }
                        },
                        child: Text(
                          configModel.configModel!.phone ?? '' ,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                       GestureDetector(
                        onTap: () async {
                          String email = '${configModel.configModel?.maintenanceModeData?.maintenanceMessageSetup?.businessEmail}'.tr;
                          if(await canLaunchUrlString('mailto:$email')) {
                            launchUrlString('mailto:$email');
                          }
                        },
                        child: Text(
                          configModel.configModel?.email ?? '' ,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline, decorationColor: Theme.of(context).primaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ) ,
                    ],
                  ),
                SizedBox(height: widget.isUpdate ? 0 : MediaQuery.of(context).size.height*0.04),

                widget.isUpdate ? CustomButton(buttonText: 'update_now'.tr, onPressed: () async {
                  String? appUrl = 'https://google.com';
                  if(GetPlatform.isAndroid) {
                    appUrl = configModel.configModel!.appUrlAndroid;
                  }else if(GetPlatform.isIOS) {
                    appUrl = configModel.configModel!.appUrlIos;
                  }
                  if(await canLaunchUrlString(appUrl!)) {
                    launchUrlString(appUrl, mode: LaunchMode.externalApplication);
                  }else {
                    showCustomSnackBar('${'can_not_launch'.tr} $appUrl');
                  }
                }) : const SizedBox(),

              ]),
            ),
          );
        }
      ),
    );
  }
}
