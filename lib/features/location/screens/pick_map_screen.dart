import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/animated_map_icon_extended.dart';
import 'package:sixam_mart/features/location/widgets/animated_map_icon_minimized.dart';
import 'package:sixam_mart/features/location/widgets/location_search_dialog_widget.dart';
import 'package:sixam_mart/features/location/widgets/serach_location_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/debouncer.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PickMapScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;
  final GoogleMapController? googleMapController;
  final Function(AddressModel address)? onPicked;
  final bool fromLandingPage;
  final bool fromGuestCheckout;
  final LatLng? initialPosition;
  final String? initialAddress;
  const PickMapScreen({super.key,
    required this.fromSignUp, required this.fromAddAddress, required this.canRoute, required this.route, this.googleMapController,
    this.onPicked, this.fromLandingPage = false, this.fromGuestCheckout = false, this.initialPosition, this.initialAddress,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  late LatLng _initialPosition;
  bool locationAlreadyAllow = false;
  double _currentZoomLevel = 16.0;
  final Debouncer _idleDebouncer = Debouncer(delay: const Duration(milliseconds: AppConstants.idleDebounceDuration));

  @override
  void initState() {
    super.initState();

    if(widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }
    if(widget.initialPosition != null) {
      _initialPosition = widget.initialPosition!;
      _cameraPosition = CameraPosition(target: _initialPosition, zoom: _currentZoomLevel);
    } else {
      _initialPosition = LatLng(
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '0'),
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '0'),
      );
    }
    _checkAlreadyLocationEnable();
  }

  @override
  void dispose() {
    _idleDebouncer.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyLocationEnable() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.whileInUse) {
      locationAlreadyAllow = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
      appBar: widget.fromGuestCheckout && !ResponsiveHelper.isDesktop(context) ? CustomAppBar(title: 'delivery_address'.tr) : null,
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: Center(child: Container(
        height:  ResponsiveHelper.isDesktop(context) ? 600 : null,
        width: ResponsiveHelper.isDesktop(context) ? 700 : Dimensions.webMaxWidth,
        decoration: context.width > 700 ? BoxDecoration(
          color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ) : null,

        child: GetBuilder<LocationController>(builder: (locationController) {

          return ResponsiveHelper.isDesktop(context) ? Padding(
            padding: const  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.clear),
                  ),
                ),
                // const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text('type_your_address_here_to_pick_form_map'.tr, style: robotoBold),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                SearchLocationWidget(mapController: _mapController, pickedAddress: locationController.pickAddress, isEnabled: null, fromDialog: true),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                SizedBox(
                  height: 350,
                  child:  Stack(children: [
                    ClipRRect(
                      borderRadius:BorderRadius.circular(Dimensions.radiusDefault),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: widget.fromAddAddress ? LatLng(locationController.position.latitude, locationController.position.longitude)
                              : _initialPosition,
                          zoom: _currentZoomLevel,
                        ),
                        minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                        myLocationButtonEnabled: false,
                        onMapCreated: (GoogleMapController mapController) async {
                          _mapController = mapController;
                          if(!widget.fromAddAddress && widget.route != 'splash' && widget.initialPosition == null) {
                            Get.find<LocationController>().getCurrentLocation(false, mapController: mapController).then((value) async {
                              if(widget.fromLandingPage && !locationAlreadyAllow && await _locationCheck()) {
                                _onPickAddressButtonPressed(locationController);
                              }
                            });
                          }
                        },
                        scrollGesturesEnabled: !Get.isDialogOpen!,
                        zoomControlsEnabled: false,
                        onCameraMove: (CameraPosition cameraPosition) {
                          _cameraPosition = cameraPosition;
                        },
                        onCameraMoveStarted: () {
                          _idleDebouncer.cancel();
                          locationController.updateCameraMovingStatus(true);
                          locationController.disableButton();
                        },
                        onCameraIdle: () {
                          locationController.updateCameraMovingStatus(false);
                          _idleDebouncer.run(() {
                            if (!mounted) return;
                            Get.find<LocationController>().updatePosition(_cameraPosition, false);
                          });
                        },
                        style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
                      ),
                    ),

                    // Center(child: !locationController.loading ? Image.asset(Images.pickMarker, height: 50, width: 50)
                    //     : const CircularProgressIndicator()),
                    Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // if(locationController.isCameraMoving)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('is_this_your_location'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.pickMapIconSize * 0.65),
                          child: locationController.isCameraMoving ? const AnimatedMapIconExtended() : const AnimatedMapIconMinimised(),
                        ),
                      ],
                    )),

                    Positioned(
                      bottom: 75, right: Dimensions.paddingSizeSmall,
                      child: FloatingActionButton(
                        mini: true, backgroundColor: Theme.of(context).cardColor,
                        onPressed: () => Get.find<LocationController>().checkPermission(() {
                          Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
                        }),
                        child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                Row(
                  children: [
                    const Spacer(),
                    CustomButton(
                      isBold: false,
                      width: 120,
                      radius: Dimensions.radiusSmall,
                      buttonText: 'cancel'.tr,
                      isLoading: locationController.isLoading,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                      textColor: Theme.of(context).textTheme.bodyLarge?.color,
                      onPressed: () {
                        Get.back();
                      },
                    ),

                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Flexible(
                      child: CustomButton(
                        isBold: false,
                        radius: Dimensions.radiusSmall,
                        buttonText: locationController.inZone ? widget.fromAddAddress ? 'pick_address'.tr : 'pick_location'.tr
                            : 'service_not_available_in_this_area'.tr,
                        isLoading: locationController.isLoading,
                        onPressed: locationController.isLoading ? (){} : (locationController.buttonDisabled || locationController.loading) ? null : () {
                          _onPickAddressButtonPressed(locationController);
                        },
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ) : Stack(children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.fromAddAddress ? LatLng(locationController.position.latitude, locationController.position.longitude)
                    : _initialPosition,
                zoom: _currentZoomLevel,
              ),
              minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController mapController) {
                _mapController = mapController;

                if(!widget.fromAddAddress && widget.route != RouteHelper.onBoarding && widget.initialPosition == null) {
                  Get.find<LocationController>().getCurrentLocation(false, mapController: mapController);
                }
              },
              scrollGesturesEnabled: !Get.isDialogOpen!,
              zoomControlsEnabled: false,
              onCameraMove: (CameraPosition cameraPosition) {
                _cameraPosition = cameraPosition;
              },
              onCameraMoveStarted: () {
                _idleDebouncer.cancel();
                locationController.updateCameraMovingStatus(true);
                locationController.disableButton();
              },
              onCameraIdle: () {
                locationController.updateCameraMovingStatus(false);
                _idleDebouncer.run(() {
                  if (!mounted) return;
                  Get.find<LocationController>().updatePosition(_cameraPosition, false);
                });
              },
              style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
            ),

            Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.pickMapIconSize * 0.65),
                  child: locationController.isCameraMoving ? const AnimatedMapIconExtended() : const AnimatedMapIconMinimised(),
                ),
              ],
            )),

            Positioned(
              top: 0, left: 0, right: 0,
              child: _MapTopSearchBar(
                mapController: _mapController, pickedAddress: locationController.pickAddress,
                showBackButton: widget.route != RouteHelper.onBoarding,
              ),
            ),

            Positioned(
              bottom: 80, right: Dimensions.paddingSizeLarge,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, spreadRadius: 0.5, offset: const Offset(0, 4))],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: FloatingActionButton(
                      mini: true, backgroundColor: Theme.of(context).cardColor,
                      onPressed: () => Get.find<LocationController>().checkPermission(() {
                        Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
                      }),
                      child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, spreadRadius: 0.5, offset: const Offset(0, 4))],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                        icon: const Icon( Icons.add, size: 28),
                        onPressed: () {
                          setState(() {
                            _currentZoomLevel++;
                          });
                          _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoomLevel));
                        },
                      ),


                      IconButton(
                        icon: const Icon(Icons.remove, size: 28),
                        onPressed: () {
                          _currentZoomLevel--;
                          _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoomLevel));
                        },
                      ),


                    ]),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: Dimensions.paddingSizeLarge, left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge,
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                  onTap: locationController.isLoading ? (){} : (locationController.buttonDisabled || locationController.loading) ? null : () {
                    _onPickAddressButtonPressed(locationController);
                  },
                // onTap: (locationController.buttonDisabled || locationController.loading) ? null : () => _onPickAddressButtonPressed(locationController),
                child: Builder(
                  builder: (context) {
                    print('======Button Disabled: ${locationController.buttonDisabled}, Loading: ${locationController.loading}');
                    return Container(
                      padding: EdgeInsets.all(locationController.loading ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeDefault - 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: locationController.loading ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
                            : locationController.buttonDisabled ? Theme.of(context).disabledColor.withValues(alpha: 0.7)
                            : Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: locationController.loading ? Center(
                        child: LoadingAnimationWidget.waveDots(color: Colors.white, size: 40),
                      ) : Text(
                        locationController.inZone ? widget.fromAddAddress ? 'confirm_location'.tr : widget.fromGuestCheckout ? 'confirm_address'.tr : 'confirm_location'.tr : 'service_not_available_in_this_area'.tr,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
                      ),
                    );
                  }
                ),
              ),
            ),
          ]);

        }),
      ))),
    );
  }

  void _onPickAddressButtonPressed(LocationController locationController) {
    if(locationController.pickPosition.latitude != 0 && locationController.pickAddress!.isNotEmpty) {
      if(widget.onPicked != null) {
        AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: '', address: locationController.pickAddress,
          contactPersonName: AddressHelper.getUserAddressFromSharedPref()?.contactPersonName,
          contactPersonNumber: AddressHelper.getUserAddressFromSharedPref()?.contactPersonNumber,
        );
        widget.onPicked!(address);
        Get.back();
      }else if(widget.fromAddAddress) {
        if(widget.googleMapController != null) {
          widget.googleMapController!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(
            locationController.pickPosition.latitude, locationController.pickPosition.longitude,
          ), zoom: 16)));
          locationController.setAddAddressData();
        }
        Get.back();
      }else {
        AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: '', address: locationController.pickAddress,
        );

        if(widget.fromLandingPage) {
          if(!AuthHelper.isGuestLoggedIn() && !AuthHelper.isLoggedIn()) {
            Get.find<AuthController>().guestLogin().then((response) {
              if(response.isSuccess) {
                Get.find<ProfileController>().setForceFullyUserEmpty();
                Get.back();
                locationController.saveAddressAndNavigate(
                  address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(Get.context),
                );
              }
            });
          } else {
            Get.back();
            locationController.saveAddressAndNavigate(
              address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(context),
            );
          }
        }else {
          print('========here calling m f  dm djjk======');
          locationController.saveAddressAndNavigate(
            address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(context),
          );
        }
      }
    }else {
      showCustomSnackBar('pick_an_address'.tr);
    }
  }

  Future<bool> _locationCheck() async {
    bool locationServiceEnabled = true;
    LocationPermission permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.denied) {
      locationServiceEnabled = false;
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.deniedForever) {
      locationServiceEnabled = false;
    }
    return locationServiceEnabled;
  }

}

class _MapTopSearchBar extends StatelessWidget {
  final GoogleMapController? mapController;
  final String? pickedAddress;
  final bool showBackButton;
  const _MapTopSearchBar({required this.mapController, required this.pickedAddress, required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    final bool hasAddress = pickedAddress != null && pickedAddress!.isNotEmpty;
    final Color midDisabledColor = Theme.of(context).disabledColor.withValues(alpha: 0.4);
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: Dimensions.paddingSizeSmall),
      child: LocationSearchDialogWidget(
        mapController: mapController,
        pickedLocation: pickedAddress,
        fullWidthBar: true,
        leading: showBackButton ? _CircleIconButton(
          icon: Icons.arrow_back,
          backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          onTap: () => Get.back(),
        ) : null,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: midDisabledColor),
          ),
          child: Row(children: [

            const Icon(CupertinoIcons.placemark, size: 22),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Text(
              hasAddress ? pickedAddress! : 'search_location'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: hasAddress ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).hintColor,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            Icon(hasAddress ? Icons.close : Icons.search, size: 22, color: Theme.of(context).hintColor),
          ]),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.backgroundColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40,
          child: Icon(icon, size: 22, color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
      ),
    );
  }
}
